// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import {
	aws_ec2 as ec2,
	aws_iam as iam,
	aws_logs as logs,
	aws_networkfirewall as nf,
	aws_networkmanager as nm,
	custom_resources as cr,
	Stack,
	StackProps,
	RemovalPolicy,
} from "aws-cdk-lib";
import { Construct } from "constructs";
import { cloudWanRegion } from "../bin/cloudwan-workshop-code";

interface InspectionStackProps extends StackProps {
	cidr: string;
	cloudWanRegion: string;
	cloudWanSegment: string;
	egressInspection?: boolean;
	lab: string;
	organisationCidr: string;
	onPremCidr: string;
}

export class InspectionStack extends Stack {
	private lab: string;

	constructor(scope: Construct, id: string, props: InspectionStackProps) {
		super(scope, id, props);

		this.lab = props.lab;

		// Start creation of either egress or internal inspection
		if (props.egressInspection) {
			this.createEgressInspectionVPC(
				props.cidr,
				props.organisationCidr,
				props.cloudWanSegment,
				props.onPremCidr
			);
		} else {
			this.createInspectionVPC(
				props.cidr,
				props.organisationCidr,
				props.cloudWanSegment,
				props.onPremCidr
			);
		}
	}

	private createInspectionVPC(
		cidr: string,
		organisationCidr: string,
		cloudWanSegment: string,
		onPremCidr: string
	) {
		const vpc = new ec2.Vpc(this, "InspectionVPC", {
			vpcName: "eastwest-inspection",
			availabilityZones: ["a", "b"].map((az) => {
				return Stack.of(this).region + az;
			}),
			ipAddresses: ec2.IpAddresses.cidr(cidr),
			createInternetGateway: true,
			natGatewayProvider: ec2.NatGatewayProvider.gateway(),
			subnetConfiguration: [
				{
					name: "Firewall",
					subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
					cidrMask: 28,
				},
				{
					name: "CWAN",
					subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
					cidrMask: 28,
				},
			],
		});

		// Create Network Firewall for internal inspection. No public routes created.
		this.createNetworkFirewallAndRoutes(
			"eastwestinspection",
			vpc,
			false,
			organisationCidr
		);

		// Create Cloud WAN attachment and routes towards Network Firewall and towards Cloud WAN
		if (this.lab === "lab1" || this.lab === "lab2" || this.lab === "lab3")
			this.createCloudWanAttachmentAndRoutes(
				"eastwestinspection",
				cloudWanSegment,
				onPremCidr,
				organisationCidr,
				vpc
			);
	}

	private createEgressInspectionVPC(
		cidr: string,
		organisationCidr: string,
		cloudWanSegment: string,
		onPremCidr: string
	) {
		const vpc = new ec2.Vpc(this, "EgressInspectionVPC", {
			vpcName: "egress-inspection",
			availabilityZones: ["a", "b"].map((az) => {
				return Stack.of(this).region + az;
			}),
			ipAddresses: ec2.IpAddresses.cidr(cidr),
			createInternetGateway: true,
			natGatewayProvider: ec2.NatGatewayProvider.gateway(),
			subnetConfiguration: [
				{
					name: "Public",
					subnetType: ec2.SubnetType.PUBLIC,
					mapPublicIpOnLaunch: true,
					cidrMask: 28,
				},
				{
					name: "Firewall",
					subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
					cidrMask: 28,
				},
				{
					name: "CWAN",
					subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
					cidrMask: 28,
				},
			],
		});

		// Create Network Firewall for egress inspection and routes from public subnets towards Network Firewall
		this.createNetworkFirewallAndRoutes(
			"egressinspection",
			vpc,
			true,
			organisationCidr
		);

		// Create Cloud WAN attachment and routes towards Network Firewall and towards Cloud WAN
		if (this.lab === "lab1" || this.lab === "lab2" || this.lab === "lab3") {
			this.createCloudWanAttachmentAndRoutes(
				"egressinspection",
				cloudWanSegment,
				onPremCidr,
				organisationCidr,
				vpc
			);
		}
	}

	private createCloudWanAttachmentAndRoutes(
		environmentName: string,
		cloudWanSegment: string,
		onPremCidr: string,
		organisationCidr: string,
		vpc: ec2.Vpc
	) {
		/**
		 * Select all subnets from subnet group named CloudWANAttachment and create ARNs for those.
		 * Create CloudWAN attachment to both of those subnets.
		 */
		const subnetArns = vpc
			.selectSubnets({ subnetGroupName: "CWAN" })
			.subnetIds.map(
				(id) =>
					`arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:subnet/${id}`
			);

		// Cloud WAN Core Network ID from SSM paramaters
		const coreNetworkId = this.getCloudWANCoreNetworkID(
			environmentName,
			cloudWanRegion,
			vpc.vpcId
		).getResponseField("Parameter.Value");

		const cloudWanAttachment = new nm.CfnVpcAttachment(
			this,
			"CloudWanAttachment",
			{
				coreNetworkId: coreNetworkId,
				subnetArns: subnetArns,
				vpcArn: vpc.vpcArn,
				options: {
					applianceModeSupport: true,
				},
				tags: [
					{
						key: "nfg",
						value: cloudWanSegment,
					},
					{
						key: "Name",
						value: `${Stack.of(this).region === "us-west-2" ? "oregon" : "stockholm"}-${environmentName}`,
					},
				],
			}
		);

		// Routes from Firewall subnets towards Cloud WAN attachment
		vpc
			.selectSubnets({ subnetGroupName: "Firewall" })
			.subnets.forEach((subnet) => {
				new ec2.CfnRoute(this, `RouteFirewallToCwan-${subnet.node.id}`, {
					destinationCidrBlock: organisationCidr,
					coreNetworkArn: cloudWanAttachment.attrCoreNetworkArn,
					routeTableId: subnet.routeTable.routeTableId,
				});

				if (this.lab === "lab3") {
					new ec2.CfnRoute(this, `RouteFirewallToOnprem-${subnet.node.id}`, {
						destinationCidrBlock: onPremCidr,
						coreNetworkArn: cloudWanAttachment.attrCoreNetworkArn,
						routeTableId: subnet.routeTable.routeTableId,
					});
				}
			});
	}

	private createNetworkFirewallAndRoutes(
		environmentName: string,
		vpc: ec2.Vpc,
		egress: boolean = false,
		organisationCidr: string
	): string {
		// Create a list of subnet IDs for Network Firewall
		let subnetList: nf.CfnFirewall.SubnetMappingProperty[] = [];
		subnetList = vpc
			.selectSubnets({ subnetGroupName: "Firewall" })
			.subnetIds.map((id) => ({ subnetId: id }));

		// Network firewall
		const networkFirewall = new nf.CfnFirewall(
			this,
			`${environmentName}NetworkFirewall`,
			{
				firewallName: environmentName,
				firewallPolicyArn: egress
					? this.createEgressInspectionFirewallPolicy()
					: this.createInspectionVPCFirewallPolicy(),
				subnetMappings: subnetList,
				vpcId: vpc.vpcId,
			}
		);

		// CloudWatch Logs group to store Network Firewall flow logs
		const fwFlowLogsGroup = new logs.LogGroup(
			this,
			`${environmentName}LogsGroup`,
			{
				logGroupName: `${environmentName}-firewall-flow-logs`,
				retention: logs.RetentionDays.ONE_DAY,
				removalPolicy: RemovalPolicy.DESTROY,
			}
		);

		// CloudWatch Logs group to store Network Firewall alert logs
		const fwAlertLogsGroup = new logs.LogGroup(
			this,
			`${environmentName}AlertLogsGroup`,
			{
				logGroupName: `${environmentName}-firewall-alert-logs`,
				retention: logs.RetentionDays.ONE_DAY,
				removalPolicy: RemovalPolicy.DESTROY,
			}
		);

		// Firewall logging configuration to enable both flow and alert logs
		new nf.CfnLoggingConfiguration(this, `${environmentName}FirewallLogConf`, {
			firewallArn: networkFirewall.attrFirewallArn,
			loggingConfiguration: {
				logDestinationConfigs: [
					{
						logDestination: { logGroup: fwFlowLogsGroup.logGroupName },
						logDestinationType: "CloudWatchLogs",
						logType: "FLOW",
					},
					{
						logDestination: { logGroup: fwAlertLogsGroup.logGroupName },
						logDestinationType: "CloudWatchLogs",
						logType: "ALERT",
					},
				],
			},
		});

		const firewallStatus = this.getFirewallEndpointId(
			environmentName,
			networkFirewall.attrFirewallArn
		);

		vpc.selectSubnets({ subnetGroupName: "CWAN" }).subnets.forEach((subnet) => {
			new ec2.CfnRoute(this, `RouteCwanToFirewall-${subnet.availabilityZone}`, {
				destinationCidrBlock: "0.0.0.0/0",
				routeTableId: subnet.routeTable.routeTableId,
				vpcEndpointId: firewallStatus.getResponseField(
					`FirewallStatus.SyncStates.${subnet.availabilityZone}.Attachment.EndpointId`
				),
			});
		});

		if (egress) {
			vpc
				.selectSubnets({ subnetGroupName: "Public" })
				.subnets.forEach((subnet) => {
					new ec2.CfnRoute(
						this,
						`RoutePublicToFirewall-${subnet.availabilityZone}`,
						{
							destinationCidrBlock: organisationCidr,
							routeTableId: subnet.routeTable.routeTableId,
							vpcEndpointId: firewallStatus.getResponseField(
								`FirewallStatus.SyncStates.${subnet.availabilityZone}.Attachment.EndpointId`
							),
						}
					);
				});
		}

		return networkFirewall.attrFirewallArn;
	}

	private createEgressInspectionFirewallPolicy(): string {
		const dropRemoteSSHRuleGroup = new nf.CfnRuleGroup(
			this,
			"egress-drop-remote-ssh",
			{
				capacity: 2,
				ruleGroupName: "egress-drop-remote-ssh",
				type: "STATELESS",
				ruleGroup: {
					rulesSource: {
						statelessRulesAndCustomActions: {
							statelessRules: [
								{
									priority: 1,
									ruleDefinition: {
										matchAttributes: {
											protocols: [6],
											sources: [{ addressDefinition: "0.0.0.0/0" }],
											sourcePorts: [{ fromPort: 22, toPort: 22 }],
											destinations: [{ addressDefinition: "0.0.0.0/0" }],
											destinationPorts: [{ fromPort: 22, toPort: 22 }],
										},
										actions: ["aws:drop"],
									},
								},
							],
						},
					},
				},
			}
		);

		const allowDomains = new nf.CfnRuleGroup(this, "egress-allow-domains", {
			capacity: 100,
			ruleGroupName: "egress-allow-domains",
			type: "STATEFUL",
			ruleGroup: {
				statefulRuleOptions: {
					ruleOrder: "STRICT_ORDER",
				},
				rulesSource: {
					rulesString: `
			pass tcp any any <> $EXTERNAL_NET 443 (msg:"Allowing TCP in port 443"; flow:not_established; sid:892123; rev:1;)
			pass tls any any -> $EXTERNAL_NET 443 (tls.sni; dotprefix; content:".amazon.com"; endswith; msg:"Allowing .amazon.com HTTPS requests"; sid:892125; rev:1;)
		  `,
				},
			},
		});

		const allowIcmpRuleGroup = new nf.CfnRuleGroup(this, "egress-allow-icmp", {
			capacity: 100,
			ruleGroupName: "egress-allow-icmp",
			type: "STATEFUL",
			ruleGroup: {
				statefulRuleOptions: {
					ruleOrder: "STRICT_ORDER",
				},
				rulesSource: {
					rulesString: `
			alert icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Alert on ICMP traffic between/within Prod and Third Party VPCs"; sid:199407051; rev:1;)
			pass icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Allow ICMP traffic between/within Prod and Third Party VPCs"; sid:199407052; rev:1;)
			alert icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Alert on ICMP traffic from Prod/Third Party to On-Premises"; sid:199407053; rev:1;)
			pass icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Allow ICMP traffic from Prod/Third Party to On-Premises"; sid:199407054; rev:1;)
			`,
				},
			},
		});

		const firewallPolicy = new nf.CfnFirewallPolicy(this, "egress-inspection", {
			firewallPolicyName: "egress-inspection-policy",
			firewallPolicy: {
				statelessDefaultActions: ["aws:forward_to_sfe"],
				statelessFragmentDefaultActions: ["aws:forward_to_sfe"],
				statelessRuleGroupReferences: [
					{
						priority: 10,
						resourceArn: dropRemoteSSHRuleGroup.attrRuleGroupArn,
					},
				],
				statefulEngineOptions: {
					ruleOrder: "STRICT_ORDER",
				},
				statefulDefaultActions: ["aws:drop_strict", "aws:alert_strict"],
				statefulRuleGroupReferences: [
					{
						priority: 10,
						resourceArn: allowDomains.attrRuleGroupArn,
					},
					{
						priority: 20,
						resourceArn: allowIcmpRuleGroup.attrRuleGroupArn,
					},
				],
			},
		});

		return firewallPolicy.attrFirewallPolicyArn;
	}

	private createInspectionVPCFirewallPolicy(): string {
		const allowIcmpRuleGroup = new nf.CfnRuleGroup(
			this,
			"eastwest-allow-icmp",
			{
				capacity: 100,
				ruleGroupName: "eastwest-allow-icmp",
				type: "STATEFUL",
				ruleGroup: {
					statefulRuleOptions: {
						ruleOrder: "STRICT_ORDER",
					},
					rulesSource: {
						rulesString: `
			alert icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Alert on ICMP traffic between/within Prod and Third Party VPCs"; sid:199407051; rev:1;)
			pass icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Allow ICMP traffic between/within Prod and Third Party VPCs"; sid:199407052; rev:1;)
			alert icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Alert on ICMP traffic from Prod/Third Party to On-Premises"; sid:199407053; rev:1;)
			pass icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Allow ICMP traffic from Prod/Third Party to On-Premises"; sid:199407054; rev:1;)
			`,
					},
				},
			}
		);

		const firewallPolicy = new nf.CfnFirewallPolicy(this, "eastwest-policy", {
			firewallPolicyName: "eastwest-policy",
			firewallPolicy: {
				statelessDefaultActions: ["aws:forward_to_sfe"],
				statelessFragmentDefaultActions: ["aws:forward_to_sfe"],
				statefulEngineOptions: {
					ruleOrder: "STRICT_ORDER",
				},
				statefulDefaultActions: ["aws:drop_strict", "aws:alert_strict"],
				statefulRuleGroupReferences: [
					{
						priority: 10,
						resourceArn: allowIcmpRuleGroup.attrRuleGroupArn,
					},
				],
			},
		});

		return firewallPolicy.attrFirewallPolicyArn;
	}

	private getCloudWANCoreNetworkID(
		environmentName: string,
		cloudWanRegion: string,
		vpcId: string
	): cr.AwsCustomResource {
		/*
		 * When VPC is created in same account as the CloudWAN. We need to get CloudWAN ID
		 * from AWS SSM parameters instead of AWS RAM share.
		 * AWS RAM doesn't work within same account.
		 */

		const ssmSdkCall: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "CloudWanCoreNetworkId",
			},
			region: cloudWanRegion,
			physicalResourceId: cr.PhysicalResourceId.of(`${vpcId}CoreNetworkId`),
		};

		return new cr.AwsCustomResource(this, "CustomResourceCloudWanId", {
			installLatestAwsSdk: false,
			onCreate: ssmSdkCall,
			onUpdate: ssmSdkCall,
			policy: cr.AwsCustomResourcePolicy.fromStatements([
				new iam.PolicyStatement({
					actions: ["ssm:GetParameter"],
					effect: iam.Effect.ALLOW,
					resources: [
						`arn:aws:ssm:${cloudWanRegion}:${Stack.of(this).account}:parameter/CloudWanCoreNetworkId`,
					],
				}),
			]),
		});
	}

	private getFirewallEndpointId(
		environmentName: string,
		firewallArn: string
	): cr.AwsCustomResource {
		/**
		 * Query AWS Network Firewall for the Endpoint ID in specific Availability Zone
		 *  */
		const describeFirewall: cr.AwsSdkCall = {
			service: "network-firewall",
			action: "describeFirewall",
			parameters: {
				FirewallArn: firewallArn,
			},
			outputPaths: ["FirewallStatus.SyncStates"],
			physicalResourceId: cr.PhysicalResourceId.of("describeFirewall"),
		};

		return new cr.AwsCustomResource(this, "CustomResourceFirewallEndpointID", {
			installLatestAwsSdk: false,
			onCreate: describeFirewall,
			onUpdate: describeFirewall,
			policy: cr.AwsCustomResourcePolicy.fromStatements([
				new iam.PolicyStatement({
					actions: ["network-firewall:DescribeFirewall"],
					effect: iam.Effect.ALLOW,
					resources: [firewallArn],
				}),
			]),
		});
	}
}

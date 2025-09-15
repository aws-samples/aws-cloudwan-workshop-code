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
	aws_networkmanager as nm,
	custom_resources as cr,
	Stack,
	StackProps,
} from "aws-cdk-lib";
import { Construct } from "constructs";

interface WorkloadStackProps extends StackProps {
	cidr: string;
	environmentName: string;
	cloudWanRegion?: string;
	cloudWanSegment?: string;
	lab: string;
	transitGatewayId?: string;
	routeTableId?: string;
}

export class WorkloadStack extends Stack {
	private environmentName: string;

	constructor(scope: Construct, id: string, props: WorkloadStackProps) {
		super(scope, id, props);

		this.environmentName = props.environmentName;

		// Create VPC for either CloudWan or Transit Gateway attached VPC
		const vpc = this.createVpc(
			props.environmentName,
			props.cidr,
			props.cloudWanSegment ? true : false
		);

		// Create either Cloud WAN attachment or Transit Gateway attachment.
		// Depends whether Cloud WAN or Transit Gateway parameters were provided
		if (
			props.cloudWanSegment &&
			props.cloudWanRegion &&
			(props.lab === "lab1" || props.lab === "lab2" || props.lab === "lab3")
		) {
			this.createCloudWanAttachmentAndRoutes(
				vpc,
				props.environmentName,
				props.cloudWanRegion,
				props.cloudWanSegment
			);
		} else if (props.transitGatewayId && props.routeTableId) {
			this.createTransitGatewayAttachmentAndRoutes(
				vpc,
				props.environmentName,
				props.transitGatewayId,
				props.routeTableId
			);
		}

		/*
		 * EC2 instance to test connectivity through CloudWAN
		 * Instance connects to AWS SSM through VPC endpoints so
		 * that the connectivity is always available regardless of CloudWAN config
		 */
		vpc.addInterfaceEndpoint("SsmEndpoint", {
			service: ec2.InterfaceVpcEndpointAwsService.SSM,
		});
		vpc.addInterfaceEndpoint("SsmMessagesEndpoint", {
			service: ec2.InterfaceVpcEndpointAwsService.SSM_MESSAGES,
		});
		vpc.addInterfaceEndpoint("Ec2MessagesEndpoint", {
			service: ec2.InterfaceVpcEndpointAwsService.EC2_MESSAGES,
		});

		// SSM role for the EC2 instance to enable remote management with AWS Systems Manager
		const ssmRole = new iam.Role(this, `${props.environmentName}Role`, {
			assumedBy: new iam.ServicePrincipal("ec2.amazonaws.com"),
			managedPolicies: [
				iam.ManagedPolicy.fromAwsManagedPolicyName(
					"AmazonSSMManagedInstanceCore"
				),
			],
		});

		// Security group for the EC2 instance.
		// Allows ICMP Requests in with IPv4 and IPv6
		const sg = new ec2.SecurityGroup(
			this,
			`${props.environmentName}SecurityGroup`,
			{
				securityGroupName: `${props.environmentName}-instance-sg`,
				vpc: vpc,
			}
		);

		sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.icmpType(8));
		sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.SSH);

		new ec2.Instance(this, `${props.environmentName}Instance`, {
			vpc: vpc,
			vpcSubnets: vpc.selectSubnets({
				subnetGroupName: "Private",
			}),
			instanceType: ec2.InstanceType.of(
				ec2.InstanceClass.BURSTABLE4_GRAVITON,
				ec2.InstanceSize.MICRO
			),
			machineImage: ec2.MachineImage.latestAmazonLinux2023({
				cpuType: ec2.AmazonLinuxCpuType.ARM_64,
			}),
			role: ssmRole,
			securityGroup: sg,
			instanceName: `${props.environmentName}`,
		});
	}

	private createVpc(
		environmentName: string,
		cidr: string,
		cwanAttached: boolean
	): ec2.Vpc {
		let subConfiguration;
		if (cwanAttached) {
			subConfiguration = ["Endpoint", "Private", "CWAN"].map((name) => {
				return {
					name,
					subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
					cidrMask: 28,
				};
			});
		} else {
			subConfiguration = ["Endpoint", "Private", "TGW"].map((name) => {
				return {
					name,
					subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
					cidrMask: 28,
				};
			});
		}

		return new ec2.Vpc(this, `${environmentName}VPC`, {
			vpcName: environmentName,
			ipAddresses: ec2.IpAddresses.cidr(cidr),
			maxAzs: 2,
			subnetConfiguration: subConfiguration,
		});
	}

	private createCloudWanAttachmentAndRoutes(
		vpc: ec2.Vpc,
		environmentName: string,
		cloudWanRegion: string,
		cloudWanSegment: string
	) {
		// Because we are deploying this sample to one account and different regions
		// we need to use SSM to get access to CloudWAN core network ID. We can't do stack references
		// cross regions.

		const ssmSdkCall: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "CloudWanCoreNetworkId",
			},
			region: cloudWanRegion,
			physicalResourceId: cr.PhysicalResourceId.of(`${vpc.vpcId}CoreNetworkId`),
		};

		const coreNetworkId = new cr.AwsCustomResource(this, "CoreNetworkId", {
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

		// Create a list of subnet ARNs for the VPC Attachment
		const subnetArns = vpc
			.selectSubnets({ subnetGroupName: "CWAN" })
			.subnetIds.map(
				(id) =>
					`arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:subnet/${id}`
			);

		const attachment = new nm.CfnVpcAttachment(
			this,
			this.environmentName + "CloudwanAttachment",
			{
				coreNetworkId: coreNetworkId.getResponseField("Parameter.Value"),
				subnetArns: subnetArns,
				vpcArn: vpc.vpcArn,
				tags: [
					{
						key: "domain",
						value: cloudWanSegment,
					},
					{
						key: "Name",
						value: `${Stack.of(this).region === "us-west-2" ? "oregon" : "stockholm"}-${environmentName}`,
					},
				],
			}
		);

		// Create default route towards CloudWAN attachment
		vpc
			.selectSubnets({ subnetGroupName: "Private" })
			.subnets.forEach((subnet) => {
				new ec2.CfnRoute(this, `${subnet.node.id}-route`, {
					destinationCidrBlock: "0.0.0.0/0",
					routeTableId: subnet.routeTable.routeTableId,
					coreNetworkArn: `arn:aws:networkmanager::${Stack.of(this).account}:core-network/${coreNetworkId.getResponseField("Parameter.Value")}`,
				}).addDependency(attachment);
			});
	}

	private createTransitGatewayAttachmentAndRoutes(
		vpc: ec2.Vpc,
		environmentName: string,
		transitGatewayId: string,
		routeTableId: string
	) {
		const attachment = new ec2.CfnTransitGatewayAttachment(
			this,
			`${this.environmentName}TransitGatewayAttachment`,
			{
				transitGatewayId,
				subnetIds: vpc.selectSubnets({ subnetGroupName: "TGW" }).subnetIds,
				vpcId: vpc.vpcId,
			}
		);

		new ec2.CfnTransitGatewayRouteTableAssociation(
			this,
			`${environmentName}TGWRouteTableAssociation`,
			{
				transitGatewayAttachmentId: attachment.attrId,
				transitGatewayRouteTableId: routeTableId,
			}
		);

		new ec2.CfnTransitGatewayRouteTablePropagation(
			this,
			`${environmentName}RouteTablePropagation`,
			{
				transitGatewayRouteTableId: routeTableId,
				transitGatewayAttachmentId: attachment.attrId,
			}
		);

		// Create default route towards Transit Gateway attachment
		vpc
			.selectSubnets({ subnetGroupName: "Private" })
			.subnets.forEach((subnet) => {
				new ec2.CfnRoute(this, `${subnet.node.id}TgwRoute`, {
					destinationCidrBlock: "0.0.0.0/0",
					routeTableId: subnet.routeTable.routeTableId,
					transitGatewayId,
				}).addDependency(attachment);
			});
	}
}

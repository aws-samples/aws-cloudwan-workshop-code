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
	aws_ssm as ssm,
	Duration,
	Stack,
	StackProps,
} from "aws-cdk-lib";
import { Construct } from "constructs";
import path from "path";

interface OnPremisesStackProps extends StackProps {
	cidr: string;
	cloudWanRegion: string;
	lab: string;
}

export class OnPremisesStack extends Stack {
	constructor(scope: Construct, id: string, props: OnPremisesStackProps) {
		super(scope, id, props);

		const vpc = new ec2.Vpc(this, "OnPremisesVPC", {
			ipAddresses: ec2.IpAddresses.cidr(props.cidr),
			maxAzs: 1,
			natGateways: 0,
			subnetConfiguration: [
				{
					name: "Public",
					subnetType: ec2.SubnetType.PUBLIC,
					cidrMask: 25,
				},
			],
		});

		// Elastic IP for the on-premises instance
		const elasticIp = new ec2.CfnEIP(this, "OnPremisesPublicIp");
		new ssm.StringParameter(this, "OnpremisesIp", {
			stringValue: elasticIp.attrPublicIp,
			parameterName: "OnPremisesIp",
		});

		const securityGroup = new ec2.SecurityGroup(
			this,
			"OnPremisesInstanceSecurityGroup",
			{
				vpc,
			}
		);
		securityGroup.addIngressRule(
			ec2.Peer.ipv4(props.cidr),
			ec2.Port.icmpPing(),
			"Allow ICMP from on-premises"
		);

		const userData = ec2.UserData.forLinux();
		userData.addCommands(
			"apt update",
			"apt -y install python3-pip",
			"pip3 install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz",
			"mkdir -p /opt/aws/bin",
			"ln -s /usr/local/bin/cfn-* /opt/aws/bin/"
		);

		const role = new iam.Role(this, "OnPremisesInstaceRole", {
			assumedBy: new iam.ServicePrincipal("ec2.amazonaws.com"),
			managedPolicies: [
				iam.ManagedPolicy.fromAwsManagedPolicyName(
					"AmazonSSMManagedInstanceCore"
				),
			],
			inlinePolicies: {
				describeVpnConnections: new iam.PolicyDocument({
					statements: [
						new iam.PolicyStatement({
							actions: ["ec2:DescribeVpnConnections"],
							resources: ["*"],
						}),
					],
				}),
			},
		});

		const instance = new ec2.Instance(this, "OnPremisesInstance", {
			instanceType: ec2.InstanceType.of(
				ec2.InstanceClass.BURSTABLE4_GRAVITON,
				ec2.InstanceSize.MICRO
			),
			instanceName: "onprem",
			vpc: vpc,
			role,
			vpcSubnets: vpc.selectSubnets({ subnetGroupName: "Public" }),
			machineImage: ec2.MachineImage.fromSsmParameter(
				"/aws/service/canonical/ubuntu/server/22.04/stable/current/arm64/hvm/ebs-gp2/ami-id"
			),
			securityGroup,
			userData,
			init: ec2.CloudFormationInit.fromConfigSets({
				configSets: {
					default: ["config"],
				},
				configs: {
					config: new ec2.InitConfig([
						ec2.InitPackage.apt("apparmor-utils"),
						ec2.InitPackage.apt("frr"),
						ec2.InitPackage.apt("net-tools"),
						ec2.InitPackage.apt("strongswan"),
						ec2.InitFile.fromString("/etc/hostname", "onprem", {
							mode: "000644",
							owner: "root",
							group: "root",
						}),
						ec2.InitFile.fromAsset(
							"/usr/local/sbin/configure-vpn.py",
							path.join(__dirname, "ec2_init_files/vpn_config_script.py"),
							{
								mode: "000700",
								group: "root",
								owner: "root",
							}
						),
						ec2.InitFile.fromAsset(
							"/etc/netplan/01-loopback.yaml",
							path.join(__dirname, "ec2_init_files/loopback.yaml"),
							{
								mode: "000644",
								group: "root",
								owner: "root",
							}
						),
						ec2.InitFile.fromAsset(
							"/etc/dnsmasq.d/unicornrentals.cfg",
							path.join(__dirname, "ec2_init_files/unicornrentals.cfg")
						),
						ec2.InitCommand.shellCommand("hostname onprem"),
						ec2.InitCommand.shellCommand("pip3 install boto3"),
						ec2.InitCommand.shellCommand(
							"sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons"
						),
						ec2.InitCommand.shellCommand("aa-complain /usr/lib/ipsec/charon"),
						ec2.InitCommand.shellCommand("aa-complain /usr/lib/ipsec/stroke"),
						ec2.InitCommand.shellCommand("netplan apply"),
						ec2.InitCommand.shellCommand("apt -y install dnsmasq"),
					]),
				},
			}),
			initOptions: {
				timeout: Duration.minutes(10),
			},
		});

		new ec2.CfnEIPAssociation(this, "ElasticIPAssociation", {
			allocationId: elasticIp.attrAllocationId,
			instanceId: instance.instanceId,
		});

		(instance.node.defaultChild as ec2.CfnInstance).overrideLogicalId(
			"OnPremisesInstance"
		);
	}
}

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

interface VpnStackProps extends StackProps {
	cloudWanRegion: string;
}

export class VpnStack extends Stack {
	constructor(scope: Construct, id: string, props: VpnStackProps) {
		super(scope, id, props);

		const sdkCallCoreNetId: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "CloudWanCoreNetworkId",
			},
			region: props.cloudWanRegion,
			physicalResourceId: cr.PhysicalResourceId.of("VpnCoreNetworkId"),
		};

		const coreNetworkId = new cr.AwsCustomResource(
			this,
			"CustomResourceVpnCoreNetworkId",
			{
				onCreate: sdkCallCoreNetId,
				onUpdate: sdkCallCoreNetId,
				policy: cr.AwsCustomResourcePolicy.fromStatements([
					new iam.PolicyStatement({
						actions: ["ssm:GetParameter"],
						effect: iam.Effect.ALLOW,
						resources: [
							`arn:aws:ssm:${props.cloudWanRegion}:${Stack.of(this).account}:parameter/CloudWanCoreNetworkId`,
						],
					}),
				]),
			}
		);

		const sdkCallOnPremisesIp: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "OnPremisesIp",
			},
			region: "eu-west-2",
			physicalResourceId: cr.PhysicalResourceId.of("VpnOnPremisesIp"),
		};

		const onPremisesIp = new cr.AwsCustomResource(
			this,
			"CustomResourceOnPremisesIp",
			{
				onCreate: sdkCallOnPremisesIp,
				onUpdate: sdkCallOnPremisesIp,
				policy: cr.AwsCustomResourcePolicy.fromStatements([
					new iam.PolicyStatement({
						actions: ["ssm:GetParameter"],
						effect: iam.Effect.ALLOW,
						resources: [
							`arn:aws:ssm:eu-west-2:${Stack.of(this).account}:parameter/OnPremisesIp`,
						],
					}),
				]),
			}
		);

		const customerGateway = new ec2.CfnCustomerGateway(
			this,
			"VpnCustomerGateway",
			{
				type: "ipsec.1",
				ipAddress: onPremisesIp.getResponseField("Parameter.Value"),
				bgpAsn: 64512,
				deviceName: "cgw-cwan-workshop",
			}
		);

		const vpn = new ec2.CfnVPNConnection(this, "VpnConnection", {
			customerGatewayId: customerGateway.attrCustomerGatewayId,
			type: "ipsec.1",
			tags: [
				{
					key: "Name",
					value: "onpremises",
				},
			],
		});

		new nm.CfnSiteToSiteVpnAttachment(this, "VpnAttachment", {
			vpnConnectionArn: `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:vpn-connection/${vpn.attrVpnConnectionId}`,
			coreNetworkId: coreNetworkId.getResponseField("Parameter.Value"),
			tags: [
				{
					key: "Name",
					value: `stockholm-onpremises-vpn`,
				},
				{
					key: "domain",
					value: "onpremises",
				},
			],
		});
	}
}

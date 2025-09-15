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
	cloudWanRegion: string;
	tgwAsn: number;
	lab: string;
}

export class TransitGatewayStack extends Stack {
	public readonly transitGatewayId: string;
	public readonly routeTableId: string;

	constructor(scope: Construct, id: string, props: WorkloadStackProps) {
		super(scope, id, props);

		const transitGateway = new ec2.CfnTransitGateway(
			this,
			"LegacyTransitGateway",
			{
				description: `legacy-tgw-${Stack.of(this).region}`,
				amazonSideAsn: props.tgwAsn,
				defaultRouteTableAssociation: "disable",
				defaultRouteTablePropagation: "disable",
				tags: [
					{
						key: "Name",
						value: `legacy-tgw-${Stack.of(this).region}`,
					},
				],
			}
		);

		this.transitGatewayId = transitGateway.attrId;

		const routeTable = new ec2.CfnTransitGatewayRouteTable(
			this,
			"LegacyTGWRouteTable",
			{
				transitGatewayId: transitGateway.attrId,
				tags: [
					{
						key: "Name",
						value: `legacy-tgw-rt-${Stack.of(this).region}`,
					},
				],
			}
		);
		this.routeTableId = routeTable.attrTransitGatewayRouteTableId;

		/*
		 * Cloud WAN Peering. Get Global Network ID and Core Network ID from SSM parameters.
		 * This is required because we are deploying in a single region and Resource Access Manager (RAM) is not usable.
		 */
		// const globalNetworkId = this.getCloudWanGlobalNetworkId(
		//   props.environmentName,
		//   props.cloudWanRegion
		// );
		const coreNetworkId = this.getCloudWanCoreNetworkId(props.cloudWanRegion);

		// new nm.CfnTransitGatewayRegistration(
		//   this,
		//   `${props.environmentName}TransitGatewayRegistration`,
		//   {
		//     transitGatewayArn: transitGateway.attrTransitGatewayArn,
		//     globalNetworkId: globalNetworkId.getResponseField("Parameter.Value"),
		//   }
		// );

		// If lab is 2 or 3, then deploy Transit Gateway Peering and Policy Table
		if (props.lab === "lab2" || props.lab === "lab3") {
			const peering = new nm.CfnTransitGatewayPeering(
				this,
				"LegacyTransitGatewayPeering",
				{
					coreNetworkId: coreNetworkId.getResponseField("Parameter.Value"),
					transitGatewayArn: transitGateway.attrTransitGatewayArn,
					tags: [
						{
							key: "Name",
							value: `${Stack.of(this).region === "us-west-2" ? "oregon" : "stockholm"}-legacy-tgw`,
						},
					],
				}
			);

			const policyTable = this.createTransitGatewayPolicytable(
				transitGateway.attrId
			);
			this.associatePolicyTable(policyTable, peering, routeTable);
		}
	}

	private getCloudWanGlobalNetworkId(
		cloudWanRegion: string
	): cr.AwsCustomResource {
		const sdkCallGlobalNetId: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "CloudWanGlobalNetworkId",
			},
			region: cloudWanRegion,
			physicalResourceId: cr.PhysicalResourceId.of("LegacyGlobalNetworkId"),
		};

		return new cr.AwsCustomResource(
			this,
			"LegacyCustomResourceGlobalNetworkId",
			{
				onCreate: sdkCallGlobalNetId,
				onUpdate: sdkCallGlobalNetId,
				policy: cr.AwsCustomResourcePolicy.fromStatements([
					new iam.PolicyStatement({
						actions: ["ssm:GetParameter"],
						effect: iam.Effect.ALLOW,
						resources: [
							`arn:aws:ssm:${cloudWanRegion}:${Stack.of(this).account}:parameter/CloudWanGlobalNetworkId`,
						],
					}),
				]),
			}
		);
	}

	private getCloudWanCoreNetworkId(
		cloudWanRegion: string
	): cr.AwsCustomResource {
		const sdkCallCoreNetId: cr.AwsSdkCall = {
			service: "SSM",
			action: "getParameter",
			parameters: {
				Name: "CloudWanCoreNetworkId",
			},
			region: cloudWanRegion,
			physicalResourceId: cr.PhysicalResourceId.of("LegagySDKCoreNetworkId"),
		};

		return new cr.AwsCustomResource(this, "LegacyCustomResourceCoreNetworkId", {
			onCreate: sdkCallCoreNetId,
			onUpdate: sdkCallCoreNetId,
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

	private createTransitGatewayPolicytable(
		transitGatewayId: string
	): cr.AwsCustomResource {
		const sdkCallCreatePolicyTable: cr.AwsSdkCall = {
			service: "ec2",
			action: "createTransitGatewayPolicyTable",
			parameters: {
				TransitGatewayId: transitGatewayId,
				TagSpecifications: [
					{
						ResourceType: "transit-gateway-policy-table",
						Tags: [
							{
								Key: "Name",
								Value: "LegacyPolicyTable",
							},
						],
					},
				],
			},
			region: Stack.of(this).region,
			physicalResourceId: cr.PhysicalResourceId.of("LegacySDKPolicyTable"),
		};

		return new cr.AwsCustomResource(
			this,
			"LegcyCustomResourceCreatePolicyTable",
			{
				onCreate: sdkCallCreatePolicyTable,
				onUpdate: sdkCallCreatePolicyTable,
				policy: cr.AwsCustomResourcePolicy.fromStatements([
					new iam.PolicyStatement({
						actions: ["ec2:CreateTransitGatewayPolicyTable", "ec2:CreateTags"],
						effect: iam.Effect.ALLOW,
						resources: ["*"],
					}),
				]),
			}
		);
	}

	private associatePolicyTable(
		policyTable: cr.AwsCustomResource,
		peering: nm.CfnTransitGatewayPeering,
		routeTable: ec2.CfnTransitGatewayRouteTable
	) {
		const sdkCallAssociatePolicyTable: cr.AwsSdkCall = {
			service: "ec2",
			action: "associateTransitGatewayPolicyTable",
			parameters: {
				TransitGatewayPolicyTableId: policyTable.getResponseField(
					"TransitGatewayPolicyTable.TransitGatewayPolicyTableId"
				),
				TransitGatewayAttachmentId:
					peering.attrTransitGatewayPeeringAttachmentId,
			},
			region: Stack.of(this).region,
			physicalResourceId: cr.PhysicalResourceId.of(
				"LegacyPolicyTableAttachment"
			),
		};

		new cr.AwsCustomResource(this, "LegacyCustomResourcePolicyTableAssociate", {
			onCreate: sdkCallAssociatePolicyTable,
			onUpdate: sdkCallAssociatePolicyTable,
			policy: cr.AwsCustomResourcePolicy.fromStatements([
				new iam.PolicyStatement({
					actions: ["ec2:AssociateTransitGatewayPolicyTable"],
					effect: iam.Effect.ALLOW,
					resources: ["*"],
				}),
			]),
		});

		new nm.CfnTransitGatewayRouteTableAttachment(
			this,
			"LegacyRouteTableAttachment",
			{
				transitGatewayRouteTableArn: `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:transit-gateway-route-table/${routeTable.attrTransitGatewayRouteTableId}`,
				peeringId: peering.attrPeeringId,
				tags: [
					{
						key: "Name",
						value: `${Stack.of(this).region === "us-west-2" ? "oregon" : "stockholm"}-legacy`,
					},
					{
						key: "domain",
						value: "legacy",
					},
				],
			}
		);
	}
}

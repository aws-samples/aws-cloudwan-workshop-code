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
	aws_networkmanager as nm,
	aws_ssm as ssm,
	Stack,
	StackProps,
} from "aws-cdk-lib";
import { Construct } from "constructs";

interface CloudWanStackProps extends StackProps {
	lab: string;
}

export class CloudWanStack extends Stack {
	constructor(scope: Construct, id: string, props: CloudWanStackProps) {
		super(scope, id, props);

		const globalNetwork = new nm.CfnGlobalNetwork(this, "GlobalNet", {
			description: "Global Net",
			tags: [{ key: "Name", value: "global-network-cwan-workshop" }],
		});

		const coreNetwork = new nm.CfnCoreNetwork(this, "CoreNetwork", {
			globalNetworkId: globalNetwork.attrId,
			policyDocument: this.createCloudWanPolicy(props.lab),
			description: "Core network",
			tags: [{ key: "Name", value: "core-network-cwan-workshop" }],
		});

		// CloudWAN core network id export
		// This is used when deployment is done in a single account and thus Resource Access Manager (RAM) share is not available.
		new ssm.StringParameter(this, "CoreNetworkId", {
			stringValue: coreNetwork.attrCoreNetworkId,
			parameterName: "CloudWanCoreNetworkId",
		});

		// CloudWAN Global network id export
		// This is used when deployment is done in a single account where Resource Access Manager (RAM) share is not available.
		new ssm.StringParameter(this, "GlobalNetworkId", {
			stringValue: coreNetwork.attrCoreNetworkId,
			parameterName: "CloudWanGlobalNetworkId",
		});
	}

	// Constructing Cloud WAN policy for this workshop. This is complex to support the multiple workshop scenarios.
	private createCloudWanPolicy(lab: string): object {
		const policyInitial: object = {
			version: "2021.12",
			"core-network-configuration": {
				"vpn-ecmp-support": false,
				"asn-ranges": ["64520-65525"],
				"edge-locations": [
					{
						location: "us-west-2",
					},
					{
						location: "eu-north-1",
					},
				],
			},
			segments: [
				{
					name: "prod",
					"edge-locations": ["us-west-2", "eu-north-1"],
					"require-attachment-acceptance": false,
				},
				{
					name: "thirdparty",
					"edge-locations": ["us-west-2", "eu-north-1"],
					"isolate-attachments": true,
					"require-attachment-acceptance": false,
				},
				{
					name: "onpremises",
					"require-attachment-acceptance": false,
				},
			],
			"network-function-groups": [
				{
					name: "EgressInspectionVpcs",
					"require-attachment-acceptance": false,
				},
				{
					name: "InspectionVpcs",
					"require-attachment-acceptance": false,
				},
			],
		};

		const policyLab1: object = {
			"attachment-policies": [
				{
					"rule-number": 100,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-value",
							operator: "equals",
							key: "nfg",
							value: "inspection",
						},
					],
					action: {
						"add-to-network-function-group": "InspectionVpcs",
					},
				},
				{
					"rule-number": 200,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-value",
							operator: "equals",
							key: "nfg",
							value: "egressinspection",
						},
					],
					action: {
						"add-to-network-function-group": "EgressInspectionVpcs",
					},
				},
				{
					"rule-number": 300,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-exists",
							key: "domain",
						},
					],
					action: {
						"association-method": "tag",
						"tag-value-of-key": "domain",
					},
				},
			],
			"segment-actions": [
				{
					action: "share",
					mode: "attachment-route",
					segment: "onpremises",
					"share-with": ["prod"],
				},
				{
					action: "send-to",
					segment: "prod",
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
					},
				},
				{
					action: "send-to",
					segment: "thirdparty",
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
					},
				},
				{
					action: "send-via",
					segment: "thirdparty",
					mode: "dual-hop",
					"when-sent-to": {
						segments: ["prod"],
					},
					via: {
						"network-function-groups": ["InspectionVpcs"],
					},
				},
			],
		};

		const policyLab2AttachmentPolicy: object = {
			"rule-number": 400,
			"condition-logic": "or",
			conditions: [
				{
					type: "attachment-type",
					operator: "equals",
					value: "transit-gateway-route-table",
					action: {
						"association-method": "constant",
						segment: "legacy",
					},
				},
			],
		};

		const policyLab2SegmentAction: object = {
			action: "share",
			mode: "attachment-route",
			segment: "legacy",
			"share-with": ["prod"],
		};

		const policyLab3: object = {
			version: "2021.12",
			"core-network-configuration": {
				"vpn-ecmp-support": false,
				"asn-ranges": ["64520-65525"],
				"edge-locations": [
					{
						location: "eu-north-1",
					},
					{
						location: "us-west-2",
					},
				],
			},
			segments: [
				{
					name: "prod",
					"require-attachment-acceptance": false,
					"edge-locations": ["eu-north-1", "us-west-2"],
				},
				{
					name: "thirdparty",
					"isolate-attachments": true,
					"require-attachment-acceptance": false,
					"edge-locations": ["eu-north-1", "us-west-2"],
				},
				{
					name: "onpremises",
					"require-attachment-acceptance": false,
				},
				{
					name: "legacy",
					"require-attachment-acceptance": false,
					"edge-locations": ["eu-north-1", "us-west-2"],
				},
			],
			"network-function-groups": [
				{
					name: "EgressInspectionVpcs",
					"require-attachment-acceptance": false,
				},
				{
					name: "InspectionVpcs",
					"require-attachment-acceptance": false,
				},
			],
			"attachment-policies": [
				{
					"rule-number": 100,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-value",
							operator: "equals",
							key: "nfg",
							value: "inspection",
						},
					],
					action: {
						"add-to-network-function-group": "InspectionVpcs",
					},
				},
				{
					"rule-number": 200,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-value",
							operator: "equals",
							key: "nfg",
							value: "egressinspection",
						},
					],
					action: {
						"add-to-network-function-group": "EgressInspectionVpcs",
					},
				},
				{
					"rule-number": 300,
					"condition-logic": "or",
					conditions: [
						{
							type: "tag-exists",
							key: "domain",
						},
					],
					action: {
						"association-method": "tag",
						"tag-value-of-key": "domain",
					},
				},
				{
					"rule-number": 400,
					"condition-logic": "or",
					conditions: [
						{
							type: "attachment-type",
							operator: "equals",
							value: "transit-gateway-route-table",
						},
					],
					action: {
						"association-method": "constant",
						segment: "legacy",
					},
				},
			],
			"segment-actions": [
				{
					action: "send-to",
					segment: "prod",
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
					},
				},
				{
					action: "send-to",
					segment: "thirdparty",
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
					},
				},
				{
					action: "send-via",
					segment: "thirdparty",
					mode: "single-hop",
					"when-sent-to": {
						segments: ["prod"],
					},
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
					},
				},
				{
					action: "send-via",
					segment: "prod",
					mode: "single-hop",
					"when-sent-to": {
						segments: ["onpremises"],
					},
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
						"with-edge-overrides": [
							{
								"edge-sets": [["us-west-2", "eu-north-1"]],
								"use-edge-location": "eu-north-1",
							},
						],
					},
				},
				{
					action: "send-via",
					segment: "thirdparty",
					mode: "single-hop",
					via: {
						"network-function-groups": ["EgressInspectionVpcs"],
						"with-edge-overrides": [
							{
								"edge-sets": [["us-west-2", "eu-north-1"]],
								"use-edge-location": "eu-north-1",
							},
						],
					},
				},
				{
					action: "share",
					mode: "attachment-route",
					segment: "legacy",
					"share-with": ["prod"],
				},
			],
		};

		if (lab === "lab1") {
			return {
				...policyInitial,
				...policyLab1,
			};
		} else if (lab === "lab2") {
			// eslint-disable-next-line @typescript-eslint/no-explicit-any
			const policy: any = {
				...policyInitial,
				...policyLab1,
			};
			policy["attachment-policies"].push(policyLab2AttachmentPolicy);
			policy["segment-actions"].push(policyLab2SegmentAction);
			return policy;
		} else if (lab === "lab3") {
			return policyLab3;
		} else {
			return policyInitial;
		}
	}
}

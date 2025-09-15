#!/usr/bin/env node
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

import * as cdk from "aws-cdk-lib";
import { CloudWanStack } from "../lib/cloudwan";
import { InspectionStack } from "../lib/inspection";
import { WorkloadStack } from "../lib/workload";
import { TransitGatewayStack } from "../lib/transitgateway";
import { OnPremisesStack } from "../lib/onpremises";
import { VpnStack } from "../lib/vpn";

// Configuration values
export const regions: string[] = ["us-west-2", "eu-north-1"];
export const cloudWanRegion: string = "us-west-2";
const organisationCidr = "10.0.0.0/8";
const onPremCidr = "192.168.100.0/24";
const tgwCidrs: { [key: string]: string } = {
	"us-west-2": "10.12.0.0/16",
	"eu-north-1": "10.2.0.0/16",
};
const cwanProdCidrs: { [key: string]: string } = {
	"us-west-2": "10.10.0.0/16",
	"eu-north-1": "10.0.0.0/16",
};
const cwanThirdPartyCidrs: { [key: string]: string } = {
	"us-west-2": "10.11.0.0/16",
	"eu-north-1": "10.1.0.0/16",
};
const tgwAsn: { [key: string]: number } = {
	"us-west-2": 65527,
	"eu-north-1": 65526,
};

const app = new cdk.App();

const lab = app.node.tryGetContext("lab");

new CloudWanStack(app, "CloudWan", {
	lab,
	env: {
		region: cloudWanRegion,
	},
});

regions.forEach((region) => {
	new InspectionStack(app, `EgressInspection-${region}`, {
		cidr: "100.64.0.0/16",
		cloudWanRegion,
		cloudWanSegment: "egressinspection",
		egressInspection: true,
		lab,
		onPremCidr,
		organisationCidr,
		env: {
			region,
		},
	});

	new InspectionStack(app, `Inspection-${region}`, {
		cidr: "100.64.0.0/16",
		cloudWanRegion,
		cloudWanSegment: "inspection",
		egressInspection: false,
		lab,
		onPremCidr,
		organisationCidr,
		env: {
			region,
		},
	});

	// Worklaods for Cloud WAN
	new WorkloadStack(app, `ProductionWorkload-${region}`, {
		cidr: cwanProdCidrs[region],
		cloudWanRegion,
		cloudWanSegment: "prod",
		environmentName: "prod",
		lab,
		env: {
			region,
		},
	});

	new WorkloadStack(app, `ThirdPartyWorkload-${region}`, {
		cidr: cwanThirdPartyCidrs[region],
		cloudWanRegion,
		cloudWanSegment: "thirdparty",
		environmentName: "thirdparty",
		lab,
		env: {
			region,
		},
	});

	// Stacks for Legacy environment
	const transitGateway = new TransitGatewayStack(
		app,
		`TransitGateway-${region}`,
		{
			cloudWanRegion,
			lab,
			tgwAsn: tgwAsn[region],
			env: {
				region,
			},
		}
	);

	new WorkloadStack(app, `LegacyWorkload-${region}`, {
		cidr: tgwCidrs[region],
		environmentName: "legacy",
		lab,
		transitGatewayId: transitGateway.transitGatewayId,
		routeTableId: transitGateway.routeTableId,
		env: {
			region,
		},
	});
});

// Deploy single region resources
new OnPremisesStack(app, "Onpremises-eu-west-2", {
	cidr: "100.64.0.0/24",
	cloudWanRegion,
	lab,
	env: {
		region: "eu-west-2",
	},
});

new VpnStack(app, "Vpn-eu-north-1", {
	cloudWanRegion,
	env: {
		region: "eu-north-1",
	},
});

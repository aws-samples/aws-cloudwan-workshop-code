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

import fs from 'fs';
import path from 'path';
import { App } from 'aws-cdk-lib';
import { CloudWanStack } from './cloudwan-stack';
import { InspectionStack  } from './inspection-stack';
import { WorkloadStack } from './workload-stack';

// Global variables to set network
const organisationCidr = '10.0.0.0/8';

const app = new App();

/**
 * CloudWAN policy JSON to use.
 * If there is no active configuration created, then we will default to init policy.
 * Otherwise load active configuration.
 */

let cloudWanPolicy: string;
if (fs.existsSync(path.join(__dirname, 'cloudwan-policy-active.json'))) {
  cloudWanPolicy = 'cloudwan-policy-active.json';
} else {
  cloudWanPolicy = 'cloudwan-policy-init.json';
}


new CloudWanStack(app, 'CloudWAN', {
  env: {
    region: 'us-east-1',
  },
  policyFile: cloudWanPolicy,
});

new InspectionStack(app, 'InspectionUS', {
  env: {
    region: 'us-east-1',
  },
  cloudWanSegment: 'sharedservices',
  cidr: '100.64.0.0/16',
  organisationCidr,
});

new InspectionStack(app, 'InspectionEU', {
  env: {
    region: 'eu-west-1',
  },
  cloudWanSegment: 'sharedservices',
  cidr: '100.64.0.0/16',
  organisationCidr,
});

new WorkloadStack(app, 'WorkloadNonProdEU', {
  env: {
    region: 'eu-west-1',
  },
  vpcCidr: '10.1.0.0/16',
  vpcName: 'eu-nonprod',
  cloudWanSegment: 'nonprod',
});

new WorkloadStack(app, 'WorkloadProdEU', {
  env: {
    region: 'eu-west-1',
  },
  vpcCidr: '10.3.0.0/16',
  vpcName: 'eu-nonprod',
  cloudWanSegment: 'prod',
});

new WorkloadStack(app, 'WorkloadProdUS', {
  env: {
    region: 'us-east-1',
  },
  vpcName: 'us-prod',
  vpcCidr: '10.0.0.0/16',
  cloudWanSegment: 'prod',
});

new WorkloadStack(app, 'WorkloadNonProdUS', {
  env: {
    region: 'us-east-1',
  },
  vpcName: 'us-nonprod',
  vpcCidr: '10.2.0.0/16',
  cloudWanSegment: 'nonprod',
});


app.synth();
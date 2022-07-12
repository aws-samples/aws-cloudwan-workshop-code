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
import {
  Stack, StackProps,
  aws_networkmanager as nm,
  aws_ram as ram,
  aws_ssm as ssm,
} from 'aws-cdk-lib';
import { Construct } from 'constructs';

interface CloudWanStackProps extends StackProps {
  policyFile: string;
}

export class CloudWanStack extends Stack {

  constructor(scope: Construct, id: string, props: CloudWanStackProps ) {
    super(scope, id, props);

    const cloudWanPolicy = JSON.parse(fs.readFileSync(path.join(__dirname, props.policyFile), 'utf-8'));

    const globalNetwork = new nm.CfnGlobalNetwork(this, 'GlobalNet', {
      description: 'Global Net',
      tags: [
        { key: 'Name', value: 'Global-Net' },
        { key: 'Env', value: 'Workshop' },
      ],
    });

    const coreNetwork = new nm.CfnCoreNetwork(this, 'CoreNetwork', {
      globalNetworkId: globalNetwork.attrId,
      policyDocument: cloudWanPolicy,
      description: 'Core network',
      tags: [
        { key: 'Name', value: 'CoreNetwork' },
        { key: 'Env', value: 'Workshop' },
      ],
    });

    // CloudWAN core network id export
    // For usage in same account in different regions.
    new ssm.StringParameter(this, 'CoreNetworkId', {
      stringValue: coreNetwork.attrCoreNetworkId,
      parameterName: 'CloudWanCoreNetworkId',
    });

    // Not used in this example but can be used to share CloudWAN to other accounts
    new ram.CfnResourceShare(this, 'CoreNetworkShare', {
      name: 'CloudWanCoreNetwork',
      allowExternalPrincipals: false,
      resourceArns: [coreNetwork.attrCoreNetworkArn],
    });

  }
}
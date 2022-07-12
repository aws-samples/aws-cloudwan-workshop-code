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

import { NetworkManagerClient, ListAttachmentsCommand, ListAttachmentsCommandOutput, ListCoreNetworksCommand, GetCoreNetworkPolicyCommand } from "@aws-sdk/client-networkmanager";
import { writeFileSync, existsSync } from 'fs';
import path from 'path';

async function getData(): Promise<void> {
  const client = new NetworkManagerClient({region: 'us-east-1'});

  /**
   * Get CloudWAN core network id for downloading policy document
   */
  let coreNetworkId: string = "";
  const networksResponse = await client.send(new ListCoreNetworksCommand({}))
  if (networksResponse.CoreNetworks){
    networksResponse.CoreNetworks.forEach(network => {
      if (network.Tags) {
        network.Tags.forEach(tag => {
          if (tag.Key == 'Env' && tag.Value == 'Workshop') {
            coreNetworkId = network.CoreNetworkId as string
          }
        })
      }
    })
  };

  if ( coreNetworkId == "") {
    throw new Error('Could not get core network ID')
  }

  /**
   * Get all core network attachments
   */

   const attachmentCommand = new ListAttachmentsCommand({CoreNetworkId: coreNetworkId});

   let attachmentList: string[] = [];

   const attachmentResponse: ListAttachmentsCommandOutput = await client.send(attachmentCommand);

   if (attachmentResponse.Attachments) {
     attachmentResponse.Attachments.forEach((attachment) => {
       if (attachment['SegmentName'] === 'sharedservices') {
         attachmentList.push(attachment['AttachmentId'] as unknown as string)
       }
     });
   } else {
     throw new Error(`Couldn't load attachment data from CloudWAN`)
   }

   if (attachmentList.length == 0) {
    throw new Error("No CloudwAN attachments for inspection VPC available");

   }

  /**
  * Download latest active CloudWAN policy
  */
   const policyResponse = await client.send(
    new GetCoreNetworkPolicyCommand({CoreNetworkId: coreNetworkId}))

  if (!policyResponse.CoreNetworkPolicy?.PolicyDocument) {
    throw new Error("Couldn't load CloudWAN policy document");
  }

  updatePolicy(attachmentList, policyResponse.CoreNetworkPolicy.PolicyDocument.toString())
}

function updatePolicy(attachments: string[], policyString: string): void {

  const segments = ['prod', 'nonprod'];
  const policy = JSON.parse(policyString);

  segments.forEach(segment => {
    policy['segment-actions'].push(
      {
        'action': 'create-route',
        'destination-cidr-blocks': ['0.0.0.0/0'],
        'segment': segment,
        'destinations': attachments
      }
    )
  });

  // Write policy to local disk so that we can use it in later step to deploy with CDK.
  // Policy can be committed to Git also once it is on disk.
  try {
    writeFileSync('src/cloudwan-policy-active.json', JSON.stringify(policy));
  } catch {
    throw new Error(`Couldn't write policy to a file`);
  }
}

// Check that there is no previously created CloudWAN policy. This code is designed to work only for first time deployment.
if (existsSync(path.join(__dirname, 'src/cloudwan-policy-active.json'))) {
  throw new Error('CloudWAN policy has been already created. \
  This code is designed to be used for first time deployment only. For redeploy, delete src/cloudwan-policy-active.json')
}

getData();
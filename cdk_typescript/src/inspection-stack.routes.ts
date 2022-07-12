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
  CreateRouteCommand,
  DeleteRouteCommand,
  EC2Client,
  EC2ServiceException
} from '@aws-sdk/client-ec2';
import {
  NetworkFirewallClient,
  DescribeFirewallCommand,
} from '@aws-sdk/client-network-firewall';


import {
  CloudFormationCustomResourceCreateEvent,
  CloudFormationCustomResourceEvent,
  CloudFormationCustomResourceUpdateEvent,
  CloudFormationCustomResourceDeleteEvent,
} from 'aws-lambda';

const nfw = new NetworkFirewallClient({});
const ec2 = new EC2Client({});

export async function onEvent(event: CloudFormationCustomResourceEvent) {
  switch (event.RequestType) {
    case 'Create':
      return create(event as CloudFormationCustomResourceCreateEvent);
    case 'Update':
      return update(event as CloudFormationCustomResourceUpdateEvent);
    case 'Delete':
      return destroy(event as CloudFormationCustomResourceDeleteEvent);
  }
}

async function create(event: CloudFormationCustomResourceCreateEvent) {
  const physResourceId =
    event.LogicalResourceId + '-' + event.RequestId.replace(/-/g, '') + '.txt';
  console.log(event.ResourceProperties);
  const firewallArn = event.ResourceProperties.FirewallArn;

  const endpoints = await getData(firewallArn);

  if ('DestinationCidr' in event.ResourceProperties) {
    const command = new CreateRouteCommand({
      DestinationCidrBlock: event.ResourceProperties.DestinationCidr,
      RouteTableId: event.ResourceProperties.RouteTableId,
      VpcEndpointId: endpoints[event.ResourceProperties.SubnetAz],
    });
    await send(command);

  } else if ('DestinationIpv6CidrBlock' in event.ResourceProperties) {
    const command = new CreateRouteCommand({
      DestinationIpv6CidrBlock: event.ResourceProperties.DestinationIpv6CidrBlock,
      RouteTableId: event.ResourceProperties.RouteTableId,
      VpcEndpointId: endpoints[event.ResourceProperties.SubnetAz],
    });
    await send(command);
  }

  return {
    PhysicalResourceId: physResourceId,
  };
}

async function update(event: CloudFormationCustomResourceUpdateEvent) {
  const firewallArn = event.ResourceProperties.FirewallArn;
  return {
    Data: await getData(firewallArn),
  };
}

async function destroy(event: CloudFormationCustomResourceDeleteEvent) {

  if ('DestinationCidr' in event.ResourceProperties) {
    const command = new DeleteRouteCommand({
      DestinationCidrBlock: event.ResourceProperties.DestinationCidr,
      RouteTableId: event.ResourceProperties.RouteTableId,
    });
    await send(command);

  } else if ('DestinationIpv6CidrBlock' in event.ResourceProperties) {
    const command = new DeleteRouteCommand({
      DestinationIpv6CidrBlock: event.ResourceProperties.DestinationIpv6CidrBlock,
      RouteTableId: event.ResourceProperties.RouteTableId,
    });
    await send(command);
  }

  return {};
}

async function getData(FirewallArn: string) {
  const command = new DescribeFirewallCommand({
    FirewallArn: FirewallArn,
  });
  const response = await nfw.send(command);

  const data = Object.fromEntries(
    Object.entries(response.FirewallStatus?.SyncStates!).map(([k, v]) => [
      `${k}`,
      v.Attachment?.EndpointId,
    ]),
  );
  return data;
}

async function send(command: CreateRouteCommand | DeleteRouteCommand) {
  try {
    const response = await ec2.send(command);
    console.log(response);
  } catch (error) {
    console.log(error);
    if (error instanceof EC2ServiceException) {
      console.log(error.name)
    }
  }
}
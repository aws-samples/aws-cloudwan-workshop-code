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
  Stack, StackProps, Fn,
  aws_ec2 as ec2,
  aws_iam as iam,
  aws_networkmanager as nm,
  aws_logs as logs,
  custom_resources as cr,
} from 'aws-cdk-lib';
import { Construct } from 'constructs';

interface WorkloadStackProps extends StackProps {
  vpcName: string;
  vpcCidr: string;
  cloudWanSegment: string;
}

export class WorkloadStack extends Stack {
  constructor(scope: Construct, id: string, props: WorkloadStackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, `${props.vpcName}-${Stack.of(this).region}`, {
      vpcName: props.vpcName + '-' + props.env?.region,
      cidr: props.vpcCidr,
      subnetConfiguration: [
        {
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          name: 'Private',
          cidrMask: 24,
        }
      ]
    });

    const ipv6Cidr = new ec2.CfnVPCCidrBlock(this, 'CidrBlock', {
      vpcId: vpc.vpcId,
      amazonProvidedIpv6CidrBlock: true,
    });

    const subnets = vpc.selectSubnets({subnetGroupName: 'Private'}).subnets;
    for (let i = 0; i < subnets.length; i++) {
      const cfnSubnet = subnets[i].node.defaultChild as ec2.CfnSubnet;
      cfnSubnet.ipv6CidrBlock = Fn.select(i, Fn.cidr(Fn.select(0, vpc.vpcIpv6CidrBlocks), 2, "64"));
      cfnSubnet.assignIpv6AddressOnCreation = true;
      cfnSubnet.addDependsOn(ipv6Cidr);
    }

    const ssmSdkCall: cr.AwsSdkCall = {
      service: 'SSM',
      action: 'getParameter',
      parameters: {
        Name: 'CloudWanCoreNetworkId',
      },
      region: 'us-east-1',
      physicalResourceId: cr.PhysicalResourceId.of(`${vpc.vpcId}-cloudwan-id`),
    };

    const cloudWanId = new cr.AwsCustomResource(this, 'CloudWanId', {
      onCreate: ssmSdkCall,
      onUpdate: ssmSdkCall,
      logRetention: logs.RetentionDays.FIVE_DAYS,
      policy: cr.AwsCustomResourcePolicy.fromStatements([
        new iam.PolicyStatement({
          actions: ['ssm:GetParameter'],
          effect: iam.Effect.ALLOW,
          resources: [`arn:aws:ssm:us-east-1:${Stack.of(this).account}:parameter/CloudWanCoreNetworkId`],
        }),
      ]),
    });

    const subnetArns: string[] = vpc.isolatedSubnets.map(subnet => `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:subnet/${subnet.subnetId}`);
    const attachment = new nm.CfnVpcAttachment(this, props.vpcName + 'CloudwanAttachment', {
      coreNetworkId: cloudWanId.getResponseField('Parameter.Value'),
      subnetArns: subnetArns,
      vpcArn: vpc.vpcArn,
      options: {
        ipv6Support: true
      },
      tags: [
        {
          key: props.cloudWanSegment,
          value: 'cloudwan-segment',
        },
        {
          key: 'Name',
          value: `Workload-${props.vpcName}`,
        },
      ],
    });

    // Create default route towards CloudWAN attachment
    for (const subnet of vpc.selectSubnets({ subnetGroupName: 'Private' }).subnets) {

      const addRoutev4SdkCall: cr.AwsSdkCall = {
        service: 'EC2',
        action: 'createRoute',
        parameters: {
          CoreNetworkArn: `arn:aws:networkmanager::${Stack.of(this).account}:core-network/${cloudWanId.getResponseField('Parameter.Value')}`,
          RouteTableId: subnet.routeTable.routeTableId,
          DestinationCidrBlock: '0.0.0.0/0',
        },
        region: Stack.of(this).region,
        physicalResourceId: cr.PhysicalResourceId.of(subnet.routeTable.routeTableId + '-cloudwan-route'),
      };

      const addRoutev6SdkCall: cr.AwsSdkCall = {
        service: 'EC2',
        action: 'createRoute',
        parameters: {
          CoreNetworkArn: `arn:aws:networkmanager::${Stack.of(this).account}:core-network/${cloudWanId.getResponseField('Parameter.Value')}`,
          RouteTableId: subnet.routeTable.routeTableId,
          DestinationIpv6CidrBlock: '::/0',
        },
        region: Stack.of(this).region,
        physicalResourceId: cr.PhysicalResourceId.of(subnet.routeTable.routeTableId + '-cloudwan-route'),
      };

      new cr.AwsCustomResource(this, `${subnet.node.id}-v4route`, {
        onCreate: addRoutev4SdkCall,
        onUpdate: addRoutev4SdkCall,
        logRetention: logs.RetentionDays.FIVE_DAYS,
        policy: cr.AwsCustomResourcePolicy.fromStatements([
          new iam.PolicyStatement({
            actions: ['ec2:CreateRoute'],
            effect: iam.Effect.ALLOW,
            resources: [`arn:aws:ec2:*:*:route-table/${subnet.routeTable.routeTableId}`],
          }),
        ]),
      }).node.addDependency(attachment);

      new cr.AwsCustomResource(this, `${subnet.node.id}-v6route`, {
        onCreate: addRoutev6SdkCall,
        onUpdate: addRoutev6SdkCall,
        logRetention: logs.RetentionDays.FIVE_DAYS,
        policy: cr.AwsCustomResourcePolicy.fromStatements([
          new iam.PolicyStatement({
            actions: ['ec2:CreateRoute'],
            effect: iam.Effect.ALLOW,
            resources: [`arn:aws:ec2:*:*:route-table/${subnet.routeTable.routeTableId}`],
          }),
        ]),
      }).node.addDependency(attachment);

    }

    /*
    * EC2 instance to test connectivity through CloudWAN
    * Instance connects to AWS SSM through VPC endpoints so
    * that the connectivity is always available regardless of CloudWAN config
    */
    vpc.addInterfaceEndpoint('SsmEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.SSM,
    });
    vpc.addInterfaceEndpoint('SsmMessagesEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.SSM_MESSAGES,
    });
    vpc.addInterfaceEndpoint('Ec2MessagesEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.EC2_MESSAGES,
    });

    const ssmRole = new iam.Role(this, 'SSMRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });

    const sg = new ec2.SecurityGroup(this, 'WorkloadEC2SG', {
      securityGroupName: 'workload-sg',
      vpc: vpc,
    });

    sg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.icmpType(8));
    sg.addIngressRule(ec2.Peer.anyIpv6(), ec2.Port.icmpType(8));

    new ec2.Instance(this, `WorkloadEC2-${props.env?.region}`, {
      vpc: vpc,
      vpcSubnets: vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_ISOLATED }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO),
      machineImage: ec2.MachineImage.latestAmazonLinux({
        cpuType: ec2.AmazonLinuxCpuType.ARM_64,
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
      }),
      role: ssmRole,
      securityGroup: sg
    });
  }
}

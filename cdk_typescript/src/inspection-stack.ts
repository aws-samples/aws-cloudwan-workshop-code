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
  Stack, StackProps, RemovalPolicy,
  aws_networkfirewall as nf,
  aws_ec2 as ec2,
  aws_logs as logs,
  aws_iam as iam,
  aws_networkmanager as nm,
  aws_lambda as lambda,
  aws_lambda_nodejs as lambdaNodejs,
  Duration,
  CustomResource,
  custom_resources as cr,
} from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { NetworkFirewallRules } from './firewall-rules';

interface InspectionStackProps extends StackProps {
  cloudWanSegment: string;
  cidr: string;
  organisationCidr: string;
};

export class InspectionStack extends Stack {
  constructor(scope: Construct, id: string, props: InspectionStackProps) {
    super(scope, id, props);

    /*
    * Inspection VPC for AWS Network Firewall
    * Creates three subnet groups that are used for
    * CloudWAN attachments, AWS Network Firewall endpoints
    * and NAT gateways.
    */

    const vpc = new ec2.Vpc(this, 'InspectionVPC', {
      vpcName: 'inspection-vpc',
      cidr: props.cidr,
      subnetConfiguration: [
        {
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          name: 'CloudWanAttachment',
          cidrMask: 26,
        },
        {
          subnetType: ec2.SubnetType.PRIVATE_WITH_NAT,
          name: 'NetworkFirewall',
          cidrMask: 27,
        },
        {
          subnetType: ec2.SubnetType.PUBLIC,
          name: 'Public',
          cidrMask: 27,
        },
      ],
    });

    /*
    * When VPC is created in same account as the CloudWAN. We need to get CloudWAN ID
    * from AWS SSM parameters instead of AWS RAM share.
    * AWS RAM doesn't work within same account.
    */
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

    /**
     * Select all subnets from subnet group named CloudWANAttachment and create ARNs for those.
     * Create CloudWAN attachment to both of those subnets.
     */
    const subnetArns: string[] = vpc.selectSubnets({ subnetGroupName: 'CloudWanAttachment' }).subnets
      .map(subnet => `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:subnet/${subnet.subnetId}`);

    const cloudWanAttachment = new nm.CfnVpcAttachment(this, 'CloudWanAttachment', {
      coreNetworkId: cloudWanId.getResponseField('Parameter.Value'),
      subnetArns: subnetArns,
      vpcArn: vpc.vpcArn,
      tags: [
        {
          key: props.cloudWanSegment,
          value: 'cloudwan-segment',
        },
        {
          key: 'Name',
          value: `Inspection-${Stack.of(this).region}`,
        },
      ],
    });

    /**
     * Create route towards organisation network behind CloudWAN.
     * Select all subnets in Network Firewall subnet group and insert route towards CloudWAN attachment.
     * Uses CloudWAN ID from earlier custom call that gets it from SSM parameter store.
     */
    for (const subnet of vpc.selectSubnets({ subnetGroupName: 'NetworkFirewall' }).subnets) {
      const addRouteSdkCall: cr.AwsSdkCall = {
        service: 'EC2',
        action: 'createRoute',
        parameters: {
          CoreNetworkArn: `arn:aws:networkmanager::${Stack.of(this).account}:core-network/${cloudWanId.getResponseField('Parameter.Value')}`,
          RouteTableId: subnet.routeTable.routeTableId,
          DestinationCidrBlock: props.organisationCidr,
        },
        region: Stack.of(this).region,
        physicalResourceId: cr.PhysicalResourceId.of(`${subnet.routeTable.routeTableId}-cloudwan-route`),
      };

      const deleteRouteSdkCall: cr.AwsSdkCall = {
        service: 'EC2',
        action: 'deleteRoute',
        parameters: {
          RouteTableId: subnet.routeTable.routeTableId,
          DestinationCidrBlock: props.organisationCidr,
        },
        region: Stack.of(this).region,
      };

      new cr.AwsCustomResource(this, subnet.node.id + '-route', {
        onCreate: addRouteSdkCall,
        onUpdate: addRouteSdkCall,
        onDelete: deleteRouteSdkCall,
        logRetention: logs.RetentionDays.FIVE_DAYS,
        policy: cr.AwsCustomResourcePolicy.fromStatements([
          new iam.PolicyStatement({
            actions: ['ec2:CreateRoute', 'ec2:DeleteRoute'],
            effect: iam.Effect.ALLOW,
            resources: [`arn:aws:ec2:*:*:route-table/${subnet.routeTable.routeTableId}`],
          }),
        ]),
      }).node.addDependency(cloudWanAttachment);
    };


    /**
     * Create rules for AWS Network Firewall
     * Rules are defined in separate file
    */
    const FirewallRules = new NetworkFirewallRules(this, 'NetworkFirewallRules');

    // Subnet mapping list for AWS Network Firewall
    let subnetList: nf.CfnFirewall.SubnetMappingProperty[] = [];
    subnetList = vpc.selectSubnets({ subnetGroupName: 'NetworkFirewall' }).subnets.map(subnet =>
      ({ subnetId: subnet.subnetId }),
    );

    // Network firewall
    const networkFw = new nf.CfnFirewall(this, 'NetworkFirewall', {
      firewallName: 'EgressInspectionFirewall',
      firewallPolicyArn: FirewallRules.firewallPolicy.attrFirewallPolicyArn,
      subnetMappings: subnetList,
      vpcId: vpc.vpcId,
    });

    // CloudWatch Logs group to store Network Firewall flow logs
    const fwFlowLogsGroup = new logs.LogGroup(this, 'FWFlowLogsGroup', {
      logGroupName: 'NetworkFirewallFlowLogs',
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // CloudWatch Logs group to store Network Firewall alert logs
    const fwAlertLogsGroup = new logs.LogGroup(this, 'FWAlertLogsGroup', {
      logGroupName: 'NetworkFirewallAlertLogs',
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // Firewall logging configuration to enable both flow and alert logs
    new nf.CfnLoggingConfiguration(this, 'FirewallLogConf', {
      firewallArn: networkFw.ref,
      loggingConfiguration: {
        logDestinationConfigs: [{
          logDestination: { logGroup: fwFlowLogsGroup.logGroupName },
          logDestinationType: 'CloudWatchLogs',
          logType: 'FLOW',
        },
        {
          logDestination: { logGroup: fwAlertLogsGroup.logGroupName },
          logDestinationType: 'CloudWatchLogs',
          logType: 'ALERT',
        }],
      },
    });

    /*
		* Lambda function and custom action to create and delete routes to
		* Gateway Load Balancer endpoints in correct availability zones
		*/
    const routeLambdaRole = new iam.Role(this, 'routeLambdaRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    routeLambdaRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'network-firewall:DescribeFirewall',
        ],
        resources: [networkFw.attrFirewallArn],
      }),
    );

    // Get route table ARN for each subnet to be used for Lambda permission policy
    const cloudWANSubnetsArns: string[] = vpc.selectSubnets({ subnetGroupName: 'CloudWanAttachment' }).subnets.map(subnet =>
      `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:route-table/${subnet.routeTable.routeTableId}`,
    );

    const publicSubnetArns: string[] = vpc.selectSubnets({ subnetGroupName: 'Public' }).subnets.map(subnet =>
      `arn:aws:ec2:${Stack.of(this).region}:${Stack.of(this).account}:route-table/${subnet.routeTable.routeTableId}`,
    );

    // Permissions for custom lambda function to create and delete routes toward AWS Network Firewall
    routeLambdaRole.addToPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'ec2:CreateRoute',
          'ec2:DeleteRoute',
        ],
        resources: [...cloudWANSubnetsArns, ...publicSubnetArns],
      }),
    );

    const customRouteLambda = new lambdaNodejs.NodejsFunction(this, 'routes', {
      runtime: lambda.Runtime.NODEJS_16_X,
      handler: 'onEvent',
      role: routeLambdaRole,
      timeout: Duration.seconds(20),
    });

    const provider = new cr.Provider(this, 'provider', {
      onEventHandler: customRouteLambda,
      logRetention: logs.RetentionDays.ONE_DAY,
    });
    provider.node.addDependency(customRouteLambda);


    /**
     * Create a default route towards AWS Network firewall endpoints.
     * Select all subnets in group CloudWANAttacment and use custom lambda function to find
     * AWS Network Firewall endpoint that is in same availability zone as subnet.
     */
    vpc.selectSubnets({ subnetGroupName: 'CloudWanAttachment' }).subnets.forEach(subnet => {
      const subnetName = subnet.node.path.split('/').pop(); // E.g. TransitGatewayStack/InspectionVPC/PublicSubnet1
      new CustomResource(this, 'FirewallRoute-' + subnetName, {
        serviceToken: provider.serviceToken,
        properties: {
          FirewallArn: networkFw.attrFirewallArn,
          SubnetAz: subnet.availabilityZone,
          DestinationCidr: '0.0.0.0/0',
          RouteTableId: subnet.routeTable.routeTableId,
        },
      });
    });

    /**
     * Select all subnets in subnet group Public.
     * Create a route towards organisation network through AWS Network Firewall.
     */
    vpc.selectSubnets({ subnetGroupName: 'Public' }).subnets.forEach(subnet => {
      const subnetName = subnet.node.path.split('/').pop(); // E.g. TransitGatewayStack/InspectionVPC/PublicSubnet1
      new CustomResource(this, 'ReturnRoute-' + subnetName, {
        serviceToken: provider.serviceToken,
        properties: {
          FirewallArn: networkFw.attrFirewallArn,
          SubnetAz: subnet.availabilityZone,
          RouteTableId: subnet.routeTable.routeTableId,
          DestinationCidr: props.organisationCidr,
        },
      });
    });

  }
}
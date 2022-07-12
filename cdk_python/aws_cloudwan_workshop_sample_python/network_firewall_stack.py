# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

from aws_cdk import Arn, ArnComponents, CfnTag, Duration, RemovalPolicy, Stack
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_iam as iam
from aws_cdk import aws_lambda
from aws_cdk import aws_lambda_python_alpha as aws_python
from aws_cdk import aws_logs as logs
from aws_cdk import aws_networkfirewall as nf
from aws_cdk import aws_networkmanager as nm
from aws_cdk import custom_resources as cr
from aws_cdk import CustomResource
from constructs import Construct

from .consts import (
    CLOUDWAN_CORE_NETWORK_ID,
    SUBNET_CLOUDWAN_ATTACHMENT,
    SUBNET_NETWORK_FIREWALL,
    SUBNET_PUBLIC,
)
from .firewall_rules import NetworkFirewallRules


class NetworkFirewallStack(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        cidr: str,
        organisation_cidr: str,
        cloudwan_segment: str,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Inspection VPC for AWS Network Firewall
        # Creates three subnet groups that are used for CloudWAN attachments,
        # AWS Network Firewall endpoints and NAT gateways.
        vpc = ec2.Vpc(
            self,
            "InspectionVPC",
            vpc_name="inspection-vpc",
            cidr=cidr,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name=SUBNET_CLOUDWAN_ATTACHMENT,
                    subnet_type=ec2.SubnetType.PRIVATE_ISOLATED,
                    cidr_mask=26,
                ),
                ec2.SubnetConfiguration(
                    name=SUBNET_NETWORK_FIREWALL,
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_NAT,
                    cidr_mask=27,
                ),
                ec2.SubnetConfiguration(
                    name=SUBNET_PUBLIC, subnet_type=ec2.SubnetType.PUBLIC, cidr_mask=27
                ),
            ],
        )

        # When VPC is created in same account as the CloudWAN. We need to get
        # CloudWAN ID from AWS SSM parameters instead of AWS RAM share. AWS RAM
        # doesn't work within same account.
        ssm_sdk_call = cr.AwsSdkCall(
            service="SSM",
            action="getParameter",
            parameters={"Name": CLOUDWAN_CORE_NETWORK_ID},
            region="us-east-1",
            physical_resource_id=cr.PhysicalResourceId.of(f"{vpc.vpc_id}-cloudwan-id"),
        )

        cloud_wan_id = cr.AwsCustomResource(
            self,
            "CloudWanId",
            on_create=ssm_sdk_call,
            on_update=ssm_sdk_call,
            log_retention=logs.RetentionDays.FIVE_DAYS,
            policy=cr.AwsCustomResourcePolicy.from_statements(
                [
                    iam.PolicyStatement(
                        actions=["ssm:GetParameter"],
                        effect=iam.Effect.ALLOW,
                        resources=[
                            Arn.format(
                                ArnComponents(
                                    service="ssm",
                                    region="us-east-1",
                                    resource=f"parameter/{CLOUDWAN_CORE_NETWORK_ID}",
                                ),
                                stack=self,
                            )
                        ],
                    )
                ]
            ),
        )

        # Select all subnets from subnet group named CloudWANAttachment and
        # create ARNs for those.
        # Create CloudWAN attachment to both of those subnets.
        subnet_arns = [
            Arn.format(
                ArnComponents(
                    service="ec2",
                    resource=f"subnet/{subnet.subnet_id}",
                ),
                stack=self,
            )
            for subnet in vpc.select_subnets(
                subnet_group_name=SUBNET_CLOUDWAN_ATTACHMENT
            ).subnets
        ]

        cloud_wan_attachment = nm.CfnVpcAttachment(
            self,
            SUBNET_CLOUDWAN_ATTACHMENT,
            core_network_id=cloud_wan_id.get_response_field("Parameter.Value"),
            subnet_arns=subnet_arns,
            vpc_arn=vpc.vpc_arn,
            tags=[
                CfnTag(key=cloudwan_segment, value="cloudwan-segment"),
                CfnTag(key="Name", value=f"Inspection-{Stack.of(self).region}"),
            ],
        )

        for subnet in vpc.select_subnets(
            subnet_group_name=SUBNET_NETWORK_FIREWALL
        ).subnets:
            add_route_sdk_call = cr.AwsSdkCall(
                service="EC2",
                action="createRoute",
                parameters={
                    "CoreNetworkArn": Arn.format(
                        ArnComponents(
                            service="networkmanager",
                            region="",
                            resource=f"core-network/{cloud_wan_id.get_response_field('Parameter.Value')}",
                        ),
                        stack=self,
                    ),
                    "RouteTableId": subnet.route_table.route_table_id,
                    "DestinationCidrBlock": organisation_cidr,
                },
                physical_resource_id=cr.PhysicalResourceId.of(
                    f"{subnet.route_table.route_table_id}-cloudwan-route"
                ),
            )
            delete_route_sdk_call = cr.AwsSdkCall(
                service="EC2",
                action="deleteRoute",
                parameters={
                    "RouteTableId": subnet.route_table.route_table_id,
                    "DestinationCidrBlock": organisation_cidr,
                },
            )

            cr.AwsCustomResource(
                self,
                f"{subnet.node.id}-route",
                on_create=add_route_sdk_call,
                on_update=add_route_sdk_call,
                on_delete=delete_route_sdk_call,
                log_retention=logs.RetentionDays.FIVE_DAYS,
                policy=cr.AwsCustomResourcePolicy.from_statements(
                    [
                        iam.PolicyStatement(
                            actions=["ec2:CreateRoute", "ec2:DeleteRoute"],
                            effect=iam.Effect.ALLOW,
                            resources=[
                                Arn.format(
                                    ArnComponents(
                                        service="ec2",
                                        region="*",
                                        account="*",
                                        resource=f"route-table/{subnet.route_table.route_table_id}",
                                    ),
                                    stack=self,
                                )
                            ],
                        )
                    ]
                ),
            ).node.add_dependency(cloud_wan_attachment)

        # Create rules for AWS Network Firewall
        # Rule are defined in a separate file
        firewall_rules = NetworkFirewallRules(self, "NetworkFirewallRules")

        subnet_list = [
            nf.CfnFirewall.SubnetMappingProperty(subnet_id=subnet.subnet_id)
            for subnet in vpc.select_subnets(
                subnet_group_name=SUBNET_NETWORK_FIREWALL
            ).subnets
        ]

        network_fw = nf.CfnFirewall(
            self,
            SUBNET_NETWORK_FIREWALL,
            firewall_name="EgressInspectionFirewall",
            firewall_policy_arn=firewall_rules.firewall_policy.attr_firewall_policy_arn,
            subnet_mappings=subnet_list,
            vpc_id=vpc.vpc_id,
        )

        fw_flow_logs_group = logs.LogGroup(
            self,
            "FWFlowLogsGroup",
            log_group_name="NetworkFirewallFlowLogs",
            removal_policy=RemovalPolicy.DESTROY,
        )

        fw_alert_logs_group = logs.LogGroup(
            self,
            "FWAlertLogsGroup",
            log_group_name="NetworkFirewallAlertLogs",
            removal_policy=RemovalPolicy.DESTROY,
        )

        nf.CfnLoggingConfiguration(
            self,
            "FirewallLoggingConfg",
            firewall_arn=network_fw.ref,
            logging_configuration=nf.CfnLoggingConfiguration.LoggingConfigurationProperty(
                log_destination_configs=[
                    nf.CfnLoggingConfiguration.LogDestinationConfigProperty(
                        log_destination={"logGroup": fw_flow_logs_group.log_group_name},
                        log_destination_type="CloudWatchLogs",
                        log_type="FLOW",
                    ),
                    nf.CfnLoggingConfiguration.LogDestinationConfigProperty(
                        log_destination={
                            "logGroup": fw_alert_logs_group.log_group_name
                        },
                        log_destination_type="CloudWatchLogs",
                        log_type="ALERT",
                    ),
                ]
            ),
        )

        # Lambda function and custom action to create and delete routes to
        # Gateway Load Balancer endpoints in correct AZ
        route_lambda_role = iam.Role(
            self,
            "routeLambdaRole",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                )
            ],
        )

        route_lambda_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=["network-firewall:DescribeFirewall"],
                resources=[network_fw.attr_firewall_arn],
            )
        )

        cloud_wan_subnets_arns = [
            Arn.format(
                ArnComponents(
                    service="ec2",
                    resource=f"route-table/{subnet.route_table.route_table_id}",
                ),
                stack=self,
            )
            for subnet in vpc.select_subnets(
                subnet_group_name=SUBNET_CLOUDWAN_ATTACHMENT
            ).subnets
        ]

        public_subnet_arns = [
            Arn.format(
                ArnComponents(
                    service="ec2",
                    resource=f"route-table/{subnet.route_table.route_table_id}",
                ),
                stack=self,
            )
            for subnet in vpc.select_subnets(subnet_group_name=SUBNET_PUBLIC).subnets
        ]

        route_lambda_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=["ec2:CreateRoute", "ec2:DeleteRoute"],
                resources=cloud_wan_subnets_arns + public_subnet_arns,
            )
        )

        custom_route_lambda = aws_python.PythonFunction(
            self,
            "RoutesFunction",
            runtime=aws_lambda.Runtime.PYTHON_3_9,
            handler="on_event",
            role=route_lambda_role,
            timeout=Duration.seconds(20),
            entry="lambda/routes",
        )

        provider = cr.Provider(
            self,
            "provider",
            on_event_handler=custom_route_lambda,
            log_retention=logs.RetentionDays.ONE_DAY,
        )

        # Create a default route towards AWS Network firewall endpoints. Select
        # all subnets in group CloudWANAttacment and use custom lambda function
        # to find AWS Network Firewall endpoint that is in same availability
        # zone as subnet.
        for subnet in vpc.select_subnets(
            subnet_group_name=SUBNET_CLOUDWAN_ATTACHMENT
        ).subnets:
            subnet_name = subnet.node.path.split("/")[-1]
            CustomResource(
                self,
                f"FirewallRoute-{subnet_name}",
                properties={
                    "FirewallArn": network_fw.attr_firewall_arn,
                    "SubnetAz": subnet.availability_zone,
                    "RouteTableId": subnet.route_table.route_table_id,
                    "DestinationCidr": "0.0.0.0/0",
                },
                service_token=provider.service_token,
            )

        for subnet in vpc.select_subnets(
            subnet_group_name=SUBNET_PUBLIC
        ).subnets:
            subnet_name = subnet.node.path.split("/")[-1]
            CustomResource(
                self,
                f"ReturnRoute-{subnet_name}",
                properties={
                    "FirewallArn": network_fw.attr_firewall_arn,
                    "SubnetAz": subnet.availability_zone,
                    "RouteTableId": subnet.route_table.route_table_id,
                    "DestinationCidr": organisation_cidr,
                },
                service_token=provider.service_token,
            )

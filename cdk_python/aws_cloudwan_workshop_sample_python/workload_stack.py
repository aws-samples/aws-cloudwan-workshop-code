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

from aws_cdk import Arn, ArnComponents, CfnTag, Stack
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_iam as iam
from aws_cdk import aws_logs as logs
from aws_cdk import aws_networkmanager as nm
from aws_cdk import custom_resources as cr
from constructs import Construct

from .consts import (
    CLOUDWAN_CORE_NETWORK_ID,
    SUBNET_PRIVATE,
)


class WorkloadStack(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        vpc_name: str,
        vpc_cidr: str,
        segment: str,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        vpc = ec2.Vpc(
            self,
            f"{vpc_name}-{Stack.of(self).region}",
            cidr=vpc_cidr,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name=SUBNET_PRIVATE,
                    subnet_type=ec2.SubnetType.PRIVATE_ISOLATED,
                    cidr_mask=24,
                )
            ],
        )

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

        subnet_arns = [
            Arn.format(
                ArnComponents(service="ec2", resource=f"subnet/{subnet.subnet_id}"),
                stack=self,
            )
            for subnet in vpc.isolated_subnets
        ]

        attachment = nm.CfnVpcAttachment(
            self,
            f"{vpc_name}CloudwanAttachment",
            core_network_id=cloud_wan_id.get_response_field("Parameter.Value"),
            subnet_arns=subnet_arns,
            vpc_arn=vpc.vpc_arn,
            tags=[
                CfnTag(key=segment, value="cloudwan-segment"),
                CfnTag(key="Name", value=f"Workload-{vpc_name}"),
            ],
        )

        for subnet in vpc.select_subnets(subnet_group_name=SUBNET_PRIVATE).subnets:
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
                    "DestinationCidrBlock": "0.0.0.0/0",
                },
                physical_resource_id=cr.PhysicalResourceId.of(
                    subnet.route_table.route_table_id
                ),
            )
            cr.AwsCustomResource(
                self,
                f"{subnet.node.id}-route",
                on_create=add_route_sdk_call,
                on_update=add_route_sdk_call,
                log_retention=logs.RetentionDays.FIVE_DAYS,
                policy=cr.AwsCustomResourcePolicy.from_statements(
                    [
                        iam.PolicyStatement(
                            actions=["ec2:CreateRoute"],
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
            ).node.add_dependency(attachment)

        vpc.add_interface_endpoint(
            "SsmEndpoint", service=ec2.InterfaceVpcEndpointAwsService.SSM
        )
        vpc.add_interface_endpoint(
            "SsmMessagesEndpoint",
            service=ec2.InterfaceVpcEndpointAwsService.SSM_MESSAGES,
        )
        vpc.add_interface_endpoint(
            "Ec2MessagesEndpoint",
            service=ec2.InterfaceVpcEndpointAwsService.EC2_MESSAGES,
        )

        ssm_role = iam.Role(
            self,
            "SSMRole",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AmazonSSMManagedInstanceCore"
                )
            ],
        )

        security_group = ec2.SecurityGroup(
            self, "WorkloadEC2SG", security_group_name="workload-sg", vpc=vpc
        )

        security_group.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.all_icmp())

        ec2.Instance(
            self,
            f"WorkloadEC2-{Stack.of(self).region}",
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PRIVATE_ISOLATED
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO
            ),
            machine_image=ec2.MachineImage.latest_amazon_linux(
                cpu_type=ec2.AmazonLinuxCpuType.ARM_64,
                generation=ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
            ),
            role=ssm_role,
            security_group=security_group,
        )

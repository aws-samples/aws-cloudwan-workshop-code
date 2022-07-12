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

import logging
from typing import Dict

import boto3
from crhelper import CfnResource

logger = logging.getLogger(__name__)
helper = CfnResource()


nfw = boto3.client("network-firewall")
ec2 = boto3.client("ec2")


def get_data(firewall_arn: str) -> Dict[str, str]:
    response = nfw.describe_firewall(FirewallArn=firewall_arn)
    return {
        k: v["Attachment"]["EndpointId"]
        for k, v in response["FirewallStatus"]["SyncStates"].items()
    }


@helper.create
def create(event, context):
    logical_id: str = event["LogicalResourceId"]
    request_id: str = event["RequestId"]
    physical_resource_id = f'{logical_id}-{request_id.replace("-", "")}.txt'
    firewall_arn = event["ResourceProperties"]["FirewallArn"]
    subnet_az = event["ResourceProperties"]["SubnetAz"]
    destination_cidr = event["ResourceProperties"]["DestinationCidr"]
    route_table_id = event["ResourceProperties"]["RouteTableId"]

    endpoints = get_data(firewall_arn)
    ec2.create_route(
        DestinationCidrBlock=destination_cidr,
        RouteTableId=route_table_id,
        VpcEndpointId=endpoints[subnet_az],
    )
    return physical_resource_id


@helper.update
def update(event, context):
    firewall_arn = event["ResourceProperties"]["FirewallArn"]
    helper.Data.update(get_data(firewall_arn))


@helper.delete
def delete(event, context):
    route_table_id = event["ResourceProperties"]["RouteTableId"]
    destination_cidr = event["ResourceProperties"]["DestinationCidr"]
    ec2.delete_route(DestinationCidrBlock=destination_cidr, RouteTableId=route_table_id)


def on_event(event, context):
    helper(event, context)

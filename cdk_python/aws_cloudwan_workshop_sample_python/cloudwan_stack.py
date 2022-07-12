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

import json

from .consts import CLOUDWAN_CORE_NETWORK_ID

from aws_cdk import CfnTag, Stack
from aws_cdk import aws_networkmanager as nm
from aws_cdk import aws_ram as ram
from aws_cdk import aws_ssm as ssm
from constructs import Construct


class CloudWanStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, policy_file: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        with open(policy_file, "r", encoding="utf-8") as file_handle:
            policy_json = json.load(file_handle)

        global_network = nm.CfnGlobalNetwork(
            self,
            "GlobalNet",
            description="Global Net",
            tags=[
                CfnTag(key="Name", value="Global-Net"),
                CfnTag(key="Env", value="Workshop"),
            ],
        )

        core_network = nm.CfnCoreNetwork(
            self,
            "CoreNetwork",
            global_network_id=global_network.attr_id,
            policy_document=policy_json,
            description="Core network",
            tags=[
                CfnTag(key="Name", value="Global-Net"),
                CfnTag(key="Env", value="Workshop"),
            ],
        )

        ssm.StringParameter(
            self,
            "CoreNetworkId",
            string_value=core_network.attr_core_network_id,
            parameter_name=CLOUDWAN_CORE_NETWORK_ID,
        )

        ram.CfnResourceShare(
            self,
            "CoreNetworkShare",
            name="CloudWanCoreNetwork",
            allow_external_principals=False,
            resource_arns=[core_network.attr_core_network_arn],
        )

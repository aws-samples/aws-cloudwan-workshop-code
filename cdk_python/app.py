#!/usr/bin/env python3

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

from pathlib import Path

import aws_cdk as cdk

from aws_cloudwan_workshop_sample_python.cloudwan_stack import CloudWanStack
from aws_cloudwan_workshop_sample_python.network_firewall_stack import (
    NetworkFirewallStack,
)
from aws_cloudwan_workshop_sample_python.workload_stack import WorkloadStack

organisation_cidr = "10.0.0.0/8"
if Path("cloudwan-policy-active.json").exists():
    policy_file = "cloudwan-policy-active.json"
else:
    policy_file = "cloudwan-policy-init.json"

app = cdk.App()


CloudWanStack(
    app, "CloudWAN", env=cdk.Environment(region="us-east-1"), policy_file=policy_file
)

NetworkFirewallStack(
    app,
    "NetworkFirewallUS",
    env=cdk.Environment(region="us-east-1"),
    cidr="10.200.0.0/22",
    organisation_cidr=organisation_cidr,
    cloudwan_segment="sharedservices",
)

NetworkFirewallStack(
    app,
    "NetworkFirewallEU",
    env=cdk.Environment(region="eu-west-1"),
    cidr="10.200.4.0/22",
    organisation_cidr=organisation_cidr,
    cloudwan_segment="sharedservices",
)

WorkloadStack(
    app,
    "WorkloadNonProdEU",
    vpc_cidr="10.1.0.0/16",
    vpc_name="eu-nonprod",
    segment="nonprod",
    env=cdk.Environment(region="eu-west-1"),
)

WorkloadStack(
    app,
    "WorkloadProdUS",
    vpc_cidr="10.0.0.0/16",
    vpc_name="us-prod",
    segment="prod",
    env=cdk.Environment(region="us-east-1"),
)

WorkloadStack(
    app,
    "WorkloadProdUS2",
    vpc_cidr="10.2.0.0/16",
    vpc_name="us-prod-2",
    segment="prod",
    env=cdk.Environment(region="us-east-1"),
)

app.synth()

import json
import sys
import textwrap
from pathlib import Path
from typing import List

import boto3


def network_filter(core_network: dict) -> bool:
    return any(
        True
        for tag in core_network["Tags"]
        if tag["Key"] == "Env" and tag["Value"] == "Workshop"
    )


active_policy_file = Path("cloudwan-policy-active.json")

if active_policy_file.exists():
    print(
        textwrap.dedent(
            f"""
            CloudWAN active policy file {active_policy_file} already exists.
            This script is meant to be used for the initial deploy only.
            If you are redeploying, delete the above file.
            """
        )
    )
    sys.exit(1)

nm = boto3.client("networkmanager", region_name="us-east-1")

print("--> Finding core network")
network_response = nm.list_core_networks()
network = list(filter(network_filter, network_response["CoreNetworks"]))
if len(network) != 1:
    raise RuntimeError(f"Wanted 1 core network with correct tags, got {len(network)}")
core_network_id = network[0]["CoreNetworkId"]
print(f"    {core_network_id}")
print()

print("--> Finding attachment ids...")
attachment_response = nm.list_attachments(CoreNetworkId=core_network_id)
attachment_ids: List[str] = [
    x["AttachmentId"]
    for x in attachment_response["Attachments"]
    if x["SegmentName"] == "sharedservices" and x["State"] == "AVAILABLE"
]
if len(attachment_ids) == 0:
    raise RuntimeError("No CloudWAN attachments for inspection VPC available")
print(f"    {','.join(attachment_ids)}")
print()

print("--> Fetching current policy document...")
policy_response = nm.get_core_network_policy(CoreNetworkId=core_network_id)
policy_document = policy_response["CoreNetworkPolicy"]["PolicyDocument"]
policy = json.loads(policy_document)
print("    ok")
print()

if "segment-actions" not in policy:
    policy["segment-actions"] = []

for segment in ["prod", "nonprod"]:
    policy["segment-actions"].append(
        {
            "action": "create-route",
            "destination-cidr-blocks": ["0.0.0.0/0"],
            "segment": segment,
            "destinations": attachment_ids,
        }
    )

active_policy_file.write_text(json.dumps(policy), encoding="utf-8")

print(f"==> Successfully updated {active_policy_file}")

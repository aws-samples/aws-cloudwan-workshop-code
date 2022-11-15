# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

output "vpcs" {
  description = "VPCs created."
  value = {
    n_virginia = {
      spoke      = { for k, v in module.nvirginia_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.nvirginia_inspection_vpc.vpc_attributes.id
    }
    ireland = {
      spoke      = { for k, v in module.ireland_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.ireland_inspection_vpc.vpc_attributes.id
    }
  }
}

output "cloud_wan" {
  description = "AWS Cloud WAN resources."
  value = {
    core_network_id = awscc_networkmanager_core_network.core_network.core_network_id
    attachments = {
      n_virginia = {
        spoke      = { for k, v in module.nvirginia_spoke_vpcs : k => v.core_network_attachment.id }
        inspection = module.nvirginia_inspection_vpc.core_network_attachment.id
      }
      ireland = {
        spoke      = { for k, v in module.ireland_spoke_vpcs : k => v.core_network_attachment.id }
        inspection = module.ireland_inspection_vpc.core_network_attachment.id
      }
    }
  }
}

output "ec2_instances" {
  description = "List of EC2 instances created."
  value = {
    n_virginia = { for k, v in module.compute_nvirginia : k => v.ec2_instances.*.id }
    ireland    = { for k, v in module.compute_ireland : k => v.ec2_instances.*.id }
  }
}

output "vpc_endpoints" {
  description = "VPC endpoints created."
  value = {
    n_virginia = { for k, v in module.vpc_endpoints_nvirginia : k => v.endpoint_ids }
    ireland    = { for k, v in module.vpc_endpoints_ireland : k => v.endpoint_ids }
  }
}
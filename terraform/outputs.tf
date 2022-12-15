# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

output "vpcs" {
  description = "VPCs created."
  value = {
    oregon = {
      spoke      = { for k, v in module.oregon_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.oregon_inspection_vpc.vpc_attributes.id
      legacy     = module.oregon_legacy_vpc.vpc_attributes.id
    }
    stockholm = {
      spoke      = { for k, v in module.stockholm_spoke_vpcs : k => v.vpc_attributes.id }
      inspection = module.stockholm_inspection_vpc.vpc_attributes.id
      legacy     = module.stockholm_legacy_vpc.vpc_attributes.id
    }
  }
}

output "cloud_wan" {
  description = "AWS Cloud WAN resources."
  value = {
    global_network_id = aws_networkmanager_global_network.global_network.id
    core_network_id   = awscc_networkmanager_core_network.core_network.core_network_id
    attachments = {
      oregon = {
        # spoke      = { for k, v in module.oregon_spoke_vpcs : k => v.core_network_attachment.id }
        inspection = module.oregon_inspection_vpc.core_network_attachment.id
        # tgw_rt     = aws_networkmanager_transit_gateway_route_table_attachment.oregon_cwan_tgw_rt_attachment.id
      }
      stockholm = {
        # spoke      = { for k, v in module.stockholm_spoke_vpcs : k => v.core_network_attachment.id }
        inspection = module.stockholm_inspection_vpc.core_network_attachment.id
        # tgw_rt     = aws_networkmanager_transit_gateway_route_table_attachment.stockholm_cwan_tgw_rt_attachment.id
      }
    }
  }
}

output "transit_gateway" {
  description = "AWS Transit Gateway resources."
  value = {
    oregon    = aws_ec2_transit_gateway.oregon_tgw.id
    stockholm = aws_ec2_transit_gateway.stockholm_tgw.id
  }
}
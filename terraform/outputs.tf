# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# output "vpcs" {
#   description = "VPCs created."
#   value = {
#     n_virginia = {
#       spoke      = { for k, v in module.nvirginia_spoke_vpcs : k => v.vpc_attributes.id }
#       inspection = module.nvirginia_inspection_vpc.vpc_attributes.id
#     }
#     ireland = {
#       spoke      = { for k, v in module.ireland_spoke_vpcs : k => v.vpc_attributes.id }
#       inspection = module.ireland_inspection_vpc.vpc_attributes.id
#     }
#   }
# }

# output "cloud_wan" {
#   description = "AWS Cloud WAN resources."
#   value = {
#     core_network_id = module.cloudwan.core_network.id
#     attachments = {
#       n_virginia = { 
#         spoke = { for k, v in module.nvirginia_spoke_cwattachments: k => v.cloudwan_attachment.id }
#         inspection = module.nvirginia_inspection_cwattachment.cloudwan_attachment.id
#       }
#       ireland = { 
#         spoke = { for k, v in module.ireland_spoke_cwattachments: k => v.cloudwan_attachment.id }
#         inspection = module.ireland_inspection_cwattachment.cloudwan_attachment.id
#       }
#     }
#   }
# }

# output "core_nw_attachments_egress_singapore" {
#   value = module.cwan_components_singapore.core_nw_attachments_egress_singapore
# }
# output "core_nw_attachments_egress_sydney" {
#   value = module.cwan_components_sydney.core_nw_attachments_egress_sydney
# }
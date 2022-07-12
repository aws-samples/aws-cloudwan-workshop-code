# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

output "core_nw_attachments_egress_singapore" {
  value = module.cwan_components_singapore.core_nw_attachments_egress_singapore
}
output "core_nw_attachments_egress_sydney" {
  value = module.cwan_components_sydney.core_nw_attachments_egress_sydney
}
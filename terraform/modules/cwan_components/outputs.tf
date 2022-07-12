# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/outputs.tf ---

output "security_groups_info" {
  description = "Security Group IDs created for the workshop"
  value       = aws_security_group.cwan_sg.*.id
}

output "vpcendpoints" {
  description = "List of VPC Endpoints created by the Network Firewall"
  value       = [for ep in tolist(aws_networkfirewall_firewall.egress_vpc_fw.firewall_status[0].sync_states) : ep.attachment[0].endpoint_id]
}

output "public_subnets" {
  description = "Public subnets ids of Egress VPC"
  value       = aws_subnet.egress_vpc_public_subnet[*].id
}

output "private_route_ids_core_nw" {
  description = "Private Route Table IDs created for Core Network"
  value       = local.private_route_ids_core_nw
}

output "core_nw_attachments_egress_singapore" {
  value = var.deploy_global_resources ? awscc_networkmanager_vpc_attachment.corenw_attachments["egress-private"].attachment_id : ""
}
output "core_nw_attachments_egress_sydney" {
  value = var.deploy_global_resources ? "" : awscc_networkmanager_vpc_attachment.corenw_attachments["egress-private"].attachment_id
}
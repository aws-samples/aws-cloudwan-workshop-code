# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/core_nw_attachments.tf ---

resource "awscc_networkmanager_vpc_attachment" "corenw_attachments" {
  #Create VPC attachments for all VPCs created & ensure all Private Subnets are selected when creating attachments

  core_network_id = var.core_network_id

  for_each = var.core_nw_attachments

  vpc_arn     = each.value.vpc_id
  subnet_arns = each.value.subnet_ids

  options = {
    ipv_6_support = var.corenw_attachments_ipv6_support
  }

  tags = each.value.tags
}

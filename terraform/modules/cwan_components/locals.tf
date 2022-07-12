# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/locals.tf ---

# CloudWAN policy
locals {
  private_route_ids_core_nw = flatten([
    for rtb in var.core_nw_attachments : [
      for r in rtb.private_route_tbl_ids : {
        rtb_id      = r
        destination = rtb.private_routes_destination
      }
    ]
  ])

  nat_gateway_ips = try(aws_eip.nat[*].id, [])
}
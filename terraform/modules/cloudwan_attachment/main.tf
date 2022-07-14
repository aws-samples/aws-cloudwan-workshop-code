# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cloudwan_attachment/main.tf ---

# Local values
locals {
    private_subnets = { for k, v in var.vpc_info.private_subnet_attributes_by_az : k => v.id }
    private_route_tables = { for k, v in var.vpc_info.route_table_attributes_by_type_by_az.private : k => v.id }
}

# Cloud WAN VPC attachment 
resource "awscc_networkmanager_vpc_attachment" "corenw_attachment" {
  core_network_id = var.core_network_id

  vpc_arn     = var.vpc_info.vpc_attributes.id
  subnet_arns = values(local.private_subnets)

  options = {
    ipv_6_support = "enable"
  }

  tags = {
      Name = "${each.key}-cloudwan-attachment"
  }
}

# Route from the private subnets to the Core Network
resource "aws_route" "private_to_core_network" {
    count = length(local.private_subnets)

    route_table_id = values(local.private_route_tables)[count.index]
    destination_cidr_block = var.route_to_cloudwan
    core_network_arn = var.core_network_arn

    depends_on = [
        awscc_networkmanager_vpc_attachment.corenw_attachment
    ]
}
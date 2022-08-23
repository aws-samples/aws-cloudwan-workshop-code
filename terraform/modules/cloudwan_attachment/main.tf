# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cloudwan_attachment/main.tf ---

# Cloud WAN VPC attachment 
resource "aws_networkmanager_vpc_attachment" "cwan_attachment" {
  core_network_id = var.core_network_id

  vpc_arn     = var.vpc_arn
  subnet_arns = var.cloudwan_subnets

  options {
    ipv6_support = false
  }

  tags = {
    Name = "${var.vpc_name}-cloudwan-attachment"
    env  = var.environment
  }
}

# Route from the private subnets to the Core Network
resource "aws_route" "private_to_core_network" {
  count = var.number_azs

  route_table_id         = var.route_tables[count.index]
  destination_cidr_block = var.route_to_cloudwan
  core_network_arn       = var.core_network_arn

  depends_on = [
    aws_networkmanager_vpc_attachment.cwan_attachment,
    aws_networkmanager_attachment_accepter.cwan_attachment_acceptance
  ]
}

# Local variable to check if VPC attachment acceptance is needed
locals {
  acceptance_needed = var.environment == "prod" ? true : false
}

# Attachment acceptance (only for attachments going to prod)
resource "aws_networkmanager_attachment_accepter" "cwan_attachment_acceptance" {
  count = var.attachment_accepted && local.acceptance_needed ? 1 : 0

  attachment_id   = aws_networkmanager_vpc_attachment.cwan_attachment.id
  attachment_type = "VPC"
}


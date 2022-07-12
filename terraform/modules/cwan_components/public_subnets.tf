# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/public_subnets.tf ---

#Creating Public Subnets outside of VPC module 
#This is to avoid default Public route table and Subnet associations

resource "aws_subnet" "egress_vpc_public_subnet" {
  count = length(var.public_subnets_info)

  vpc_id                  = var.network_firewall_vpc
  cidr_block              = var.public_subnets_info[count.index]["cidr_block"]
  availability_zone       = var.public_subnets_info[count.index]["availability_zone"]
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-%s", "egress-vpc-public", var.public_subnets_info[count.index]["availability_zone"])
  }
}
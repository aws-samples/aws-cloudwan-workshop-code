# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/igw_nat.tf ---

#Creating Internet Gateway outside of VPC module 
#This is to avoid it getting attached with Public Subnets by default

resource "aws_internet_gateway" "egress_igw" {
  vpc_id = var.network_firewall_vpc
  tags = {
    Name = "egress-igw-cloudwan-workshop"
  }
}

#Creating NAT Gateway outside of VPC module 
#This is because Public Subnets and Internet Gateway are created outside of VPC module as well

resource "aws_eip" "nat" {
  count = length(var.public_subnets_info)

  vpc = true

  tags = {
    Name = format("%s-%s", "egress-vpc-nat-gw-eip", count.index)
  }
}

resource "aws_nat_gateway" "egress_vpc_nat" {
  count = length(var.public_subnets_info)

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = aws_subnet.egress_vpc_public_subnet[count.index].id

  tags = {
    Name = format("%s-%s", "egress-vpc-nat-gw", count.index)
  }

  depends_on = [aws_internet_gateway.egress_igw]
}
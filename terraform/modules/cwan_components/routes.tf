# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/routes.tf ---

resource "aws_route_table" "public_route_table" {
  #Create route tables for Public Subnets
  count  = length(var.public_subnets_info)
  vpc_id = var.network_firewall_vpc
  tags = {
    Name = format("%s-%s", "egress-vpc-cloudwan-workshop-public", count.index)
  }
}

resource "aws_route" "public_route_table_routes" {
  #Create default route to corresponding Firewall Endpoint Id for the public subnets
  count = length(var.public_subnets_info)

  route_table_id         = aws_route_table.public_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = element([for ep in tolist(aws_networkfirewall_firewall.egress_vpc_fw.firewall_status[0].sync_states) : ep.attachment[0].endpoint_id if ep.attachment[0].subnet_id == aws_subnet.firewall_subnets[count.index].id], 0)

  depends_on = [aws_route_table.ingress_route_table]
}

resource "aws_route_table_association" "public_route_table_association" {
  #Create route table associations between public route tables and Egress VPC public subnets
  count = length(var.public_subnets_info)

  route_table_id = aws_route_table.public_route_table[count.index].id
  subnet_id      = aws_subnet.egress_vpc_public_subnet[count.index].id
  depends_on     = [aws_subnet.egress_vpc_public_subnet]
}

resource "aws_route_table" "firewall_subnet_route_table" {
  #Create route tables fir Firewall subnets with default route to Internet Gateway

  count = length(var.firewall_subnets)

  vpc_id = var.firewall_subnets[count.index]["vpc_id"]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.egress_igw.id
  }
  tags = {
    Name = format("%s-%s", "firewall-subnet-rtb", count.index)
  }
  depends_on = [
    aws_internet_gateway.egress_igw
  ]
}

resource "aws_route_table_association" "inspection_vpc_public_subnet_route_table_association" {
  #Create route table associations between firewall subnet route tables and Firewall subnets

  count = length(var.firewall_subnets)

  route_table_id = aws_route_table.firewall_subnet_route_table[count.index].id
  subnet_id      = aws_subnet.firewall_subnets[count.index].id
}

resource "aws_route_table" "ingress_route_table" {
  #Create an ingress route table for Firewall VPC
  vpc_id = var.network_firewall_vpc

  tags = {
    Name = "ingress-rtb"
  }
}

resource "aws_route_table_association" "ingress_route_table_gw_association" {
  #Associate Firewall VPC Ingress route table with Internet Gateway
  gateway_id     = aws_internet_gateway.egress_igw.id
  route_table_id = aws_route_table.ingress_route_table.id
  depends_on = [
    aws_internet_gateway.egress_igw
  ]
}

resource "aws_route" "ingress_routes" {
  #Create routes on Ingress ROute table with Egress VPC Public subnets and corresponding Firewall Endpoint Id
  count = length(var.public_subnets_info)

  route_table_id         = aws_route_table.ingress_route_table.id
  destination_cidr_block = aws_subnet.egress_vpc_public_subnet[count.index].cidr_block
  vpc_endpoint_id        = element([for ep in tolist(aws_networkfirewall_firewall.egress_vpc_fw.firewall_status[0].sync_states) : ep.attachment[0].endpoint_id if ep.attachment[0].subnet_id == aws_subnet.firewall_subnets[count.index].id], 0)

  depends_on = [aws_route_table.ingress_route_table]
}

resource "aws_route" "private_subnets_nat_gateway" {
  #Create NAT gateway destination routes for Private Subnets
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.egress_vpc_nat[*].id, count.index)
  depends_on = [
    aws_nat_gateway.egress_vpc_nat
  ]
}

resource "aws_route" "private_subnets_core_network" {
  #Create Core Network target for Private Route tables
  count = length(local.private_route_ids_core_nw)

  route_table_id         = local.private_route_ids_core_nw[count.index].rtb_id
  destination_cidr_block = local.private_route_ids_core_nw[count.index].destination
  core_network_arn       = var.core_network_arn
  depends_on = [
    awscc_networkmanager_vpc_attachment.corenw_attachments
  ]
}


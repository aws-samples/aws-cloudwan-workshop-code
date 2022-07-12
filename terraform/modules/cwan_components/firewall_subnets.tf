# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/firewall_subnets.tf ---

resource "aws_subnet" "firewall_subnets" {
  # Firewall Subnets for firewall endpoints
  count = length(var.firewall_subnets)

  vpc_id                  = var.firewall_subnets[count.index]["vpc_id"]
  cidr_block              = var.firewall_subnets[count.index]["cidr_block"]
  availability_zone       = var.firewall_subnets[count.index]["availability_zone"]
  map_public_ip_on_launch = var.firewall_subnets[count.index]["map_public_ip_on_launch"]

  tags = {
    Name = format("%s-%s", var.firewall_subnets[count.index]["name"], var.firewall_subnets[count.index]["availability_zone"])
  }
}
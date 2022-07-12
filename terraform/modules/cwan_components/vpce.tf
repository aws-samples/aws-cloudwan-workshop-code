# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/vpce.tf ---

resource "aws_vpc_endpoint" "ssm" {
  #SSM VPC Endpoint resource for Private Subnets
  count = length(var.vpc_endpoints_ssm)

  vpc_id              = var.vpc_endpoints_ssm[count.index]["vpc_id"]
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = var.vpc_endpoints_ssm[count.index]["security_group_ids"]
  private_dns_enabled = true
  subnet_ids          = var.vpc_endpoints_ssm[count.index]["subnet_ids"]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  #SSM Messages VPC Endpoint resource for Private Subnets
  count = length(var.vpc_endpoints_ssmmessages)

  vpc_id              = var.vpc_endpoints_ssmmessages[count.index]["vpc_id"]
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = var.vpc_endpoints_ssmmessages[count.index]["security_group_ids"]
  private_dns_enabled = true
  subnet_ids          = var.vpc_endpoints_ssmmessages[count.index]["subnet_ids"]
}

resource "aws_vpc_endpoint" "ec2messages" {
  #EC2 Messages VPC Endpoint resource for Private Subnets
  count = length(var.vpc_endpoints_ec2messages)

  vpc_id              = var.vpc_endpoints_ec2messages[count.index]["vpc_id"]
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = var.vpc_endpoints_ec2messages[count.index]["security_group_ids"]
  private_dns_enabled = true
  subnet_ids          = var.vpc_endpoints_ec2messages[count.index]["subnet_ids"]
}
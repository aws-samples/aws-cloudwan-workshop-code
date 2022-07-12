# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/security_groups.tf ---

resource "aws_security_group" "cwan_sg" {
  #Create Seurity groups for various ports/protocols depending on input configuration
  count = length(var.security_groups_info)

  name        = var.security_groups_info[count.index]["name"]
  description = var.security_groups_info[count.index]["description"]
  vpc_id      = var.security_groups_info[count.index]["vpc_id"]

  ingress {
    description = "Allow Ingress connection"
    from_port   = var.security_groups_info[count.index]["from_port"]
    to_port     = var.security_groups_info[count.index]["to_port"]
    protocol    = var.security_groups_info[count.index]["protocol"]
    cidr_blocks = var.security_groups_info[count.index]["cidr_blocks"]
  }

  egress {
    description = "Allow outbound HTTPS to VPC"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
  }
}
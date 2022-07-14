# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cloudwan_attachment/variables.tf ---

variable "core_network_id" {
    type = string
    description = "Core Network ID."
}

variable "core_network_arn" {
    type =  string
    description = "Core Network ARN."
}

variable "vpc_name" {
    type = string
    description = "VPC name."
}

variable "vpc_info" {
    type = any
    description = "VPC Information."
}

variable "route_to_cloudwan" {
    type = string
    description = "CIDR block destination to route via Cloud WAN."
}
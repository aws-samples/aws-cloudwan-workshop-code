# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/variables.tf ---

variable "aws_region" {
  description = "AWS region for the module"
  type        = string
}
variable "deployment_region" {
  description = "Deployment region name"
  type        = string
}
variable "ec2_instance_type" {
  description = "EC2 instance type for test instances"
  type        = string
}
variable "security_groups_info" {
  description = "Security Group IDs to be attached to instances"
  type        = any
}
variable "vpc_endpoints_ssm" {
  description = "Details related to VPC Endpoints for ssm"
  type        = any
}
variable "vpc_endpoints_ssmmessages" {
  description = "Details related to VPC Endpoints for ssmmessages"
  type        = any
}
variable "vpc_endpoints_ec2messages" {
  description = "Details related to VPC Endpoints for ec2messages"
  type        = any
}
variable "ec2_instances" {
  description = "EC2 instances to be created for testing"
  type        = any
}
variable "firewall_subnets" {
  description = "Egress Firewall VPC subnets information"
  type        = any
}
variable "network_firewall_vpc" {
  description = "Network Firewall VPC information"
}
variable "deploy_global_resources" {
  description = "Bool flag to determine if Global resources like IAM, Global/Core Networks need to be created"
  type        = bool
}
variable "public_subnets_info" {
  description = "Public Subnets details to be created"
  type        = any
}
variable "single_nat_gateway" {
  description = "Disable Single NAT Gateway setting"
  type        = bool
  default     = false
}
variable "nat_gateway_destination_cidr_block" {
  description = "CIDR block for NAT Gateway destination"
  type        = string
  default     = "0.0.0.0/0"
}
variable "private_route_table_ids" {
  description = "Private route table IDs of various VPCs"
  type        = any
}
variable "core_nw_attachments" {
  description = "Core Network Attachments list"
  type        = any
}
variable "core_network_id" {
  description = "Core Network ID"
  type        = any
}
variable "core_network_arn" {
  description = "Core Network ARN value"
  type        = any
}
variable "corenw_attachments_ipv6_support" {
  description = "Disable IPv6 support for Core Network attachments"
  type        = bool
  default     = false
}
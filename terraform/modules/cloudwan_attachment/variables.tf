# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cloudwan_attachment/variables.tf ---

variable "core_network_id" {
  type        = string
  description = "Core Network ID."
}

variable "core_network_arn" {
  type        = string
  description = "Core Network ARN."
}

variable "vpc_name" {
  type        = string
  description = "VPC name."
}

variable "environment" {
  type        = string
  description = "Environment (for segment association)."
}

variable "vpc_arn" {
  type        = string
  description = "VPC ARN."
}

variable "cloudwan_subnets" {
  type        = list(string)
  description = "List of Cloud WAN subnet IDs, to place the attachment ENIs."
}

variable "route_tables" {
  type        = list(string)
  description = "List of Route Tables IDs (either from private or inspection subnets), to add a route to the CloudWAN attachment."
}

variable "number_azs" {
  type        = number
  description = "Number of AZs used by the VPC."
}

variable "route_to_cloudwan" {
  type        = string
  description = "CIDR block destination to route via Cloud WAN."
}

variable "attachment_accepted" {
  type        = bool
  description = "Indicates if the Cloud WAN attachment is accepted (only for segments that require acceptance)."
}
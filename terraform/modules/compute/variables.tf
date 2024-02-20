# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/compute/variables.tf ---

variable "project_name" {
  type        = string
  description = "Project identifier."
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC where the EC2 instance(s) are created."
}

variable "vpc_information" {
  type        = any
  description = "VPC information."
}

variable "number_azs" {
  type        = number
  description = "Number of AZs to place instances."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
}

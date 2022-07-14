# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Project identifier
variable "project_identifier" {
  type        = string
  description = "Project Identifier."

  default = "CloudWAN_Workshop"
}

# AWS Regions to use in this example
variable "aws_regions" {
  type        = map(string)
  description = "AWS regions to spin up resources."

  default = {
    north_virginia = "us-east-1"
    ireland        = "eu-west-1"
  }
}

# Definition of the VPCs to create in N. Virginia Region
variable "nvirginia_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-east-1."

  default = {
    "non-prod" = {
      type                 = "nonprod"
      name                 = "non-prod-us-east-1"
      number_azs           = 2
      cidr_block           = "10.11.0.0/16"
      private_subnet_cidrs = ["10.11.0.0/24", "10.11.2.0/24"]
      instance_type        = "t3.nano"
    }
    "prod" = {
      type                 = "prod"
      name                 = "prod-us-east-1"
      number_azs           = 2
      cidr_block           = "10.10.0.0/16"
      private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
      instance_type        = "t3.nano"
    }
  }
}

variable "nvirginia_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in us-east-1."

  default = {
    name                    = "inspection-us-east-1"
    cidr_block              = "100.64.0.0/16"
    number_azs              = 2
    public_subnet_cidrs     = ["100.64.1.0/24", "100.64.3.0/24"]
    inspection_subnet_cidrs = ["100.64.0.0/24", "100.64.2.0/24"]
  }
}

# Definition of the VPCs to create in Ireland Region
variable "ireland_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-west-1."

  default = {
    "non-prod" = {
      type                 = "nonprod"
      name                 = "non-prod-eu-west-1"
      number_azs           = 2
      cidr_block           = "10.1.0.0/16"
      private_subnet_cidrs = ["10.1.0.0/24", "10.1.2.0/24"]
      instance_type        = "t3.nano"
    }
    "prod" = {
      type                 = "prod"
      name                 = "prod-eu-west-1"
      number_azs           = 2
      cidr_block           = "10.0.0.0/16"
      private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
      instance_type        = "t3.nano"
    }
  }
}

variable "ireland_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in eu-west-1."

  default = {
    name                    = "inspection-eu-west-1"
    cidr_block              = "100.64.0.0/16"
    number_azs              = 2
    public_subnet_cidrs     = ["100.64.1.0/24", "100.64.3.0/24"]
    inspection_subnet_cidrs = ["100.64.0.0/24", "100.64.2.0/24"]
  }
}
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
      type                  = "nonprod"
      name                  = "non-prod-us-east-1"
      number_azs            = 2
      cidr_block            = "10.10.0.0/24"
      endpoint_subnet_cidrs = ["10.10.0.0/28", "10.10.0.16/28"]
      private_subnet_cidrs  = ["10.10.0.32/28", "10.10.0.48/28"]
      cwan_subnet_cidrs     = ["10.10.0.64/28", "10.10.0.80/28"]
      instance_type         = "t2.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "prod-us-east-1"
      number_azs            = 2
      cidr_block            = "10.0.0.0/24"
      endpoint_subnet_cidrs = ["10.0.0.0/28", "10.0.0.16/28"]
      private_subnet_cidrs  = ["10.0.0.32/28", "10.0.0.48/28"]
      cwan_subnet_cidrs     = ["10.0.0.64/28", "10.0.0.80/28"]
      instance_type         = "t2.micro"
    }
  }
}

variable "nvirginia_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in us-east-1."

  default = {
    name                    = "inspection-us-east-1"
    cidr_block              = "100.64.0.0/24"
    number_azs              = 2
    public_subnet_cidrs     = ["100.64.0.0/28", "100.64.0.16/28"]
    inspection_subnet_cidrs = ["100.64.0.32/28", "100.64.0.48/28"]
    cwan_subnet_cidrs       = ["100.64.0.64/28", "100.64.0.80/28"]
  }
}

# Definition of the VPCs to create in Ireland Region
variable "ireland_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-west-1."

  default = {
    "non-prod" = {
      type                  = "nonprod"
      name                  = "non-prod-eu-west-1"
      number_azs            = 2
      cidr_block            = "10.11.0.0/24"
      endpoint_subnet_cidrs = ["10.11.0.0/28", "10.11.0.16/28"]
      private_subnet_cidrs  = ["10.11.0.32/28", "10.11.0.48/28"]
      cwan_subnet_cidrs     = ["10.11.0.64/28", "10.11.0.80/28"]
      instance_type         = "t2.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "prod-eu-west-1"
      number_azs            = 2
      cidr_block            = "10.1.0.0/24"
      endpoint_subnet_cidrs = ["10.1.0.0/28", "10.1.0.16/28"]
      private_subnet_cidrs  = ["10.1.0.32/28", "10.1.0.48/28"]
      cwan_subnet_cidrs     = ["10.1.0.64/28", "10.1.0.80/28"]
      instance_type         = "t2.micro"
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
    public_subnet_cidrs     = ["100.64.0.0/28", "100.64.0.16/28"]
    inspection_subnet_cidrs = ["100.64.0.32/28", "100.64.0.48/28"]
    cwan_subnet_cidrs       = ["100.64.0.64/28", "100.64.0.80/28"]
  }
}
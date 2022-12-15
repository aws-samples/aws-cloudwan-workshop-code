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
    oregon    = "us-west-2"
    stockholm = "eu-north-1"
  }
}

# Transit Gateway ASNs
variable "transit_gateway_asn" {
  type        = map(number)
  description = "Transit Gateway ASNs."

  default = {
    oregon    = 64515
    stockholm = 64516
  }
}

# Definition of the VPCs to create in Oregon Region
variable "oregon_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-west-2."

  default = {
    "non-prod" = {
      type                  = "nonprod"
      name                  = "non-prod-us-west-2"
      number_azs            = 2
      cidr_block            = "10.1.0.0/16"
      workload_subnet_cidrs = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
      endpoint_subnet_cidrs = ["10.1.3.0/28", "10.1.3.16/28", "10.1.3.32/28"]
      cnetwork_subnet_cidrs = ["10.1.3.48/28", "10.1.3.64/28", "10.1.3.80/28"]
      instance_type         = "t3.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "prod-us-west-2"
      number_azs            = 2
      cidr_block            = "10.0.0.0/16"
      workload_subnet_cidrs = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
      endpoint_subnet_cidrs = ["10.0.3.0/28", "10.0.3.16/28", "10.0.3.32/28"]
      cnetwork_subnet_cidrs = ["10.0.3.48/28", "10.0.3.64/28", "10.0.3.80/28"]
      instance_type         = "t3.micro"
    }
  }
}

variable "oregon_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in us-west-2."

  default = {
    name                    = "inspection-us-west-2"
    cidr_block              = "100.64.0.0/16"
    public_subnet_cidrs     = ["100.64.0.0/28", "100.64.0.16/28", "100.64.0.32/28"]
    inspection_subnet_cidrs = ["100.64.0.48/28", "100.64.0.64/28", "100.64.0.80/28"]
    cnetwork_subnet_cidrs   = ["100.64.0.96/28", "100.64.0.112/28", "100.64.0.128/28"]
    number_azs              = 2
  }
}

variable "oregon_legacy_vpc" {
  type        = any
  description = "Information about the Legacy VPC to create in us-west-2."

  default = {
    name                  = "legacy-us-west-2"
    cidr_block            = "10.2.0.0/16"
    workload_subnet_cidrs = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
    endpoint_subnet_cidrs = ["10.2.3.0/28", "10.2.3.16/28", "10.2.3.32/28"]
    tgw_subnet_cidrs      = ["10.2.3.48/28", "10.2.3.64/28", "10.2.3.80/28"]
    number_azs            = 2
    instance_type         = "t3.micro"
  }
}

# Definition of the VPCs to create in Stockholm Region
variable "stockholm_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-north-1."

  default = {
    "non-prod" = {
      type                  = "nonprod"
      name                  = "non-prod-eu-north-1"
      number_azs            = 2
      cidr_block            = "10.11.0.0/16"
      workload_subnet_cidrs = ["10.11.0.0/24", "10.11.1.0/24", "10.11.2.0/24"]
      endpoint_subnet_cidrs = ["10.11.3.0/28", "10.11.3.16/28", "10.11.3.32/28"]
      cnetwork_subnet_cidrs = ["10.11.3.48/28", "10.11.3.64/28", "10.11.3.80/28"]
      instance_type         = "t3.micro"
    }
    "prod" = {
      type                  = "prod"
      name                  = "prod-eu-north-1"
      number_azs            = 2
      cidr_block            = "10.10.0.0/16"
      workload_subnet_cidrs = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
      endpoint_subnet_cidrs = ["10.10.3.0/28", "10.10.3.16/28", "10.10.3.32/28"]
      cnetwork_subnet_cidrs = ["10.10.3.48/28", "10.10.3.64/28", "10.10.3.80/28"]
      instance_type         = "t3.micro"
    }
  }
}

variable "stockholm_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in eu-north-1."

  default = {
    name                    = "inspection-eu-north-1"
    cidr_block              = "100.64.0.0/16"
    public_subnet_cidrs     = ["100.64.0.0/28", "100.64.0.16/28", "100.64.0.32/28"]
    inspection_subnet_cidrs = ["100.64.0.48/28", "100.64.0.64/28", "100.64.0.80/28"]
    cnetwork_subnet_cidrs   = ["100.64.0.96/28", "100.64.0.112/28", "100.64.0.128/28"]
    number_azs              = 2
  }
}

variable "stockholm_legacy_vpc" {
  type        = any
  description = "Information about the Legacy VPC to create in us-west-2."

  default = {
    name                  = "legacy-us-west-2"
    cidr_block            = "10.12.0.0/16"
    workload_subnet_cidrs = ["10.12.0.0/24", "10.12.1.0/24", "10.12.2.0/24"]
    endpoint_subnet_cidrs = ["10.12.3.0/28", "10.12.3.16/28", "10.12.3.32/28"]
    tgw_subnet_cidrs      = ["10.12.3.48/28", "10.12.3.64/28", "10.12.3.80/28"]
    number_azs            = 2
    instance_type         = "t3.micro"
  }
}
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

variable "project" {
  type        = string
  description = "Project Name"

  default     = "CloudWAN_Workshop"
}

variable "singapore_vpcs" {
  type        = any
  description = "VPCs information that will be deployed in ap-southeast-1 region"
  default = {
    "nonprod-vpc" = {
      type            = "non-prod"
      name            = "nonprod-vpc"
      cidr_block      = "10.11.0.0/16"
      private_subnets = ["10.11.0.0/24", "10.11.2.0/24"]
    }
    "prod-vpc" = {
      type            = "prod"
      name            = "prod-vpc"
      cidr_block      = "10.10.0.0/16"
      private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
    }
    "egress-vpc" = {
      type            = "prod"
      name            = "egress-vpc"
      cidr_block      = "100.64.0.0/16"
      private_subnets = ["100.64.0.0/24", "100.64.2.0/24"]
    }
  }
}
variable "singapore_public_subnets_info" {
  type        = any
  description = "Public Subnets information to be deployed in ap-southeast-1 region"
  default = [
    {
      cidr_block        = "100.64.1.0/24",
      availability_zone = "ap-southeast-1a"
    },
    {
      cidr_block        = "100.64.3.0/24",
      availability_zone = "ap-southeast-1b"
    }
  ]
}
variable "sydney_vpcs" {
  type        = any
  description = "VPCs information that will be deployed in ap-southeast-2 region"
  default = {
    "nonprod-vpc" = {
      type            = "non-prod"
      name            = "nonprod-vpc"
      cidr_block      = "10.1.0.0/16"
      private_subnets = ["10.1.0.0/24", "10.1.2.0/24"]
    }
    "prod-vpc" = {
      type            = "prod"
      name            = "prod-vpc"
      cidr_block      = "10.0.0.0/16"
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    }
    "egress-vpc" = {
      type            = "prod"
      name            = "egress-vpc"
      cidr_block      = "100.64.0.0/16"
      private_subnets = ["100.64.0.0/24", "100.64.2.0/24"]
    }
  }
}
variable "sydney_public_subnets_info" {
  type        = any
  description = "Public Subnets information to be deployed in ap-southeast-2 region"
  default = [
    {
      cidr_block        = "100.64.1.0/24",
      availability_zone = "ap-southeast-2a"
    },
    {
      cidr_block        = "100.64.3.0/24",
      availability_zone = "ap-southeast-2b"
    }
  ]
}
variable "ec2_instance_type" {
  default     = "t3.nano"
  description = "EC2 instance type for the test nodes"
}
variable "number_azs" {
  type        = number
  description = "Number of Availability Zones to use."
  default     = 2
}
variable "aws_singapore_region" {
  type        = string
  description = "Singapore region code"
  default     = "ap-southeast-1"
}
variable "aws_sydney_region" {
  type        = string
  description = "Sydney region code"
  default     = "ap-southeast-2"
}
variable "deploy_singapore_region" {
  type        = string
  description = "Singapore region"
  default     = "singapore"
}
variable "deploy_sydney_region" {
  type        = string
  description = "Sydney region"
  default     = "sydney"
}
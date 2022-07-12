# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/provider.tf ---

provider "aws" {
  region = "ap-southeast-1"
  alias  = "apse1"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  alias  = "apse2"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "awscc" {
  region = "ap-southeast-1"
  alias  = "awsccapse1"
}

provider "awscc" {
  region = "ap-southeast-2"
  alias  = "awsccapse2"
}

terraform {
  required_version = ">= 0.15.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.25.0"
    }
  }
}

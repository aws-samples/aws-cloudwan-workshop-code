# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/provider.tf ---

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

# Provider definitios for N. Virginia Region
provider "aws" {
  region = var.aws_regions.north_virginia
  alias  = "awsnvirginia"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "awscc" {
  region = var.aws_regions.north_virginia
  alias  = "awsccnvirginia"
}

# Provider definitios for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland
  alias  = "awsireland"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "awscc" {
  region = var.aws_regions.ireland
  alias  = "awsccireland"
}

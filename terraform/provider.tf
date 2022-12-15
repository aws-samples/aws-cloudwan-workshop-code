# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/provider.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.15.0"
    }
  }
}

# Provider definitios for Oregon Region
provider "aws" {
  region = var.aws_regions.oregon
  alias  = "awsoregon"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "awscc" {
  region = var.aws_regions.oregon
  alias  = "awsccoregon"
}

# Provider definitios for Stockholm Region
provider "aws" {
  region = var.aws_regions.stockholm
  alias  = "awsstockholm"

  default_tags {
    tags = {
      Project   = "Cloud WAN Workshop"
      Terraform = "Managed"
    }
  }
}

provider "awscc" {
  region = var.aws_regions.stockholm
  alias  = "awsccstockholm"
}

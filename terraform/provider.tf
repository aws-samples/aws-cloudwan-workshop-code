# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/provider.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57.0"
    }
  }
}

# Provider definition for Oregon Region
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

# Provider definition for Stockholm Region
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


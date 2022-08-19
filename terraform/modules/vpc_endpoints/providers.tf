# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/vpc_endpoins/providers.tf ---

terraform {
  required_version = ">= 0.15.3"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.9.0"
      configuration_aliases = [aws]
    }
  }
}
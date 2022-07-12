# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/init.tf ---

terraform {
  required_version = ">= 0.15.3"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.9.0"
      configuration_aliases = [aws]
    }
    awscc = {
      source                = "hashicorp/awscc"
      version               = ">= 0.25.0"
      configuration_aliases = [awscc]
    }
  }
}

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# GLOBAL NETWORK
resource "awscc_networkmanager_global_network" "global_network" {
  provider = awscc.awsccnvirginia

  description = "Cloud WAN Workshop - Global Network."

  tags = [{
    key   = "Name",
    value = "Global Network"
  }]
}

# CORE NETWORK
resource "awscc_networkmanager_core_network" "core_network" {
  provider = awscc.awsccnvirginia

  description       = "Cloud WAN Workshop - Core Network."
  global_network_id = awscc_networkmanager_global_network.global_network.id
  policy_document   = jsonencode(jsondecode(data.aws_networkmanager_core_network_policy_document.core_nw_policy.json))

  tags = [{
    key   = "Name",
    value = "Core Network"
  }]
}

# RESOURCES IN N. VIRGINIA REGION (us-east-1)
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each = var.nvirginia_spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 3.1.0"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { cidrs = each.value.endpoint_subnet_cidrs }
    workload      = { cidrs = each.value.private_subnet_cidrs }
    core_network = {
      cidrs              = each.value.cwan_subnet_cidrs
      ipv6_support       = false
      require_acceptance = each.value.type == "prod"
      accept_attachment  = each.value.type == "prod" ? var.accept_attachments : false

      tags = {
        env = each.value.type
      }
    }
  }
}

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 3.1.0"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  name       = var.nvirginia_inspection_vpc.name
  cidr_block = var.nvirginia_inspection_vpc.cidr_block
  az_count   = var.nvirginia_inspection_vpc.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      cidrs                     = var.nvirginia_inspection_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = var.nvirginia_inspection_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    core_network = {
      cidrs              = var.nvirginia_inspection_vpc.cwan_subnet_cidrs
      ipv6_support       = false
      require_acceptance = false

      tags = {
        env = "inspection"
      }
    }
  }
}

# AWS Network Firewall Resource
module "anfw_nvirginia" {
  source  = "aws-ia/networkfirewall/aws"
  version = "0.0.2"
  providers = {
    aws = aws.awsnvirginia
  }

  network_firewall_name   = "anfw-nvirginia"
  network_firewall_policy = aws_networkfirewall_firewall_policy.nvirginia_fwpolicy.arn

  vpc_id      = module.nvirginia_inspection_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.nvirginia_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.nvirginia_inspection_vpc.number_azs

  routing_configuration = {
    centralized_inspection_with_egress = {
      tgw_subnet_route_tables    = { for k, v in module.nvirginia_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
      public_subnet_route_tables = { for k, v in module.nvirginia_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks        = ["10.0.0.0/8"]
    }
  }
}

# KMS Key (used to encrypt VPC flow logs)
module "kms_nvirginia" {
  source = "./modules/kms"
  providers = {
    aws = aws.awsnvirginia
  }

  project_name = var.project_identifier
  aws_region   = var.aws_regions.north_virginia
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "compute_nvirginia" {
  for_each = module.nvirginia_spoke_vpcs
  source   = "./modules/compute"
  providers = {
    aws = aws.awsnvirginia
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.nvirginia_spoke_vpcs[each.key].number_azs
  instance_type            = var.nvirginia_spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.north_virginia.security_groups.instance
}

# VPC endpoints (SSM access)
module "vpc_endpoints_nvirginia" {
  for_each = module.nvirginia_spoke_vpcs
  source   = "./modules/vpc_endpoints"
  providers = {
    aws = aws.awsnvirginia
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  endpoints_security_group = local.north_virginia.security_groups.endpoints
  endpoints_service_names  = local.north_virginia.endpoint_service_names
}

# RESOURCES IN IRELAND REGION (eu-west-1)
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each = var.ireland_spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 3.1.0"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { cidrs = each.value.endpoint_subnet_cidrs }
    workload      = { cidrs = each.value.private_subnet_cidrs }
    core_network = {
      cidrs              = each.value.cwan_subnet_cidrs
      ipv6_support       = false
      require_acceptance = each.value.type == "prod"
      accept_attachment  = each.value.type == "prod" ? var.accept_attachments : false

      tags = {
        env = each.value.type
      }
    }
  }
}

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 3.1.0"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  name       = var.ireland_inspection_vpc.name
  cidr_block = var.ireland_inspection_vpc.cidr_block
  az_count   = var.ireland_inspection_vpc.number_azs

  core_network = {
    id  = awscc_networkmanager_core_network.core_network.core_network_id
    arn = awscc_networkmanager_core_network.core_network.core_network_arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      cidrs                     = var.nvirginia_inspection_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = var.nvirginia_inspection_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    core_network = {
      cidrs              = var.nvirginia_inspection_vpc.cwan_subnet_cidrs
      ipv6_support       = false
      require_acceptance = false

      tags = {
        env = "inspection"
      }
    }
  }
}

# AWS Network Firewall Resource
module "anfw_ireland" {
  source  = "aws-ia/networkfirewall/aws"
  version = "0.0.2"
  providers = {
    aws = aws.awsireland
  }

  network_firewall_name   = "anfw-ireland"
  network_firewall_policy = aws_networkfirewall_firewall_policy.ireland_fwpolicy.arn

  vpc_id      = module.ireland_inspection_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.ireland_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.ireland_inspection_vpc.number_azs

  routing_configuration = {
    centralized_inspection_with_egress = {
      tgw_subnet_route_tables    = { for k, v in module.ireland_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
      public_subnet_route_tables = { for k, v in module.ireland_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks        = ["10.0.0.0/8"]
    }
  }
}

# KMS Key (used to encrypt VPC flow logs)
module "kms_ireland" {
  source = "./modules/kms"
  providers = {
    aws = aws.awsireland
  }

  project_name = var.project_identifier
  aws_region   = var.aws_regions.ireland
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "compute_ireland" {
  for_each = module.ireland_spoke_vpcs
  source   = "./modules/compute"
  providers = {
    aws = aws.awsireland
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.ireland_spoke_vpcs[each.key].number_azs
  instance_type            = var.ireland_spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.ireland.security_groups.instance
}

# VPC endpoints (SSM access)
module "vpc_endpoints_ireland" {
  for_each = module.ireland_spoke_vpcs
  source   = "./modules/vpc_endpoints"
  providers = {
    aws = aws.awsireland
  }

  project_name             = var.project_identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  endpoints_security_group = local.ireland.security_groups.endpoints
  endpoints_service_names  = local.ireland.endpoint_service_names
}


# GLOBAL RESOURCES (IAM)
# IAM module creates the IAM roles needed to publish VPC Flow Logs into CloudWatch Logs, and for EC2 instances to connect to Systems Manager (regardless the AWS Region)
module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.awsnvirginia
  }

  project_name = var.project_identifier
}
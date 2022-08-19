# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# AWS CLOUD WAN
# The module used creates the Global Network and the Core Network (with initial policy defined in cloudwan_policy.tf)
module "cloudwan" {
  source  = "aws-ia/cloudwan/aws"
  version = "= 0.0.6"
  providers = {
    awscc = awscc.awsccnvirginia
  }

  create_global_network = true
  global_network = {
    description = "CloudWAN Workshop Global Network"
  }
  core_network = {
    description     = "CloudWAN Workshop Core Network"
    policy_document = data.aws_networkmanager_core_network_policy_document.core_nw_policy.json
  }

  tags = {
    Name = "CloudWAN Workshop"
  }
}

# RESOURCES IN N. VIRGINIA REGION (us-east-1)
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each = var.nvirginia_spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 2.4.0"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  subnets = {
    endpoint = {
      name_prefix = "vpc_endpoints"
      cidrs       = each.value.endpoint_subnet_cidrs
    }
    private = {
      name_prefix = "private"
      cidrs       = each.value.private_subnet_cidrs
    }
    cwan = {
      name_prefix = "cloud_wan"
      cidrs       = each.value.cwan_subnet_cidrs
    }
  }

  tags = {
    env = each.value.type
  }
}

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 2.4.0"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  name       = var.nvirginia_inspection_vpc.name
  cidr_block = var.nvirginia_inspection_vpc.cidr_block
  az_count   = var.nvirginia_inspection_vpc.number_azs

  subnets = {
    public = {
      name_prefix               = "public"
      cidrs                     = var.nvirginia_inspection_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      name_prefix             = "inspection"
      cidrs                   = var.nvirginia_inspection_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    cwan = {
      name_prefix = "cloud_wan"
      cidrs       = var.nvirginia_inspection_vpc.cwan_subnet_cidrs
    }
  }

  tags = {
    env = "inspection"
  }
}

# Spoke VPC Cloud WAN attachments
module "nvirginia_spoke_cwattachments" {
  for_each = module.nvirginia_spoke_vpcs
  source   = "./modules/cloudwan_attachment"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  core_network_id   = module.cloudwan.core_network.id
  core_network_arn  = module.cloudwan.core_network.core_network_arn
  vpc_name          = each.key
  environment       = var.nvirginia_spoke_vpcs[each.key].type
  vpc_arn           = each.value.vpc_attributes.arn
  cloudwan_subnets  = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.arn if split("/", k)[0] == "cwan" })
  route_tables      = values({ for k, v in each.value.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "private" })
  number_azs        = var.nvirginia_spoke_vpcs[each.key].number_azs
  route_to_cloudwan = "0.0.0.0/0"
}

# Attachment acceptance (only for attachments going to prod)
# resource "aws_networkmanager_attachment_accepter" "nvirginia_cwan_attachment_acceptance" {
#   for_each = {
#     for k, v in module.nvirginia_spoke_cwattachments : k => v.cloudwan_attachment.id
#     if var.ireland_spoke_vpcs[k].type == "prod"
#   }
#   provider = aws.awsnvirginia

#   attachment_id   = each.value
#   attachment_type = "VPC"
# }

# Inspection VPC Cloud WAN attachment
module "nvirginia_inspection_cwattachment" {
  source = "./modules/cloudwan_attachment"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  core_network_id   = module.cloudwan.core_network.id
  core_network_arn  = module.cloudwan.core_network.core_network_arn
  vpc_name          = "inspection-vpc"
  environment       = "inspection"
  vpc_arn           = module.nvirginia_inspection_vpc.vpc_attributes.arn
  cloudwan_subnets  = values({ for k, v in module.nvirginia_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.arn if split("/", k)[0] == "cwan" })
  route_tables      = values({ for k, v in module.nvirginia_inspection_vpc.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" })
  number_azs        = var.nvirginia_inspection_vpc.number_azs
  route_to_cloudwan = "10.0.0.0/8"
}

# AWS Network Firewall Resource
module "anfw_nvirginia" {
  source  = "aws-ia/networkfirewall/aws"
  version = "0.0.1"
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
      tgw_subnet_route_tables    = { for k, v in module.nvirginia_inspection_vpc.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "cwan" }
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
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "private" })
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
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoint" })
  endpoints_security_group = local.north_virginia.security_groups.endpoints
  endpoints_service_names  = local.north_virginia.endpoint_service_names
}

# RESOURCES IN IRELAND REGION (eu-west-1)
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each = var.ireland_spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 2.4.0"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  subnets = {
    endpoint = {
      name_prefix = "vpc_endpoints"
      cidrs       = each.value.endpoint_subnet_cidrs
    }
    private = {
      name_prefix = "private"
      cidrs       = each.value.private_subnet_cidrs
    }
    cwan = {
      name_prefix = "cloud_wan"
      cidrs       = each.value.cwan_subnet_cidrs
    }
  }

  tags = {
    env = each.value.type
  }
}

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 2.4.0"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  name       = var.ireland_inspection_vpc.name
  cidr_block = var.ireland_inspection_vpc.cidr_block
  az_count   = var.ireland_inspection_vpc.number_azs

  subnets = {
    public = {
      name_prefix               = "public"
      cidrs                     = var.ireland_inspection_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      name_prefix             = "inspection"
      cidrs                   = var.ireland_inspection_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    cwan = {
      name_prefix = "cloud_wan"
      cidrs       = var.ireland_inspection_vpc.cwan_subnet_cidrs
    }
  }

  tags = {
    env = "inspection"
  }
}

# Spoke VPC Cloud WAN attachments
module "ireland_spoke_cwattachments" {
  for_each = module.ireland_spoke_vpcs
  source   = "./modules/cloudwan_attachment"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  core_network_id   = module.cloudwan.core_network.id
  core_network_arn  = module.cloudwan.core_network.core_network_arn
  vpc_name          = each.key
  environment       = var.ireland_spoke_vpcs[each.key].type
  vpc_arn           = each.value.vpc_attributes.arn
  cloudwan_subnets  = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.arn if split("/", k)[0] == "cwan" })
  route_tables      = values({ for k, v in each.value.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "private" })
  number_azs        = var.ireland_spoke_vpcs[each.key].number_azs
  route_to_cloudwan = "0.0.0.0/0"
}

# Attachment acceptance (only for attachments going to prod)
# resource "aws_networkmanager_attachment_accepter" "ireland_cwan_attachment_acceptance" {
#   for_each = {
#     for k, v in module.ireland_spoke_cwattachments : k => v.cloudwan_attachment.id
#     if var.ireland_spoke_vpcs[k].type == "prod"
#   }
#   provider = aws.awsireland

#   attachment_id   = each.value
#   attachment_type = "VPC"
# }

# Inspection VPC Cloud WAN attachment
module "ireland_inspection_cwattachment" {
  source = "./modules/cloudwan_attachment"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  core_network_id   = module.cloudwan.core_network.id
  core_network_arn  = module.cloudwan.core_network.core_network_arn
  vpc_name          = "inspection-vpc"
  environment       = "inspection"
  vpc_arn           = module.ireland_inspection_vpc.vpc_attributes.arn
  cloudwan_subnets  = values({ for k, v in module.ireland_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.arn if split("/", k)[0] == "cwan" })
  route_tables      = values({ for k, v in module.ireland_inspection_vpc.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" })
  number_azs        = var.ireland_inspection_vpc.number_azs
  route_to_cloudwan = "10.0.0.0/8"
}

# AWS Network Firewall Resource
module "anfw_ireland" {
  source  = "aws-ia/networkfirewall/aws"
  version = "0.0.1"
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
      tgw_subnet_route_tables    = { for k, v in module.ireland_inspection_vpc.rt_attributes_by_type_by_az.private : split("/", k)[1] => v.id if split("/", k)[0] == "cwan" }
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
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "private" })
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
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoint" })
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
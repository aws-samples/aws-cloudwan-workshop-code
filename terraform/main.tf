# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

module "singapore_vpcs" {
  #Create VPCs in Singapore region based on input configuration (default.auto.tfvars)
  source  = "aws-ia/vpc/aws"
  version = ">= 1.0.0"
  providers = {
    aws   = aws.apse1
    awscc = awscc.awsccapse1
  }

  for_each = var.singapore_vpcs

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = var.number_azs

  subnets = {
    private = {
      name_prefix = "private"
      cidrs       = slice(each.value.private_subnets, 0, var.number_azs)
    }
  }
  tags = {
    Purpose     = "Cloud WAN Workshop"
    Environment = each.key
  }
}

module "sydney_vpcs" {
  #Create VPCs in Sydney region based on input configuration (default.auto.tfvars)
  source  = "aws-ia/vpc/aws"
  version = ">= 1.0.0"
  providers = {
    aws   = aws.apse2
    awscc = awscc.awsccapse2
  }

  for_each = var.sydney_vpcs

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = var.number_azs

  subnets = {
    private = {
      name_prefix = "private"
      cidrs       = slice(each.value.private_subnets, 0, var.number_azs)
    }
  }

  tags = {
    Purpose     = "Cloud WAN Workshop"
    Environment = each.key
  }
}

module "cloudwan" {
  #Create Cloud WAN related core components (global)- Global Network, Core Network with initial policy

  source  = "aws-ia/cloudwan/aws"
  version = ">= 0.0.6"
  providers = {
    awscc = awscc.awsccapse1
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

module "cwan_components_singapore" {
  #Create Cloud WAN related components in Singapore region
  #Public Subnets, Internet Gateway, NAT Gateway
  #Security Groups and rules
  #VPC Endpoints, Firewall Subnets
  #Test EC2 instances to validate configurations and connectivity
  #Firewall Subnets, Core Network Attachments
  source = "./modules/cwan_components"
  providers = {
    aws   = aws.apse1
    awscc = awscc.awsccapse1
  }

  aws_region              = var.aws_singapore_region
  deployment_region       = var.deploy_singapore_region
  ec2_instance_type       = var.ec2_instance_type
  deploy_global_resources = true

  public_subnets_info = var.singapore_public_subnets_info

  security_groups_info      = local.singapore_security_groups_info
  vpc_endpoints_ssm         = local.singapore_vpc_endpoints_ssm
  vpc_endpoints_ssmmessages = local.singapore_vpc_endpoints_ssmmessages
  vpc_endpoints_ec2messages = local.singapore_vpc_endpoints_ec2messages
  ec2_instances             = local.singapore_ec2_instances
  firewall_subnets          = local.singapore_firewall_subnets

  private_route_table_ids = values({ for k, v in module.singapore_vpcs["egress-vpc"].route_table_by_subnet_type.private : k => v.route_table_id })
  network_firewall_vpc    = module.singapore_vpcs["egress-vpc"].vpc_attributes.id
  core_network_id         = module.cloudwan.core_network["core_network_id"]
  core_network_arn        = module.cloudwan.core_network["core_network_arn"]
  core_nw_attachments     = local.singapore_core_nw_attachments
}

module "cwan_components_sydney" {
  #Create Cloud WAN related components in Sydney region
  #Public Subnets, Internet Gateway, NAT Gateway
  #Security Groups and rules
  #VPC Endpoints, Firewall Subnets
  #Test EC2 instances to validate configurations and connectivity
  #Firewall Subnets
  source = "./modules/cwan_components"
  providers = {
    aws   = aws.apse2
    awscc = awscc.awsccapse2
  }

  aws_region              = var.aws_sydney_region
  deployment_region       = var.deploy_sydney_region
  ec2_instance_type       = var.ec2_instance_type
  deploy_global_resources = false
  public_subnets_info     = var.sydney_public_subnets_info

  security_groups_info      = local.sydney_security_groups_info
  vpc_endpoints_ssm         = local.sydney_vpc_endpoints_ssm
  vpc_endpoints_ssmmessages = local.sydney_vpc_endpoints_ssmmessages
  vpc_endpoints_ec2messages = local.sydney_vpc_endpoints_ec2messages
  ec2_instances             = local.sydney_ec2_instances
  firewall_subnets          = local.sydney_firewall_subnets

  private_route_table_ids = values({ for k, v in module.sydney_vpcs["egress-vpc"].route_table_by_subnet_type.private : k => v.route_table_id })
  network_firewall_vpc    = module.sydney_vpcs["egress-vpc"].vpc_attributes.id
  core_network_id         = module.cloudwan.core_network["core_network_id"]
  core_network_arn        = module.cloudwan.core_network["core_network_arn"]
  core_nw_attachments     = local.sydney_core_nw_attachments
}
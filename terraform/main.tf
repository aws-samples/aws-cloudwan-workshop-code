# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# -------------------------- AWS Cloud WAN --------------------------
# The Cloud WAN module used creates the Global Network and the Core Network (with initial policy defined in cloudwan_policy.tf)
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

# ----------- RESOURCES IN N. VIRGINIA REGION (us-east-1) -----------
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  source  = "aws-ia/vpc/aws"
  version = "= 1.4.1"
  providers = {
    aws   = aws.awsnvirginia
    awscc = awscc.awsccnvirginia
  }

  for_each = var.nvirginia_spoke_vpcs

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  subnets = {
    private = {
      name_prefix = "private"
      cidrs       = slice(each.value.private_subnet_cidrs, 0, each.value.number_azs)
    }
  }
  tags = {
    Environment = each.value.type
  }
}

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 1.4.1"
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
      cidrs                     = slice(var.nvirginia_inspection_vpc.public_subnet_cidrs, 0, var.nvirginia_inspection_vpc.number_azs)
      nat_gateway_configuration = "all_azs"
    }
    private = {
      name_prefix  = "inspection"
      cidrs        = slice(var.nvirginia_inspection_vpc.inspection_subnet_cidrs, 0, var.nvirginia_inspection_vpc.number_azs)
      route_to_nat = true
    }
  }
  tags = {
    Environment = "inspection"
  }
}

# # Spoke VPC Cloud WAN attachments
# module "nvirginia_spoke_cwattachments" {
#   for_each = module.nvirginia_spoke_vpcs
#   source = "./modules/cloudwan_attachment"
#   providers = {
#     aws   = aws.awsnvirginia
#     awscc = awscc.awsccnvirginia
#   }

#   core_network_id = module.cloudwan.core_network.id
#   core_network_arn = module.cloudwan.core_network.arn
#   vpc_info = each.value
#   route_to_cloudwan = "0.0.0.0/0"
# }

# # Inspection VPC Cloud WAN attachment
# module "nvirginia_inspection_cwattachment" {
#   source = "./modules/cloudwan_attachment"
#   providers = {
#     aws   = aws.awsnvirginia
#     awscc = awscc.awsccnvirginia
#   }

#   core_network_id = module.cloudwan.core_network.id
#   core_network_arn = module.cloudwan.core_network.arn
#   vpc_info = module.nvirginia_inspection_vpc
#   route_to_cloudwan = "10.10.0.0/15"
# }

# ------------- RESOURCES IN IRELAND REGION (eu-west-1) -------------
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  source  = "aws-ia/vpc/aws"
  version = "= 1.4.1"
  providers = {
    aws   = aws.awsireland
    awscc = awscc.awsccireland
  }

  for_each = var.ireland_spoke_vpcs

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  subnets = {
    private = {
      name_prefix = "private"
      cidrs       = slice(each.value.private_subnet_cidrs, 0, each.value.number_azs)
    }
  }
  tags = {
    Environment = each.value.type
  }
}

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source  = "aws-ia/vpc/aws"
  version = "= 1.4.1"
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
      cidrs                     = slice(var.ireland_inspection_vpc.public_subnet_cidrs, 0, var.ireland_inspection_vpc.number_azs)
      nat_gateway_configuration = "all_azs"
    }
    private = {
      name_prefix  = "inspection"
      cidrs        = slice(var.ireland_inspection_vpc.inspection_subnet_cidrs, 0, var.ireland_inspection_vpc.number_azs)
      route_to_nat = true
    }
  }
  tags = {
    Environment = "inspection"
  }
}

# # Spoke VPC Cloud WAN attachments
# module "ireland_spoke_cwattachments" {
#   for_each = module.ireland_spoke_vpcs
#   source = "./modules/cloudwan_attachment"
#   providers = {
#     aws   = aws.awsireland
#     awscc = awscc.awsccireland
#   }

#   core_network_id = module.cloudwan.core_network.id
#   core_network_arn = module.cloudwan.core_network.arn
#   vpc_info = each.value
#   route_to_cloudwan = "0.0.0.0/0"
# }

# # Inspection VPC Cloud WAN attachment
# module "ireland_inspection_cwattachment" {
#   source = "./modules/cloudwan_attachment"
#   providers = {
#     aws   = aws.awsnvirginia
#     awscc = awscc.awsccnvirginia
#   }

#   core_network_id = module.cloudwan.core_network.id
#   core_network_arn = module.cloudwan.core_network.arn
#   vpc_info = module.ireland_inspection_vpc
#   route_to_cloudwan = "10.0.0.0/15"
# }




# module "cwan_components_singapore" {
#   Create Cloud WAN related components in Singapore region
#   Public Subnets, Internet Gateway, NAT Gateway
#   Security Groups and rules
#   VPC Endpoints, Firewall Subnets
#   Test EC2 instances to validate configurations and connectivity
#   Firewall Subnets, Core Network Attachments
#   source = "./modules/cwan_components"
#   providers = {
#     aws   = aws.apse1
#     awscc = awscc.awsccapse1
#   }

#   aws_region              = var.aws_singapore_region
#   deployment_region       = var.deploy_singapore_region
#   ec2_instance_type       = var.ec2_instance_type
#   deploy_global_resources = true

#   public_subnets_info = var.singapore_public_subnets_info

#   security_groups_info      = local.singapore_security_groups_info
#   vpc_endpoints_ssm         = local.singapore_vpc_endpoints_ssm
#   vpc_endpoints_ssmmessages = local.singapore_vpc_endpoints_ssmmessages
#   vpc_endpoints_ec2messages = local.singapore_vpc_endpoints_ec2messages
#   ec2_instances             = local.singapore_ec2_instances
#   firewall_subnets          = local.singapore_firewall_subnets

#   private_route_table_ids = values({ for k, v in module.singapore_vpcs["egress-vpc"].route_table_by_subnet_type.private : k => v.route_table_id })
#   network_firewall_vpc    = module.singapore_vpcs["egress-vpc"].vpc_attributes.id
#   core_network_id         = module.cloudwan.core_network["core_network_id"]
#   core_network_arn        = module.cloudwan.core_network["core_network_arn"]
#   core_nw_attachments     = local.singapore_core_nw_attachments
# }

# module "cwan_components_sydney" {
#   Create Cloud WAN related components in Sydney region
#   Public Subnets, Internet Gateway, NAT Gateway
#   Security Groups and rules
#   VPC Endpoints, Firewall Subnets
#   Test EC2 instances to validate configurations and connectivity
#   Firewall Subnets
#   source = "./modules/cwan_components"
#   providers = {
#     aws   = aws.apse2
#     awscc = awscc.awsccapse2
#   }

#   aws_region              = var.aws_sydney_region
#   deployment_region       = var.deploy_sydney_region
#   ec2_instance_type       = var.ec2_instance_type
#   deploy_global_resources = false
#   public_subnets_info     = var.sydney_public_subnets_info

#   security_groups_info      = local.sydney_security_groups_info
#   vpc_endpoints_ssm         = local.sydney_vpc_endpoints_ssm
#   vpc_endpoints_ssmmessages = local.sydney_vpc_endpoints_ssmmessages
#   vpc_endpoints_ec2messages = local.sydney_vpc_endpoints_ec2messages
#   ec2_instances             = local.sydney_ec2_instances
#   firewall_subnets          = local.sydney_firewall_subnets

#   private_route_table_ids = values({ for k, v in module.sydney_vpcs["egress-vpc"].route_table_by_subnet_type.private : k => v.route_table_id })
#   network_firewall_vpc    = module.sydney_vpcs["egress-vpc"].vpc_attributes.id
#   core_network_id         = module.cloudwan.core_network["core_network_id"]
#   core_network_arn        = module.cloudwan.core_network["core_network_arn"]
#   core_nw_attachments     = local.sydney_core_nw_attachments
# }
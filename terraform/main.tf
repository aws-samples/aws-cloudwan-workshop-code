# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------- LAB 1: BUILD A GLOBAL, SEGMENTED NETWORK WITH CENTRAL EGRESS ----------

# GLOBAL NETWORK
resource "aws_networkmanager_global_network" "global_network" {
  provider = aws.awsoregon

  description = "Cloud WAN Workshop - Global Network."

  tags = {
    Name = "Global Network - ${var.project_identifier}"
  }
}

# CORE NETWORK
resource "aws_networkmanager_core_network" "core_network" {
  provider = aws.awsoregon

  description       = "Cloud WAN Workshop - Core Network."
  global_network_id = aws_networkmanager_global_network.global_network.id

  create_base_policy  = true
  base_policy_regions = values({ for k, v in var.aws_regions : k => v })

  tags = {
    Name = "Core Network - ${var.project_identifier}"
  }
}

# CORE NETWORK POLICY ATTACHMENT
resource "aws_networkmanager_core_network_policy_attachment" "policy_attachment" {
  provider = aws.awsoregon

  core_network_id = aws_networkmanager_core_network.core_network.id
  policy_document = data.aws_networkmanager_core_network_policy_document.core_nw_policy.json

  depends_on = [
    module.oregon_spoke_vpcs,
    module.stockholm_spoke_vpcs
  ]
}

# RESOURCES IN OREGON (us-west-2)
# Spoke VPCs - definition in variables.tf
module "oregon_spoke_vpcs" {
  for_each  = var.oregon_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsoregon }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = aws_networkmanager_core_network.core_network.id
  #   arn = aws_networkmanager_core_network.core_network.arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(each.value.endpoint_subnet_cidrs, 0, each.value.number_azs) }
    workload      = { cidrs = slice(each.value.workload_subnet_cidrs, 0, each.value.number_azs) }
    # core_network = {
    #   cidrs = slice(each.value.cnetwork_subnet_cidrs, 0, each.value.number_azs)

    #   tags = {
    #     "${each.value.type}" = true
    #   }
    # }
  }
}

# Inspection VPC - definition in variables.tf
module "oregon_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsoregon }

  name       = var.oregon_inspection_vpc.name
  cidr_block = var.oregon_inspection_vpc.cidr_block
  az_count   = var.oregon_inspection_vpc.number_azs

  # core_network = {
  #   id  = aws_networkmanager_core_network.core_network.id
  #   arn = aws_networkmanager_core_network.core_network.arn
  # }
  # core_network_routes = {
  #   inspection = "10.0.0.0/8"
  # }

  subnets = {
    public = {
      cidrs                     = slice(var.oregon_inspection_vpc.public_subnet_cidrs, 0, var.oregon_inspection_vpc.number_azs)
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = slice(var.oregon_inspection_vpc.inspection_subnet_cidrs, 0, var.oregon_inspection_vpc.number_azs)
      connect_to_public_natgw = true
    }
    # core_network = {
    #   cidrs              = slice(var.oregon_inspection_vpc.cnetwork_subnet_cidrs, 0, var.oregon_inspection_vpc.number_azs)
    #   require_acceptance = true
    #   accept_attachment  = true

    #   tags = {
    #     sharedservices = true
    #   }
    # }
  }
}

# AWS Network Firewall Resource
# module "oregon_network_firewall" {
#   source    = "aws-ia/networkfirewall/aws"
#   version   = "1.0.1"
#   providers = { aws = aws.awsoregon }

#   network_firewall_name        = "anfw-oregon"
#   network_firewall_description = "AWS Network Firewall - Oregon"
#   network_firewall_policy      = aws_networkfirewall_firewall_policy.oregon_fwpolicy.arn

#   vpc_id      = module.oregon_inspection_vpc.vpc_attributes.id
#   vpc_subnets = { for k, v in module.oregon_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
#   number_azs  = var.oregon_inspection_vpc.number_azs

#   routing_configuration = {
#     centralized_inspection_with_egress = {
#       connectivity_subnet_route_tables = { for k, v in module.oregon_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
#       public_subnet_route_tables       = { for k, v in module.oregon_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
#       network_cidr_blocks              = ["10.0.0.0/8"]
#     }
#   }
# }

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "oregon_compute" {
  for_each  = module.oregon_spoke_vpcs
  source    = "./modules/compute"
  providers = { aws = aws.awsoregon }

  project_name    = var.project_identifier
  vpc_name        = each.key
  vpc_information = each.value
  number_azs      = var.oregon_spoke_vpcs[each.key].number_azs
  instance_type   = var.oregon_spoke_vpcs[each.key].instance_type
}

# RESOURCES IN STOCKHOLM REGION (eu-north-1)
# Spoke VPCs - definition in variables.tf
module "stockholm_spoke_vpcs" {
  for_each  = var.stockholm_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsstockholm }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = aws_networkmanager_core_network.core_network.id
  #   arn = aws_networkmanager_core_network.core_network.arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(each.value.endpoint_subnet_cidrs, 0, each.value.number_azs) }
    workload      = { cidrs = slice(each.value.workload_subnet_cidrs, 0, each.value.number_azs) }
    # core_network = {
    #   cidrs = slice(each.value.cnetwork_subnet_cidrs, 0, each.value.number_azs)

    #   tags = {
    #     "${each.value.type}" = true
    #   }
    # }
  }
}

# Inspection VPC - definition in variables.tf
module "stockholm_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsstockholm }

  name       = var.stockholm_inspection_vpc.name
  cidr_block = var.stockholm_inspection_vpc.cidr_block
  az_count   = var.stockholm_inspection_vpc.number_azs

  # core_network = {
  #   id  = aws_networkmanager_core_network.core_network.id
  #   arn = aws_networkmanager_core_network.core_network.arn
  # }
  # core_network_routes = {
  #   inspection = "10.0.0.0/8"
  # }

  subnets = {
    public = {
      cidrs                     = slice(var.stockholm_inspection_vpc.public_subnet_cidrs, 0, var.stockholm_inspection_vpc.number_azs)
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = slice(var.stockholm_inspection_vpc.inspection_subnet_cidrs, 0, var.stockholm_inspection_vpc.number_azs)
      connect_to_public_natgw = true
    }
    # core_network = {
    #   cidrs              = slice(var.stockholm_inspection_vpc.cnetwork_subnet_cidrs, 0, var.stockholm_inspection_vpc.number_azs)
    #   require_acceptance = true
    #   accept_attachment  = true

    #   tags = {
    #     sharedservices = true
    #   }
    # }
  }
}

# AWS Network Firewall Resource
# module "stockholm_network_firewall" {
#   source    = "aws-ia/networkfirewall/aws"
#   version   = "1.0.1"
#   providers = { aws = aws.awsstockholm }

#   network_firewall_name        = "anfw-stockholm"
#   network_firewall_description = "AWS Network Firewall - Stockholm"
#   network_firewall_policy      = aws_networkfirewall_firewall_policy.stockholm_fwpolicy.arn

#   vpc_id      = module.stockholm_inspection_vpc.vpc_attributes.id
#   vpc_subnets = { for k, v in module.stockholm_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
#   number_azs  = var.stockholm_inspection_vpc.number_azs

#   routing_configuration = {
#     centralized_inspection_with_egress = {
#       connectivity_subnet_route_tables = { for k, v in module.stockholm_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
#       public_subnet_route_tables       = { for k, v in module.stockholm_inspection_vpc.rt_attributes_by_type_by_az.public : k => v.id }
#       network_cidr_blocks              = ["10.0.0.0/8"]
#     }
#   }
# }

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "stockholm_compute" {
  for_each  = module.stockholm_spoke_vpcs
  source    = "./modules/compute"
  providers = { aws = aws.awsstockholm }

  project_name    = var.project_identifier
  vpc_name        = each.key
  vpc_information = each.value
  number_azs      = var.stockholm_spoke_vpcs[each.key].number_azs
  instance_type   = var.stockholm_spoke_vpcs[each.key].instance_type
}

# ---------- LAB 2: FEDERATE WITH AWS TRANSIT GATEWAY (TGW) ----------

# RESOURCES IN OREGON (us-west-2)
# Legacy VPC
module "oregon_legacy_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsoregon }

  name       = var.oregon_legacy_vpc.name
  cidr_block = var.oregon_legacy_vpc.cidr_block
  az_count   = var.oregon_legacy_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id
  # transit_gateway_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(var.oregon_legacy_vpc.endpoint_subnet_cidrs, 0, var.oregon_legacy_vpc.number_azs) }
    workload      = { cidrs = slice(var.oregon_legacy_vpc.workload_subnet_cidrs, 0, var.oregon_legacy_vpc.number_azs) }
    transit_gateway = {
      cidrs                                           = slice(var.oregon_legacy_vpc.tgw_subnet_cidrs, 0, var.oregon_legacy_vpc.number_azs)
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "oregon_tgw" {
  provider = aws.awsoregon

  description                     = "Transit Gateway - Oregon."
  amazon_side_asn                 = var.transit_gateway_asn.oregon
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "tgw-us-west-2"
  }
}

# Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "oregon_tgw_rt" {
  provider = aws.awsoregon

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

  tags = {
    Name = "tgw-rt-us-west-2"
  }
}

# Transit Gateway RT Association
resource "aws_ec2_transit_gateway_route_table_association" "oregon_tgw_rt_association" {
  provider = aws.awsoregon

  transit_gateway_attachment_id  = module.oregon_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.id
}

# Transit Gateway RT Propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "oregon_tgw_rt_propagation" {
  provider = aws.awsoregon

  transit_gateway_attachment_id  = module.oregon_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.id
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "oregon_legacy_compute" {
  source    = "./modules/compute"
  providers = { aws = aws.awsoregon }

  project_name    = var.project_identifier
  vpc_name        = "oregon_legacy_vpc"
  vpc_information = module.oregon_legacy_vpc
  number_azs      = var.oregon_legacy_vpc.number_azs
  instance_type   = var.oregon_legacy_vpc.instance_type
}

# Cloud WAN - Transit Gateway peering
# resource "aws_networkmanager_transit_gateway_peering" "cwan_oregon_peering" {
#   provider = aws.awsoregon

#   core_network_id     = aws_networkmanager_core_network.core_network.id
#   transit_gateway_arn = aws_ec2_transit_gateway.oregon_tgw.arn
# }

# # Transit Gateway policy table (and association)
# resource "aws_ec2_transit_gateway_policy_table" "oregon_tgw_policy_table" {
#   provider = aws.awsoregon

#   transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id

#   tags = {
#     Name = "tgw-policy-table-us-west-2"
#   }
# }

# resource "aws_ec2_transit_gateway_policy_table_association" "oregon_tgw_policy_table_association" {
#   provider = aws.awsoregon

#   transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.cwan_oregon_peering.transit_gateway_peering_attachment_id
#   transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.oregon_tgw_policy_table.id
# }

# Transit Gateway Route Table attachment
# resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_cwan_tgw_rt_attachment" {
#   provider = aws.awsoregon

#   peering_id                      = aws_networkmanager_transit_gateway_peering.cwan_oregon_peering.id
#   transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.arn

#   tags = {
#     Name   = "us-west-2-tgw-rt-attachment"
#     legacy = true
#   }

#   depends_on = [
#     aws_ec2_transit_gateway_policy_table_association.oregon_tgw_policy_table_association
#   ]
# }

# RESOURCES IN STOCKHOLM (us-west-2)
# Legacy VPC
module "stockholm_legacy_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsstockholm }

  name       = var.stockholm_legacy_vpc.name
  cidr_block = var.stockholm_legacy_vpc.cidr_block
  az_count   = var.stockholm_legacy_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.stockholm_tgw.id
  # transit_gateway_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = slice(var.stockholm_legacy_vpc.endpoint_subnet_cidrs, 0, var.stockholm_legacy_vpc.number_azs) }
    workload      = { cidrs = slice(var.stockholm_legacy_vpc.workload_subnet_cidrs, 0, var.stockholm_legacy_vpc.number_azs) }
    transit_gateway = {
      cidrs                                           = slice(var.stockholm_legacy_vpc.tgw_subnet_cidrs, 0, var.stockholm_legacy_vpc.number_azs)
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "stockholm_tgw" {
  provider = aws.awsstockholm

  description                     = "Transit Gateway - Stockholm."
  amazon_side_asn                 = var.transit_gateway_asn.stockholm
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "tgw-eu-north-1"
  }
}

# Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "stockholm_tgw_rt" {
  provider = aws.awsstockholm

  transit_gateway_id = aws_ec2_transit_gateway.stockholm_tgw.id

  tags = {
    Name = "tgw-rt-eu-north-1"
  }
}

# Transit Gateway RT Association
resource "aws_ec2_transit_gateway_route_table_association" "stockholm_tgw_rt_association" {
  provider = aws.awsstockholm

  transit_gateway_attachment_id  = module.stockholm_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.stockholm_tgw_rt.id
}

# Transit Gateway RT Propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "stockholm_tgw_rt_propagation" {
  provider = aws.awsstockholm

  transit_gateway_attachment_id  = module.stockholm_legacy_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.stockholm_tgw_rt.id
}

# EC2 Instances (1 instance per subnet in each Spoke VPC)
module "stockholm_legacy_compute" {
  source    = "./modules/compute"
  providers = { aws = aws.awsstockholm }

  project_name    = var.project_identifier
  vpc_name        = "stockholm_legacy_vpc"
  vpc_information = module.stockholm_legacy_vpc
  number_azs      = var.stockholm_legacy_vpc.number_azs
  instance_type   = var.stockholm_legacy_vpc.instance_type
}

# Cloud WAN - Transit Gateway peering
# resource "aws_networkmanager_transit_gateway_peering" "cwan_stockholm_peering" {
#   provider = aws.awsstockholm

#   core_network_id     = aws_networkmanager_core_network.core_network.id
#   transit_gateway_arn = aws_ec2_transit_gateway.stockholm_tgw.arn
# }

# # Transit Gateway policy table (and association)
# resource "aws_ec2_transit_gateway_policy_table" "stockholm_tgw_policy_table" {
#   provider = aws.awsstockholm

#   transit_gateway_id = aws_ec2_transit_gateway.stockholm_tgw.id

#   tags = {
#     Name = "tgw-policy-table-eu-north-1"
#   }
# }

# resource "aws_ec2_transit_gateway_policy_table_association" "stockholm_tgw_policy_table_association" {
#   provider = aws.awsstockholm

#   transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.cwan_stockholm_peering.transit_gateway_peering_attachment_id
#   transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.stockholm_tgw_policy_table.id
# }

# Transit Gateway Route Table attachment
# resource "aws_networkmanager_transit_gateway_route_table_attachment" "stockholm_cwan_tgw_rt_attachment" {
#   provider = aws.awsstockholm

#   peering_id                      = aws_networkmanager_transit_gateway_peering.cwan_stockholm_peering.id
#   transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.stockholm_tgw_rt.arn

#   tags = {
#     Name   = "eu-north-1-tgw-rt-attachment"
#     legacy = true
#   }

#   depends_on = [
#     aws_ec2_transit_gateway_policy_table_association.stockholm_tgw_policy_table_association
#   ]
# }
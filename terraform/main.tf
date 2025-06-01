# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------- LAB 1: BUILD A GLOBAL, SEGMENTED NETWORK WITH CENTRAL EGRESS ----------

# CLOUD WAN RESOURCES (GLOBAL & CORE NETWORK)
module "cloud_wan" {
  source  = "aws-ia/cloudwan/aws"
  version = "3.3.0"

  global_network = { description = "Global Network - ${var.project_identifier}" }

  core_network = {
    description     = "Core Network - ${var.project_identifier}"
    policy_document = data.aws_networkmanager_core_network_policy_document.core_nw_policy.json
  }
}

# RESOURCES IN OREGON (us-west-2)
# Spoke VPCs - definition in variables.tf
module "oregon_spoke_vpcs" {
  for_each  = var.oregon_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsoregon }

  name       = each.value.name
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = module.cloud_wan.core_network.id
  #   arn = module.cloud_wan.core_network.arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = each.value.endpoint_subnet_cidrs }
    workload      = { cidrs = each.value.workload_subnet_cidrs }
    # core_network = {
    #   cidrs = each.value.cnetwork_subnet_cidrs

    #   tags = {
    #     domain = "${each.value.type}"
    #   }
    # }
  }
}

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

# Inspection VPC - definition in variables.tf
module "oregon_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsoregon }

  name       = var.oregon_inspection_vpc.name
  cidr_block = var.oregon_inspection_vpc.cidr_block
  az_count   = var.oregon_inspection_vpc.number_azs

  core_network = {
    id  = module.cloud_wan.core_network.id
    arn = module.cloud_wan.core_network.arn
  }
  core_network_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { cidrs = var.oregon_inspection_vpc.inspection_subnet_cidrs }
    core_network = {
      cidrs              = var.oregon_inspection_vpc.cnetwork_subnet_cidrs
      require_acceptance = true
      accept_attachment  = true

      tags = {
        nfg = "inspection"
      }
    }
  }
}

# AWS Network Firewall Resource (Inspection VPC)
module "oregon_network_firewall_inspection" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsoregon }

  network_firewall_name        = "anfw-oregon-inspection"
  network_firewall_description = "AWS Network Firewall - Oregon (Inspection)"
  network_firewall_policy      = module.oregon_firewall_policies.eastwest_policy_arn

  vpc_id      = module.oregon_inspection_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.oregon_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.oregon_inspection_vpc.number_azs

  routing_configuration = {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = { for k, v in module.oregon_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
    }
  }
}

# Egress VPC - definition in variables.tf
module "oregon_egress_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsoregon }

  name       = var.oregon_egress_vpc.name
  cidr_block = var.oregon_egress_vpc.cidr_block
  az_count   = var.oregon_egress_vpc.number_azs

  core_network = {
    id  = module.cloud_wan.core_network.id
    arn = module.cloud_wan.core_network.arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      cidrs                     = var.oregon_egress_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = var.oregon_egress_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    core_network = {
      cidrs              = var.oregon_egress_vpc.cnetwork_subnet_cidrs
      require_acceptance = true
      accept_attachment  = true

      tags = {
        nfg = "egressinspection"
      }
    }
  }
}

# AWS Network Firewall Resource (Egress VPC)
module "oregon_network_firewall_egress" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsoregon }

  network_firewall_name        = "anfw-oregon-egress"
  network_firewall_description = "AWS Network Firewall - Oregon (Egress)"
  network_firewall_policy      = module.oregon_firewall_policies.egress_policy_arn

  vpc_id      = module.oregon_egress_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.oregon_egress_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.oregon_egress_vpc.number_azs

  routing_configuration = {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = { for k, v in module.oregon_egress_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
      public_subnet_route_tables       = { for k, v in module.oregon_egress_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks              = ["10.0.0.0/8"]
    }
  }
}

# Network Firewall policies
module "oregon_firewall_policies" {
  source    = "./modules/firewall_policy"
  providers = { aws = aws.awsoregon }
}

# RESOURCES IN STOCKHOLM REGION (eu-north-1)
# Spoke VPCs - definition in variables.tf
module "stockholm_spoke_vpcs" {
  for_each  = var.stockholm_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsstockholm }

  name       = each.value.name
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  # core_network = {
  #   id  = module.cloud_wan.core_network.id
  #   arn = module.cloud_wan.core_network.arn
  # }
  # core_network_routes = {
  #   workload = "0.0.0.0/0"
  # }

  subnets = {
    vpc_endpoints = { cidrs = each.value.endpoint_subnet_cidrs }
    workload      = { cidrs = each.value.workload_subnet_cidrs }
    # core_network = {
    #   cidrs = each.value.cnetwork_subnet_cidrs

    #   tags = {
    #     domain = "${each.value.type}"
    #   }
    # }
  }
}

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

# Inspection VPC - definition in variables.tf
module "stockholm_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsstockholm }

  name       = var.stockholm_inspection_vpc.name
  cidr_block = var.stockholm_inspection_vpc.cidr_block
  az_count   = var.stockholm_inspection_vpc.number_azs

  core_network = {
    id  = module.cloud_wan.core_network.id
    arn = module.cloud_wan.core_network.arn
  }
  core_network_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { cidrs = var.stockholm_inspection_vpc.inspection_subnet_cidrs }
    core_network = {
      cidrs              = var.stockholm_inspection_vpc.cnetwork_subnet_cidrs
      require_acceptance = true
      accept_attachment  = true

      tags = {
        nfg = "inspection"
      }
    }
  }
}

# AWS Network Firewall Resource (Inspection VPC)
module "stockholm_network_firewall_inspection" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsstockholm }

  network_firewall_name        = "anfw-stockholm-inspection"
  network_firewall_description = "AWS Network Firewall - Stockholm (Inspection)"
  network_firewall_policy      = module.stockholm_firewall_policies.eastwest_policy_arn

  vpc_id      = module.stockholm_inspection_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.stockholm_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.stockholm_inspection_vpc.number_azs

  routing_configuration = {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = { for k, v in module.stockholm_inspection_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
    }
  }
}

# Egress VPC - definition in variables.tf
module "stockholm_egress_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsstockholm }

  name       = var.stockholm_egress_vpc.name
  cidr_block = var.stockholm_egress_vpc.cidr_block
  az_count   = var.stockholm_egress_vpc.number_azs

  core_network = {
    id  = module.cloud_wan.core_network.id
    arn = module.cloud_wan.core_network.arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      cidrs                     = var.stockholm_egress_vpc.public_subnet_cidrs
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      cidrs                   = var.stockholm_egress_vpc.inspection_subnet_cidrs
      connect_to_public_natgw = true
    }
    core_network = {
      cidrs              = var.stockholm_egress_vpc.cnetwork_subnet_cidrs
      require_acceptance = true
      accept_attachment  = true

      tags = {
        nfg = "egressinspection"
      }
    }
  }
}

# AWS Network Firewall Resource (Egress VPC)
module "stockholm_network_firewall_egress" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.2"
  providers = { aws = aws.awsstockholm }

  network_firewall_name        = "anfw-stockholm-egress"
  network_firewall_description = "AWS Network Firewall - Stockholm (Egress)"
  network_firewall_policy      = module.stockholm_firewall_policies.egress_policy_arn

  vpc_id      = module.stockholm_egress_vpc.vpc_attributes.id
  vpc_subnets = { for k, v in module.stockholm_egress_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }
  number_azs  = var.stockholm_egress_vpc.number_azs

  routing_configuration = {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = { for k, v in module.stockholm_egress_vpc.rt_attributes_by_type_by_az.core_network : k => v.id }
      public_subnet_route_tables       = { for k, v in module.stockholm_egress_vpc.rt_attributes_by_type_by_az.public : k => v.id }
      network_cidr_blocks              = ["10.0.0.0/8"]
    }
  }
}

# Network Firewall policies
module "stockholm_firewall_policies" {
  source    = "./modules/firewall_policy"
  providers = { aws = aws.awsstockholm }
}

# # VPN CONNECTION (LONDON)
# # Customer gateway
# resource "aws_customer_gateway" "cgw" {
#   provider = aws.awsstockholm

#   bgp_asn    = 64512
#   ip_address = aws_eip.cgw_eip.public_ip
#   type       = "ipsec.1"

#   tags = {
#     Name = "cgw-cwan-workshop"
#   }
# }

# # Site-to-Site VPN connection
# resource "aws_vpn_connection" "vpn" {
#   provider = aws.awsstockholm

#   customer_gateway_id = aws_customer_gateway.cgw.id
#   type                = "ipsec.1"
# }

# # VPN attachment
# resource "aws_networkmanager_site_to_site_vpn_attachment" "vpn_attachment" {
#   provider = aws.awsstockholm

#   core_network_id    = module.cloud_wan.core_network.id
#   vpn_connection_arn = aws_vpn_connection.vpn.arn

#   tags = {
#     Name   = "onpremises"
#     domain = "onpremises"
#   }
# }

# ---------- LAB 2: FEDERATE WITH AWS TRANSIT GATEWAY (TGW) ----------

# RESOURCES IN OREGON (us-west-2)
# Legacy VPC
module "oregon_legacy_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsoregon }

  name       = var.oregon_legacy_vpc.name
  cidr_block = var.oregon_legacy_vpc.cidr_block
  az_count   = var.oregon_legacy_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.oregon_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

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

# # Cloud WAN - Transit Gateway peering
# resource "aws_networkmanager_transit_gateway_peering" "cwan_oregon_peering" {
#   provider = aws.awsoregon

#   core_network_id     = module.cloud_wan.core_network.id
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

# # Transit Gateway Route Table attachment
# resource "aws_networkmanager_transit_gateway_route_table_attachment" "oregon_cwan_tgw_rt_attachment" {
#   provider = aws.awsoregon

#   peering_id                      = aws_networkmanager_transit_gateway_peering.cwan_oregon_peering.id
#   transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.oregon_tgw_rt.arn

#   tags = {
#     Name = "us-west-2-tgw-rt-attachment"
#   }

#   depends_on = [
#     aws_ec2_transit_gateway_policy_table_association.oregon_tgw_policy_table_association
#   ]
# }

# RESOURCES IN STOCKHOLM (us-west-2)
# Legacy VPC
module "stockholm_legacy_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awsstockholm }

  name       = var.stockholm_legacy_vpc.name
  cidr_block = var.stockholm_legacy_vpc.cidr_block
  az_count   = var.stockholm_legacy_vpc.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.stockholm_tgw.id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

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

# # Cloud WAN - Transit Gateway peering
# resource "aws_networkmanager_transit_gateway_peering" "cwan_stockholm_peering" {
#   provider = aws.awsstockholm

#   core_network_id     = module.cloud_wan.core_network.id
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

# # Transit Gateway Route Table attachment
# resource "aws_networkmanager_transit_gateway_route_table_attachment" "stockholm_cwan_tgw_rt_attachment" {
#   provider = aws.awsstockholm

#   peering_id                      = aws_networkmanager_transit_gateway_peering.cwan_stockholm_peering.id
#   transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.stockholm_tgw_rt.arn

#   tags = {
#     Name = "eu-north-1-tgw-rt-attachment"
#   }

#   depends_on = [
#     aws_ec2_transit_gateway_policy_table_association.stockholm_tgw_policy_table_association
#   ]
# }
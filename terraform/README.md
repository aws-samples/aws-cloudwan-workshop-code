<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN - Terraform

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in Terraform of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloudwan\_workshop\_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Pre Requisites

* An AWS account with an IAM user that has appropriate permissions
* Terraform installed

## Deployment instructions

* Clone the repository
* If you want to follow the [workshop instructions](https://catalog.workshops.aws/cloudwan/en-US), move to the [Following the lab instructions](#following-the-lab-instructions) section.
* If you want to test out the code outside the lab instructions:
  * Check the `variables.tf` file and change the values accordingly.
  * The Cloud WAN policy can be found in the file `cloudwan_policy.tf`, and the AWS Network Firewall policies in the `firewall_policies.tf` file.
  * Main resources can be found in the `main.tf` file, while the resources simulating the on-premises environments are in the `on_prem.tf` file.
* Initialize Terraform using `terraform init`.

## Following the lab instructions

**NOTE**: The final state of both workshop labs is codified in this repository. However, some pieces are commented so the first `terraform apply` will create only the initial architecture when starting Lab 1. To create the whole architecture in one deployment, uncomment all the commented lines and use `terraform apply`

### Lab 1 - Build a global, segmented network with central egress

**NOTE**: Due to the Terraform modules used, Inspection VPCs' attachments will be created at the same time as the initial environment. Take that into account when following the lab instructions.

1. If you want to follow the lab guide:
  * `terraform apply` to build the initial environment.
2. If you want to build the end architecture after finishing the steps, uncomment the following lines and do `terraform apply`:
  * In `cloudwan_policy.tf` uncomment lines 59-64 and 73-147.
  * In `main.tf` uncomment lines 33-39, 44-50, 200-206, 211-217, and 355-388.

Use `terraform destroy` to clean-up the test environment and avoid undesired charges.

### Lab 2 - Federate with AWS Transit Gateway

1. If you want to follow the lab guide:
  * Check point 2 in [Lab 1](#lab-1---build-a-global-segmented-network-with-central-egress) to uncomment the corresponding lines and do `terraform apply` to build the initial environment.
  * Follow [Step 6](https://catalog.workshops.aws/cloudwan/en-US/3-labs/lab1/step-6) in the workshop guide to configure the VPN connection.
2. If you want to build the end architecture after finishing the steps, uncomment the following lines and do `terraform apply`:
  * In `cloudwan_policy.tf` uncomment lines 40-47, 59-71, and 73-161.
  * In `main.tf` uncomment lines 33-39, 44-50, 200-206, 211-217, 355-388, 472-512 and 594-634.

Use `terraform destroy` to clean-up the test environment and avoid undesired charges.

### Lab 3 - Additional inspection scenarios

1. If you want to follow the lab guide, check point 2 in [Lab 2](#lab-2---federate-with-aws-transit-gateway) to uncomment the corresponding lines and do `terraform apply` to build the initial environment.
2. If you want to build the end architecture after finishing the steps, check [lab3.md](./lab3.md) to understand what to change from the provided code.

Use `terraform destroy` to clean-up the test environment and avoid undesired charges.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |
| <a name="provider_aws.awslondon"></a> [aws.awslondon](#provider\_aws.awslondon) | >= 5.0.0 |
| <a name="provider_aws.awsoregon"></a> [aws.awsoregon](#provider\_aws.awsoregon) | >= 5.0.0 |
| <a name="provider_aws.awsstockholm"></a> [aws.awsstockholm](#provider\_aws.awsstockholm) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_wan"></a> [cloud\_wan](#module\_cloud\_wan) | aws-ia/cloudwan/aws | 3.3.0 |
| <a name="module_on_prem_vpc"></a> [on\_prem\_vpc](#module\_on\_prem\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_oregon_compute"></a> [oregon\_compute](#module\_oregon\_compute) | ./modules/compute | n/a |
| <a name="module_oregon_egress_vpc"></a> [oregon\_egress\_vpc](#module\_oregon\_egress\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_oregon_firewall_policies"></a> [oregon\_firewall\_policies](#module\_oregon\_firewall\_policies) | ./modules/firewall_policy | n/a |
| <a name="module_oregon_inspection_vpc"></a> [oregon\_inspection\_vpc](#module\_oregon\_inspection\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_oregon_legacy_compute"></a> [oregon\_legacy\_compute](#module\_oregon\_legacy\_compute) | ./modules/compute | n/a |
| <a name="module_oregon_legacy_vpc"></a> [oregon\_legacy\_vpc](#module\_oregon\_legacy\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_oregon_network_firewall_egress"></a> [oregon\_network\_firewall\_egress](#module\_oregon\_network\_firewall\_egress) | aws-ia/networkfirewall/aws | 1.0.2 |
| <a name="module_oregon_network_firewall_inspection"></a> [oregon\_network\_firewall\_inspection](#module\_oregon\_network\_firewall\_inspection) | aws-ia/networkfirewall/aws | 1.0.2 |
| <a name="module_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#module\_oregon\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_stockholm_compute"></a> [stockholm\_compute](#module\_stockholm\_compute) | ./modules/compute | n/a |
| <a name="module_stockholm_egress_vpc"></a> [stockholm\_egress\_vpc](#module\_stockholm\_egress\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_stockholm_firewall_policies"></a> [stockholm\_firewall\_policies](#module\_stockholm\_firewall\_policies) | ./modules/firewall_policy | n/a |
| <a name="module_stockholm_inspection_vpc"></a> [stockholm\_inspection\_vpc](#module\_stockholm\_inspection\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_stockholm_legacy_compute"></a> [stockholm\_legacy\_compute](#module\_stockholm\_legacy\_compute) | ./modules/compute | n/a |
| <a name="module_stockholm_legacy_vpc"></a> [stockholm\_legacy\_vpc](#module\_stockholm\_legacy\_vpc) | aws-ia/vpc/aws | = 4.4.4 |
| <a name="module_stockholm_network_firewall_egress"></a> [stockholm\_network\_firewall\_egress](#module\_stockholm\_network\_firewall\_egress) | aws-ia/networkfirewall/aws | 1.0.2 |
| <a name="module_stockholm_network_firewall_inspection"></a> [stockholm\_network\_firewall\_inspection](#module\_stockholm\_network\_firewall\_inspection) | aws-ia/networkfirewall/aws | 1.0.2 |
| <a name="module_stockholm_spoke_vpcs"></a> [stockholm\_spoke\_vpcs](#module\_stockholm\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.4.4 |

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.cgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_ec2_transit_gateway.oregon_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway.stockholm_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_policy_table.oregon_tgw_policy_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_policy_table) | resource |
| [aws_ec2_transit_gateway_policy_table.stockholm_tgw_policy_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_policy_table) | resource |
| [aws_ec2_transit_gateway_policy_table_association.oregon_tgw_policy_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_policy_table_association) | resource |
| [aws_ec2_transit_gateway_policy_table_association.stockholm_tgw_policy_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_policy_table_association) | resource |
| [aws_ec2_transit_gateway_route_table.oregon_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table.stockholm_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.oregon_tgw_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_association.stockholm_tgw_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.oregon_tgw_rt_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.stockholm_tgw_rt_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_eip.cgw_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.cgw_eip_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_iam_instance_profile.instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.describe_vpn_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.iam_role_policy_attachment_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpn_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.cgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_networkmanager_site_to_site_vpn_attachment.vpn_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_site_to_site_vpn_attachment) | resource |
| [aws_networkmanager_transit_gateway_peering.cwan_oregon_peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_transit_gateway_peering) | resource |
| [aws_networkmanager_transit_gateway_peering.cwan_stockholm_peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_transit_gateway_peering) | resource |
| [aws_networkmanager_transit_gateway_route_table_attachment.oregon_cwan_tgw_rt_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_transit_gateway_route_table_attachment) | resource |
| [aws_networkmanager_transit_gateway_route_table_attachment.stockholm_cwan_tgw_rt_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_transit_gateway_route_table_attachment) | resource |
| [aws_security_group.cgw_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpn_connection.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [aws_networkmanager_core_network_policy_document.core_nw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |
| [aws_ssm_parameter.ubuntu_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS regions to spin up resources. | `map(string)` | <pre>{<br/>  "london": "eu-west-2",<br/>  "oregon": "us-west-2",<br/>  "stockholm": "eu-north-1"<br/>}</pre> | no |
| <a name="input_oregon_egress_vpc"></a> [oregon\_egress\_vpc](#input\_oregon\_egress\_vpc) | Information about the Egress VPC to create in us-west-2. | `any` | <pre>{<br/>  "cidr_block": "100.64.0.0/16",<br/>  "cnetwork_subnet_cidrs": [<br/>    "100.64.0.64/28",<br/>    "100.64.0.80/28"<br/>  ],<br/>  "inspection_subnet_cidrs": [<br/>    "100.64.0.32/28",<br/>    "100.64.0.48/28"<br/>  ],<br/>  "name": "egress-us-west-2",<br/>  "number_azs": 2,<br/>  "public_subnet_cidrs": [<br/>    "100.64.0.0/28",<br/>    "100.64.0.16/28"<br/>  ]<br/>}</pre> | no |
| <a name="input_oregon_inspection_vpc"></a> [oregon\_inspection\_vpc](#input\_oregon\_inspection\_vpc) | Information about the Inspection VPC to create in us-west-2. | `any` | <pre>{<br/>  "cidr_block": "100.64.0.0/16",<br/>  "cnetwork_subnet_cidrs": [<br/>    "100.64.0.32/28",<br/>    "100.64.0.48/28"<br/>  ],<br/>  "inspection_subnet_cidrs": [<br/>    "100.64.0.0/28",<br/>    "100.64.0.16/28"<br/>  ],<br/>  "name": "inspection-us-west-2",<br/>  "number_azs": 2<br/>}</pre> | no |
| <a name="input_oregon_legacy_vpc"></a> [oregon\_legacy\_vpc](#input\_oregon\_legacy\_vpc) | Information about the Legacy VPC to create in us-west-2. | `any` | <pre>{<br/>  "cidr_block": "10.12.0.0/16",<br/>  "endpoint_subnet_cidrs": [<br/>    "10.12.2.0/28",<br/>    "10.12.3.16/28"<br/>  ],<br/>  "instance_type": "t3.micro",<br/>  "name": "legacy-us-west-2",<br/>  "number_azs": 2,<br/>  "tgw_subnet_cidrs": [<br/>    "10.12.3.32/28",<br/>    "10.12.3.48/28"<br/>  ],<br/>  "workload_subnet_cidrs": [<br/>    "10.12.0.0/24",<br/>    "10.12.1.0/24"<br/>  ]<br/>}</pre> | no |
| <a name="input_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#input\_oregon\_spoke\_vpcs) | Information about the VPCs to create in us-west-2. | `any` | <pre>{<br/>  "prod": {<br/>    "cidr_block": "10.10.0.0/16",<br/>    "cnetwork_subnet_cidrs": [<br/>      "10.10.2.32/28",<br/>      "10.10.2.48/28"<br/>    ],<br/>    "endpoint_subnet_cidrs": [<br/>      "10.10.2.0/28",<br/>      "10.10.2.16/28"<br/>    ],<br/>    "instance_type": "t3.micro",<br/>    "name": "prod-us-west-2",<br/>    "number_azs": 2,<br/>    "type": "prod",<br/>    "workload_subnet_cidrs": [<br/>      "10.10.0.0/24",<br/>      "10.10.1.0/24"<br/>    ]<br/>  },<br/>  "thirdparty": {<br/>    "cidr_block": "10.11.0.0/16",<br/>    "cnetwork_subnet_cidrs": [<br/>      "10.11.2.32/28",<br/>      "10.11.2.48/28"<br/>    ],<br/>    "endpoint_subnet_cidrs": [<br/>      "10.11.2.0/28",<br/>      "10.11.2.16/28"<br/>    ],<br/>    "instance_type": "t3.micro",<br/>    "name": "thirdpary-us-west-2",<br/>    "number_azs": 2,<br/>    "type": "thirdparty",<br/>    "workload_subnet_cidrs": [<br/>      "10.11.0.0/24",<br/>      "10.11.1.0/24"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_project_identifier"></a> [project\_identifier](#input\_project\_identifier) | Project Identifier. | `string` | `"CloudWAN_Workshop"` | no |
| <a name="input_stockholm_egress_vpc"></a> [stockholm\_egress\_vpc](#input\_stockholm\_egress\_vpc) | Information about the Egress VPC to create in eu-north-1. | `any` | <pre>{<br/>  "cidr_block": "100.64.0.0/16",<br/>  "cnetwork_subnet_cidrs": [<br/>    "100.64.0.64/28",<br/>    "100.64.0.80/28"<br/>  ],<br/>  "inspection_subnet_cidrs": [<br/>    "100.64.0.32/28",<br/>    "100.64.0.48/28"<br/>  ],<br/>  "name": "egress-eu-north-1",<br/>  "number_azs": 2,<br/>  "public_subnet_cidrs": [<br/>    "100.64.0.0/28",<br/>    "100.64.0.16/28"<br/>  ]<br/>}</pre> | no |
| <a name="input_stockholm_inspection_vpc"></a> [stockholm\_inspection\_vpc](#input\_stockholm\_inspection\_vpc) | Information about the Inspection VPC to create in eu-north-1. | `any` | <pre>{<br/>  "cidr_block": "100.64.0.0/16",<br/>  "cnetwork_subnet_cidrs": [<br/>    "100.64.0.32/28",<br/>    "100.64.0.48/28"<br/>  ],<br/>  "inspection_subnet_cidrs": [<br/>    "100.64.0.0/28",<br/>    "100.64.0.16/28"<br/>  ],<br/>  "name": "inspection-eu-north-1",<br/>  "number_azs": 2<br/>}</pre> | no |
| <a name="input_stockholm_legacy_vpc"></a> [stockholm\_legacy\_vpc](#input\_stockholm\_legacy\_vpc) | Information about the Legacy VPC to create in eu-north-1. | `any` | <pre>{<br/>  "cidr_block": "10.2.0.0/16",<br/>  "endpoint_subnet_cidrs": [<br/>    "10.2.2.0/28",<br/>    "10.2.3.16/28"<br/>  ],<br/>  "instance_type": "t3.micro",<br/>  "name": "legacy-eu-north-1",<br/>  "number_azs": 2,<br/>  "tgw_subnet_cidrs": [<br/>    "10.2.3.32/28",<br/>    "10.2.3.48/28"<br/>  ],<br/>  "workload_subnet_cidrs": [<br/>    "10.2.0.0/24",<br/>    "10.2.1.0/24"<br/>  ]<br/>}</pre> | no |
| <a name="input_stockholm_spoke_vpcs"></a> [stockholm\_spoke\_vpcs](#input\_stockholm\_spoke\_vpcs) | Information about the VPCs to create in eu-north-1. | `any` | <pre>{<br/>  "prod": {<br/>    "cidr_block": "10.0.0.0/16",<br/>    "cnetwork_subnet_cidrs": [<br/>      "10.0.2.32/28",<br/>      "10.0.2.48/28"<br/>    ],<br/>    "endpoint_subnet_cidrs": [<br/>      "10.0.2.0/28",<br/>      "10.0.2.16/28"<br/>    ],<br/>    "instance_type": "t3.micro",<br/>    "name": "prod-eu-north-1",<br/>    "number_azs": 2,<br/>    "type": "prod",<br/>    "workload_subnet_cidrs": [<br/>      "10.0.0.0/24",<br/>      "10.0.1.0/24"<br/>    ]<br/>  },<br/>  "thirdparty": {<br/>    "cidr_block": "10.1.0.0/16",<br/>    "cnetwork_subnet_cidrs": [<br/>      "10.1.2.32/28",<br/>      "10.1.2.48/28"<br/>    ],<br/>    "endpoint_subnet_cidrs": [<br/>      "10.1.2.0/28",<br/>      "10.1.2.16/28"<br/>    ],<br/>    "instance_type": "t3.micro",<br/>    "name": "thirdpary-us-west-2",<br/>    "number_azs": 2,<br/>    "type": "thirdparty",<br/>    "workload_subnet_cidrs": [<br/>      "10.1.0.0/24",<br/>      "10.1.1.0/24"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | Transit Gateway ASNs. | `map(number)` | <pre>{<br/>  "oregon": 64515,<br/>  "stockholm": 64516<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
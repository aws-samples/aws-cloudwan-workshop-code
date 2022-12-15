<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN - Terraform

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in Terraform of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloud\_wan\_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Pre Requisites

* An AWS account with an IAM user that has appropriate permissions
* Terraform installed

## Deployment instructions

* Clone the repository
* Modify *variables.tf* and *locals.tf* in the project root directory if there are any changes needed to the VPCs/Subnets/Security Groups/VPC Endpoints related configuration. The defaults would create required VPCs and other resources in **us-west-2** and **eu-north-1** AWS Regions.
* If you want to test out the code outside the lab instructions, you will find the Cloud WAN policy in the *cloudwan\_policy.tf* file, the AWS Network Firewall policies in the *firewall\_policies.tf* file, and the rest of resources related to the architecture in *main.tf*.
* Initialize Terraform using `terraform init`.

## Following the lab instructions

**NOTE**: The final state of both workshop labs is codified in this repository. However, some pieces are commented so the first `terraform apply` will create only the initial architecture when starting Lab 1.

* To follow the workshop, you can either use the AWS Management console as indicated in the workshop instructions, or uncomment the sections required (as explained below).
* To create the whole architecture in one deployment and use `terraform apply`

### Lab 1 - Build a global, segmented network with central egress

* Step 1 - *Create/Review JSON for Core Network Policy*. Nothing to do here, everything is built with the first deployment.
* Step 2 - *Update Core Network Policy*. This section updates the Core Network policy with the *attachment\_policies*. In *cloudwan\_policy.tf*, **uncomment lines 44 to 88**
  * Understand how the [Core Network policy data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) works, as it is used to simplify the definition of the policy - rather than using a JSON file.
* Step 3 - *Create attachments*. This section attaches the Spoke and Inspection VPCs to the Core Network. Note that, due the Terraform modules used in this example, the Inspection VPCs were already attached in the first deployment.
  * In *main.tf*, **uncomment lines 48 - 51, 59 - 67, 187 - 190, 198 - 206**.
  * In *outputs.tf*, **uncomment 29 and 34**.
  * The VPC resources are handled by the following [VPC module](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest), and the AWS Network Firewall resource (and some routing in the Inspection VPCs) by the [AWS Network Firewall module](https://registry.terraform.io/modules/aws-ia/networkfirewall/aws/latest), both created and maintained by AWS. Take some time to check the module and understand how the different resources are defined.
* Step 4 - *Update Core Network Policy for routing*. Now we are adding more information to the Core Network policy, related to the routing from the Spoke VPCs to the Inspection VPCs.
  * In *cloudwan\_policy.tf*, **uncomment lines 104 to 130**.
  * Note that you need to put the attachments of the Inspection VPCs in the definition of the static routes. You can find them in the outputs **cloud\_wan.attachments.oregon.inspection** and **cloud\_wan.attachments.stockholm.inspection**.
* Step 5 - *Update VPC Route tables*. Configuring the VPC routes to point to the Core Network attachment. In *main.tf*, **uncomment lines 52 - 54, 88 - 90, 191 - 193, and 227 - 229**.
* Step 6 - *Perform tests to validate configuration*. Nothing to do here, follow the lab instructions.

### Lab 2 - Federate with AWS Transit Gateway

* Step 1 - *Core Policy Updates*. We need to update the Core Network policy to include the "legacy" infrastructure (TGW and Legacy VPC). In *cloudwan\_policy.tf*, **uncomment lines 39 - 46, 90 - 102, and 132 - 140**.
* Step 2 - *TGW Peering*. Create TGW peering to Cloud WAN in both Regions. The console creates in the same workflow the peering, TGW policy table, and associates the policy table to the peering; here we need to create all those resources. In *main.tf*, **uncomment lines 427 - 451, and 573 - 597**.
* Step 3 - *TGW Attachments*. Create the TGW route table attachments in Cloud WAN (in both Regions). In *main.tf* file, **uncomment lines 453 - 468, and 599 - 614**.
* Step 4 - *Update VPC and TGW Route Tables*. In this section, we have to create the VPC routing in the Legacy VPCs to communicate to the Transit Gateway. In *main.tf* file, **uncomment lines 339 - 341, and 485 - 487**.
  * Take your time to understand how the [VPC module](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest) works, and how it abstracts the creation of TGW and Cloud WAN attachments (and routing to them).
* Step 5 - *Validation*. Nothing to do here, follow the lab instructions.

**NOTE**: Remember to do `terraform destroy` when you are done with the lab and your tests, to avoid undesired charges.

## References

* [AWS Cloud WAN documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/what-is-cloudwan.html).
* [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).
* Blog post: [Introducing AWS Cloud WAN (Preview)](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-aws-cloud-wan-preview/).
* Blog post: [AWS Cloud WAN and AWS Transit Gateway migration and interoperability patterns](https://aws.amazon.com/blogs/networking-and-content-delivery/aws-cloud-wan-and-aws-transit-gateway-migration-and-interoperability-patterns/)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.46.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.46.0 |
| <a name="provider_aws.awsoregon"></a> [aws.awsoregon](#provider\_aws.awsoregon) | 4.46.0 |
| <a name="provider_aws.awsstockholm"></a> [aws.awsstockholm](#provider\_aws.awsstockholm) | 4.46.0 |
| <a name="provider_awscc.awsccoregon"></a> [awscc.awsccoregon](#provider\_awscc.awsccoregon) | 0.42.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_oregon_compute"></a> [oregon\_compute](#module\_oregon\_compute) | ./modules/compute | n/a |
| <a name="module_oregon_inspection_vpc"></a> [oregon\_inspection\_vpc](#module\_oregon\_inspection\_vpc) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_oregon_legacy_compute"></a> [oregon\_legacy\_compute](#module\_oregon\_legacy\_compute) | ./modules/compute | n/a |
| <a name="module_oregon_legacy_endpoints"></a> [oregon\_legacy\_endpoints](#module\_oregon\_legacy\_endpoints) | ./modules/vpc_endpoints | n/a |
| <a name="module_oregon_legacy_vpc"></a> [oregon\_legacy\_vpc](#module\_oregon\_legacy\_vpc) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_oregon_network_firewall"></a> [oregon\_network\_firewall](#module\_oregon\_network\_firewall) | aws-ia/networkfirewall/aws | 0.0.2 |
| <a name="module_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#module\_oregon\_spoke\_vpcs) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_oregon_vpc_endpoints"></a> [oregon\_vpc\_endpoints](#module\_oregon\_vpc\_endpoints) | ./modules/vpc_endpoints | n/a |
| <a name="module_stockholm_compute"></a> [stockholm\_compute](#module\_stockholm\_compute) | ./modules/compute | n/a |
| <a name="module_stockholm_inspection_vpc"></a> [stockholm\_inspection\_vpc](#module\_stockholm\_inspection\_vpc) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_stockholm_legacy_compute"></a> [stockholm\_legacy\_compute](#module\_stockholm\_legacy\_compute) | ./modules/compute | n/a |
| <a name="module_stockholm_legacy_endpoints"></a> [stockholm\_legacy\_endpoints](#module\_stockholm\_legacy\_endpoints) | ./modules/vpc_endpoints | n/a |
| <a name="module_stockholm_legacy_vpc"></a> [stockholm\_legacy\_vpc](#module\_stockholm\_legacy\_vpc) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_stockholm_network_firewall"></a> [stockholm\_network\_firewall](#module\_stockholm\_network\_firewall) | aws-ia/networkfirewall/aws | 0.0.2 |
| <a name="module_stockholm_spoke_vpcs"></a> [stockholm\_spoke\_vpcs](#module\_stockholm\_spoke\_vpcs) | aws-ia/vpc/aws | = 3.1.0 |
| <a name="module_stockholm_vpc_endpoints"></a> [stockholm\_vpc\_endpoints](#module\_stockholm\_vpc\_endpoints) | ./modules/vpc_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.oregon_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway.stockholm_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route_table.oregon_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table.stockholm_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.oregon_tgw_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_association.stockholm_tgw_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.oregon_tgw_rt_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.stockholm_tgw_rt_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_networkfirewall_firewall_policy.oregon_fwpolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_firewall_policy.stockholm_fwpolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_oregon](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_stockholm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_oregon](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_stockholm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [awscc_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/networkmanager_core_network) | resource |
| [aws_networkmanager_core_network_policy_document.core_nw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS regions to spin up resources. | `map(string)` | <pre>{<br>  "oregon": "us-west-2",<br>  "stockholm": "eu-north-1"<br>}</pre> | no |
| <a name="input_oregon_inspection_vpc"></a> [oregon\_inspection\_vpc](#input\_oregon\_inspection\_vpc) | Information about the Inspection VPC to create in us-west-2. | `any` | <pre>{<br>  "cidr_block": "100.64.0.0/16",<br>  "cnetwork_subnet_cidrs": [<br>    "100.64.0.96/28",<br>    "100.64.0.112/28",<br>    "100.64.0.128/28"<br>  ],<br>  "inspection_subnet_cidrs": [<br>    "100.64.0.48/28",<br>    "100.64.0.64/28",<br>    "100.64.0.80/28"<br>  ],<br>  "name": "inspection-us-west-2",<br>  "number_azs": 2,<br>  "public_subnet_cidrs": [<br>    "100.64.0.0/28",<br>    "100.64.0.16/28",<br>    "100.64.0.32/28"<br>  ]<br>}</pre> | no |
| <a name="input_oregon_legacy_vpc"></a> [oregon\_legacy\_vpc](#input\_oregon\_legacy\_vpc) | Information about the Legacy VPC to create in us-west-2. | `any` | <pre>{<br>  "cidr_block": "10.2.0.0/16",<br>  "endpoint_subnet_cidrs": [<br>    "10.2.3.0/28",<br>    "10.2.3.16/28",<br>    "10.2.3.32/28"<br>  ],<br>  "instance_type": "t3.micro",<br>  "name": "legacy-us-west-2",<br>  "number_azs": 2,<br>  "tgw_subnet_cidrs": [<br>    "10.2.3.48/28",<br>    "10.2.3.64/28",<br>    "10.2.3.80/28"<br>  ],<br>  "workload_subnet_cidrs": [<br>    "10.2.0.0/24",<br>    "10.2.1.0/24",<br>    "10.2.2.0/24"<br>  ]<br>}</pre> | no |
| <a name="input_oregon_spoke_vpcs"></a> [oregon\_spoke\_vpcs](#input\_oregon\_spoke\_vpcs) | Information about the VPCs to create in us-west-2. | `any` | <pre>{<br>  "non-prod": {<br>    "cidr_block": "10.1.0.0/16",<br>    "cnetwork_subnet_cidrs": [<br>      "10.1.3.48/28",<br>      "10.1.3.64/28",<br>      "10.1.3.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.1.3.0/28",<br>      "10.1.3.16/28",<br>      "10.1.3.32/28"<br>    ],<br>    "instance_type": "t3.micro",<br>    "name": "non-prod-us-west-2",<br>    "number_azs": 2,<br>    "type": "nonprod",<br>    "workload_subnet_cidrs": [<br>      "10.1.0.0/24",<br>      "10.1.1.0/24",<br>      "10.1.2.0/24"<br>    ]<br>  },<br>  "prod": {<br>    "cidr_block": "10.0.0.0/16",<br>    "cnetwork_subnet_cidrs": [<br>      "10.0.3.48/28",<br>      "10.0.3.64/28",<br>      "10.0.3.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.0.3.0/28",<br>      "10.0.3.16/28",<br>      "10.0.3.32/28"<br>    ],<br>    "instance_type": "t3.micro",<br>    "name": "prod-us-west-2",<br>    "number_azs": 2,<br>    "type": "prod",<br>    "workload_subnet_cidrs": [<br>      "10.0.0.0/24",<br>      "10.0.1.0/24",<br>      "10.0.2.0/24"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_project_identifier"></a> [project\_identifier](#input\_project\_identifier) | Project Identifier. | `string` | `"CloudWAN_Workshop"` | no |
| <a name="input_stockholm_inspection_vpc"></a> [stockholm\_inspection\_vpc](#input\_stockholm\_inspection\_vpc) | Information about the Inspection VPC to create in eu-north-1. | `any` | <pre>{<br>  "cidr_block": "100.64.0.0/16",<br>  "cnetwork_subnet_cidrs": [<br>    "100.64.0.96/28",<br>    "100.64.0.112/28",<br>    "100.64.0.128/28"<br>  ],<br>  "inspection_subnet_cidrs": [<br>    "100.64.0.48/28",<br>    "100.64.0.64/28",<br>    "100.64.0.80/28"<br>  ],<br>  "name": "inspection-eu-north-1",<br>  "number_azs": 2,<br>  "public_subnet_cidrs": [<br>    "100.64.0.0/28",<br>    "100.64.0.16/28",<br>    "100.64.0.32/28"<br>  ]<br>}</pre> | no |
| <a name="input_stockholm_legacy_vpc"></a> [stockholm\_legacy\_vpc](#input\_stockholm\_legacy\_vpc) | Information about the Legacy VPC to create in us-west-2. | `any` | <pre>{<br>  "cidr_block": "10.12.0.0/16",<br>  "endpoint_subnet_cidrs": [<br>    "10.12.3.0/28",<br>    "10.12.3.16/28",<br>    "10.12.3.32/28"<br>  ],<br>  "instance_type": "t3.micro",<br>  "name": "legacy-us-west-2",<br>  "number_azs": 2,<br>  "tgw_subnet_cidrs": [<br>    "10.12.3.48/28",<br>    "10.12.3.64/28",<br>    "10.12.3.80/28"<br>  ],<br>  "workload_subnet_cidrs": [<br>    "10.12.0.0/24",<br>    "10.12.1.0/24",<br>    "10.12.2.0/24"<br>  ]<br>}</pre> | no |
| <a name="input_stockholm_spoke_vpcs"></a> [stockholm\_spoke\_vpcs](#input\_stockholm\_spoke\_vpcs) | Information about the VPCs to create in eu-north-1. | `any` | <pre>{<br>  "non-prod": {<br>    "cidr_block": "10.11.0.0/16",<br>    "cnetwork_subnet_cidrs": [<br>      "10.11.3.48/28",<br>      "10.11.3.64/28",<br>      "10.11.3.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.11.3.0/28",<br>      "10.11.3.16/28",<br>      "10.11.3.32/28"<br>    ],<br>    "instance_type": "t3.micro",<br>    "name": "non-prod-eu-north-1",<br>    "number_azs": 2,<br>    "type": "nonprod",<br>    "workload_subnet_cidrs": [<br>      "10.11.0.0/24",<br>      "10.11.1.0/24",<br>      "10.11.2.0/24"<br>    ]<br>  },<br>  "prod": {<br>    "cidr_block": "10.10.0.0/16",<br>    "cnetwork_subnet_cidrs": [<br>      "10.10.3.48/28",<br>      "10.10.3.64/28",<br>      "10.10.3.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.10.3.0/28",<br>      "10.10.3.16/28",<br>      "10.10.3.32/28"<br>    ],<br>    "instance_type": "t3.micro",<br>    "name": "prod-eu-north-1",<br>    "number_azs": 2,<br>    "type": "prod",<br>    "workload_subnet_cidrs": [<br>      "10.10.0.0/24",<br>      "10.10.1.0/24",<br>      "10.10.2.0/24"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | Transit Gateway ASNs. | `map(number)` | <pre>{<br>  "oregon": 64515,<br>  "stockholm": 64516<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_wan"></a> [cloud\_wan](#output\_cloud\_wan) | AWS Cloud WAN resources. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | AWS Transit Gateway resources. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->
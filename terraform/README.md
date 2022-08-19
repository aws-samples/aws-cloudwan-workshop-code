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
* Modify *variables.tf* and *locals.tf* in the project root directory if there are any changes needed to the VPCs/Subnets/Security Groups/VPC Endpoints related configuration. The defaults would create required VPCs and other resources in **us-east-1** and **eu-west-1** AWS Regions.
* The initial Core Network Policy is specified in `cloudwan_policy.tf`. This would be the default initial policy with attachments that would be used when the Core Network is created.
* Initialize Terraform using `terraform init`.
* Now you can deploy the rest of the infrastructure using `terraform apply`.
* Once the deployment is finished, you can check in the [AWS Cloud WAN management console](https://us-west-2.console.aws.amazon.com/networkmanager/home) that the Spoke VPC production attachments require acceptance. In the `main.tf` file you will find commented the piece of code needed to accept those attachments.
* Please make a note of the outputs giving you the Cloud WAN VPC attachments for the Inspection VPCs - `cloud_wan.attachments.{aws_region}.inspection` - as this will be needed for next run`.

## Updating Core Network Policy for Routing

**NOTE**: this configuration step is an MPV design, we are working on removing the need of this update and have everything working in the same `terraform apply`.

* After the entire infrastructure stack gets created, to facilitate Routing and to enable communication between attachments, the Routing configuration has to be updated.
* This would be a manual step to update the `core\_nw\_policy` in `cloudwan\_policy.tf` and will soon be automated and baked into the original apply process.
* Based on the Outputs received in prior run, please update the policy document below and do `terraform apply` again.

````hcl
data "aws_networkmanager_core_network_policy_document" "core_nw_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64512-64555"]
    edge_locations {
      location = "ap-southeast-1"
      asn      = 64512
    }
    edge_locations {
      location = "ap-southeast-2"
      asn      = 64513
    }
  }
  segments {
    name                          = "shared"
    description                   = "Segment for shared services"
    require_attachment_acceptance = false
  }

  segments {
    name                          = "prod"
    description                   = "Segment for prod services"
    require_attachment_acceptance = false
  }

  segments {
    name                          = "nonprod"
    description                   = "Segment for nonprod services"
    require_attachment_acceptance = false
  }

  segment_actions {
    action  = "create-route"
    segment = "prod"
    destination_cidr_blocks = [
      "0.0.0.0/0"
    ]
    destinations = [
      ***INSERT_OUTPUTS_FROM_PREVIOUS_APPLY***
    ]
  }
  segment_actions {
    action  = "create-route"
    segment = "nonprod"
    destination_cidr_blocks = [
      "0.0.0.0/0"
    ]
    destinations = [
      ***INSERT_OUTPUTS_FROM_PREVIOUS_APPLY***
    ]
  }
  segment_actions {
    action     = "share"
    mode       = "attachment-route"
    segment    = "shared"
    share_with = ["*"]
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"
    conditions {
      type = "tag-exists"
      key  = "prod"
    }
    action {
      association_method = "constant"
      segment            = "prod"
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"
    conditions {
      type = "tag-exists"
      key  = "nonprod"
    }
    action {
      association_method = "constant"
      segment            = "nonprod"
    }
  }

  attachment_policies {
    rule_number     = 300
    condition_logic = "or"
    conditions {
      type = "tag-exists"
      key  = "shared"
    }
    action {
      association_method = "constant"
      segment            = "shared"
    }
  }
}
```

## References

* [AWS Cloud WAN documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/what-is-cloudwan.html).
* [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).
* Blog post: [Introducing AWS Cloud WAN (Preview)](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-aws-cloud-wan-preview/).

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.27.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.25.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.27.0 |
| <a name="provider_aws.awsireland"></a> [aws.awsireland](#provider\_aws.awsireland) | 4.27.0 |
| <a name="provider_aws.awsnvirginia"></a> [aws.awsnvirginia](#provider\_aws.awsnvirginia) | 4.27.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_anfw_ireland"></a> [anfw\_ireland](#module\_anfw\_ireland) | aws-ia/networkfirewall/aws | 0.0.1 |
| <a name="module_anfw_nvirginia"></a> [anfw\_nvirginia](#module\_anfw\_nvirginia) | aws-ia/networkfirewall/aws | 0.0.1 |
| <a name="module_cloudwan"></a> [cloudwan](#module\_cloudwan) | aws-ia/cloudwan/aws | = 0.0.6 |
| <a name="module_compute_ireland"></a> [compute\_ireland](#module\_compute\_ireland) | ./modules/compute | n/a |
| <a name="module_compute_nvirginia"></a> [compute\_nvirginia](#module\_compute\_nvirginia) | ./modules/compute | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_ireland_inspection_cwattachment"></a> [ireland\_inspection\_cwattachment](#module\_ireland\_inspection\_cwattachment) | ./modules/cloudwan_attachment | n/a |
| <a name="module_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#module\_ireland\_inspection\_vpc) | aws-ia/vpc/aws | = 2.4.0 |
| <a name="module_ireland_spoke_cwattachments"></a> [ireland\_spoke\_cwattachments](#module\_ireland\_spoke\_cwattachments) | ./modules/cloudwan_attachment | n/a |
| <a name="module_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#module\_ireland\_spoke\_vpcs) | aws-ia/vpc/aws | = 2.4.0 |
| <a name="module_kms_ireland"></a> [kms\_ireland](#module\_kms\_ireland) | ./modules/kms | n/a |
| <a name="module_kms_nvirginia"></a> [kms\_nvirginia](#module\_kms\_nvirginia) | ./modules/kms | n/a |
| <a name="module_nvirginia_inspection_cwattachment"></a> [nvirginia\_inspection\_cwattachment](#module\_nvirginia\_inspection\_cwattachment) | ./modules/cloudwan_attachment | n/a |
| <a name="module_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#module\_nvirginia\_inspection\_vpc) | aws-ia/vpc/aws | = 2.4.0 |
| <a name="module_nvirginia_spoke_cwattachments"></a> [nvirginia\_spoke\_cwattachments](#module\_nvirginia\_spoke\_cwattachments) | ./modules/cloudwan_attachment | n/a |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#module\_nvirginia\_spoke\_vpcs) | aws-ia/vpc/aws | = 2.4.0 |
| <a name="module_vpc_endpoints_ireland"></a> [vpc\_endpoints\_ireland](#module\_vpc\_endpoints\_ireland) | ./modules/vpc_endpoints | n/a |
| <a name="module_vpc_endpoints_nvirginia"></a> [vpc\_endpoints\_nvirginia](#module\_vpc\_endpoints\_nvirginia) | ./modules/vpc_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_networkfirewall_firewall_policy.ireland_fwpolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_firewall_policy.nvirginia_fwpolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_ireland](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_nvirginia](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_ireland](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_nvirginia](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkmanager_core_network_policy_document.core_nw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS regions to spin up resources. | `map(string)` | <pre>{<br>  "ireland": "eu-west-1",<br>  "north_virginia": "us-east-1"<br>}</pre> | no |
| <a name="input_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#input\_ireland\_inspection\_vpc) | Information about the Inspection VPC to create in eu-west-1. | `any` | <pre>{<br>  "cidr_block": "100.64.0.0/16",<br>  "cwan_subnet_cidrs": [<br>    "100.64.0.64/28",<br>    "100.64.0.80/28"<br>  ],<br>  "inspection_subnet_cidrs": [<br>    "100.64.0.32/28",<br>    "100.64.0.48/28"<br>  ],<br>  "name": "inspection-eu-west-1",<br>  "number_azs": 2,<br>  "public_subnet_cidrs": [<br>    "100.64.0.0/28",<br>    "100.64.0.16/28"<br>  ]<br>}</pre> | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#input\_ireland\_spoke\_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br>  "non-prod": {<br>    "cidr_block": "10.11.0.0/24",<br>    "cwan_subnet_cidrs": [<br>      "10.11.0.64/28",<br>      "10.11.0.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.11.0.0/28",<br>      "10.11.0.16/28"<br>    ],<br>    "instance_type": "t2.micro",<br>    "name": "non-prod-eu-west-1",<br>    "number_azs": 2,<br>    "private_subnet_cidrs": [<br>      "10.11.0.32/28",<br>      "10.11.0.48/28"<br>    ],<br>    "type": "nonprod"<br>  },<br>  "prod": {<br>    "cidr_block": "10.1.0.0/24",<br>    "cwan_subnet_cidrs": [<br>      "10.1.0.64/28",<br>      "10.1.0.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.1.0.0/28",<br>      "10.1.0.16/28"<br>    ],<br>    "instance_type": "t2.micro",<br>    "name": "prod-eu-west-1",<br>    "number_azs": 2,<br>    "private_subnet_cidrs": [<br>      "10.1.0.32/28",<br>      "10.1.0.48/28"<br>    ],<br>    "type": "prod"<br>  }<br>}</pre> | no |
| <a name="input_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#input\_nvirginia\_inspection\_vpc) | Information about the Inspection VPC to create in us-east-1. | `any` | <pre>{<br>  "cidr_block": "100.64.0.0/24",<br>  "cwan_subnet_cidrs": [<br>    "100.64.0.64/28",<br>    "100.64.0.80/28"<br>  ],<br>  "inspection_subnet_cidrs": [<br>    "100.64.0.32/28",<br>    "100.64.0.48/28"<br>  ],<br>  "name": "inspection-us-east-1",<br>  "number_azs": 2,<br>  "public_subnet_cidrs": [<br>    "100.64.0.0/28",<br>    "100.64.0.16/28"<br>  ]<br>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#input\_nvirginia\_spoke\_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br>  "non-prod": {<br>    "cidr_block": "10.10.0.0/24",<br>    "cwan_subnet_cidrs": [<br>      "10.10.0.64/28",<br>      "10.10.0.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.10.0.0/28",<br>      "10.10.0.16/28"<br>    ],<br>    "instance_type": "t2.micro",<br>    "name": "non-prod-us-east-1",<br>    "number_azs": 2,<br>    "private_subnet_cidrs": [<br>      "10.10.0.32/28",<br>      "10.10.0.48/28"<br>    ],<br>    "type": "nonprod"<br>  },<br>  "prod": {<br>    "cidr_block": "10.0.0.0/24",<br>    "cwan_subnet_cidrs": [<br>      "10.0.0.64/28",<br>      "10.0.0.80/28"<br>    ],<br>    "endpoint_subnet_cidrs": [<br>      "10.0.0.0/28",<br>      "10.0.0.16/28"<br>    ],<br>    "instance_type": "t2.micro",<br>    "name": "prod-us-east-1",<br>    "number_azs": 2,<br>    "private_subnet_cidrs": [<br>      "10.0.0.32/28",<br>      "10.0.0.48/28"<br>    ],<br>    "type": "prod"<br>  }<br>}</pre> | no |
| <a name="input_project_identifier"></a> [project\_identifier](#input\_project\_identifier) | Project Identifier. | `string` | `"CloudWAN_Workshop"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_wan"></a> [cloud\_wan](#output\_cloud\_wan) | AWS Cloud WAN resources. |
| <a name="output_ec2_instances"></a> [ec2\_instances](#output\_ec2\_instances) | List of EC2 instances created. |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | VPC endpoints created. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->
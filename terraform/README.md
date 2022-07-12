<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN - Terraform

AWS Cloud WAN is a managed wide-area networking (WAN) service that you can use to build, manage, and monitor an unified global network that connects resources running across your cloud and on-premises environments. It provides a central dashboard from which you can connect on-premises branch offices, data centers, and Amazon Virtual Private Clouds (VPCs) across the AWS global network. You can use simple network policies to centrally configure and automate network management and security tasks, and get a complete view of your global network.

This repository shows you an example in Terraform of global communication with AWS Cloud WAN, showing the same architecture you can build in the [AWS Cloud WAN Workshop](https://catalog.workshops.aws/cloudwan/en-US).

![architecture diagram](../images/cloud_wan_architecture.png "AWS Cloud WAN diagram")

**NOTE**: The resources created incur costs in your AWS Account. Consider deleting the resources created once your tests are done. For more information, check the [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/).

## Pre Requisites

* An AWS account with an IAM user that has appropriate permissions
* Terraform installed

## Deployment instructions

* Clone the repository
* Modify *variables.tf*, *singapore_locals.tf* and *sydney_locals.tf* in the project root directory if there are any changes needed to the VPCs/Subnets/Security Groups/VPC Endpoints related configuration. The defaults would create required VPCs and other resources in **ap-southeast-1** and Sydney **ap-southeast-2** regions.
* The initial Network Policy for Core Network is specified in `data.tf`. This would be the default initial policy with attachments that would be used when the Core Network is created.
* Initialize Terraform using `terraform init`.
* Now you can deploy the rest of the infrastructure using `terraform apply`.
* Please make a note of outputs `core_nw_attachments_egress_singapore` and `core_nw_attachments_egress_sydney` as this will be needed for next run.

**Warning:** If you get any error when creating the VPC routes: *Error: error creating Route in Route Table (rtb-XXXX) with destination (0.0.0.0/0): InvalidCoreNetworkArn.NotFound: The core network arn 'arn:aws:networkmanager::XXXXXX:core-network/core-network-XXXXX' does not exist.*. Don't worry, you may need to accept the VPC attachment from the Cloud WAN console. Once this attachment is accepted and created, do `terraform apply` again and the VPC routes will be created.

## Updating Core Network Policy for Routing

**NOTE**: this configuration step is an MPV design, we are working on removing the need of this update and have everything working in the same `terraform apply`.

* After the entire infrastructure stack gets created, to facilitate Routing and to enable communication between attachments, the Routing configuration has to be updated.
* This would be a manual step to update the `core_nw_policy` in `data.tf` and will soon be automated and baked into the original apply process.
* Based on the Outputs received in prior run, please update the policy document below and do `terraform apply` again.

```hcl
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.16.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.25.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwan"></a> [cloudwan](#module\_cloudwan) | aws-ia/cloudwan/aws | >= 0.0.6 |
| <a name="module_cwan_components_singapore"></a> [cwan\_components\_singapore](#module\_cwan\_components\_singapore) | ./modules/cwan_components | n/a |
| <a name="module_cwan_components_sydney"></a> [cwan\_components\_sydney](#module\_cwan\_components\_sydney) | ./modules/cwan_components | n/a |
| <a name="module_singapore_vpcs"></a> [singapore\_vpcs](#module\_singapore\_vpcs) | aws-ia/vpc/aws | >= 1.0.0 |
| <a name="module_sydney_vpcs"></a> [sydney\_vpcs](#module\_sydney\_vpcs) | aws-ia/vpc/aws | >= 1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_networkmanager_core_network_policy_document.core_nw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_singapore_region"></a> [aws\_singapore\_region](#input\_aws\_singapore\_region) | Singapore region code | `string` | `"ap-southeast-1"` | no |
| <a name="input_aws_sydney_region"></a> [aws\_sydney\_region](#input\_aws\_sydney\_region) | Sydney region code | `string` | `"ap-southeast-2"` | no |
| <a name="input_deploy_singapore_region"></a> [deploy\_singapore\_region](#input\_deploy\_singapore\_region) | Singapore region | `string` | `"singapore"` | no |
| <a name="input_deploy_sydney_region"></a> [deploy\_sydney\_region](#input\_deploy\_sydney\_region) | Sydney region | `string` | `"sydney"` | no |
| <a name="input_ec2_instance_type"></a> [ec2\_instance\_type](#input\_ec2\_instance\_type) | EC2 instance type for the test nodes | `string` | `"t3.nano"` | no |
| <a name="input_number_azs"></a> [number\_azs](#input\_number\_azs) | Number of Availability Zones to use. | `number` | `2` | no |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | `"CloudWAN_Workshop"` | no |
| <a name="input_singapore_public_subnets_info"></a> [singapore\_public\_subnets\_info](#input\_singapore\_public\_subnets\_info) | Public Subnets information to be deployed in ap-southeast-1 region | `any` | <pre>[<br>  {<br>    "availability_zone": "ap-southeast-1a",<br>    "cidr_block": "100.64.1.0/24"<br>  },<br>  {<br>    "availability_zone": "ap-southeast-1b",<br>    "cidr_block": "100.64.3.0/24"<br>  }<br>]</pre> | no |
| <a name="input_singapore_vpcs"></a> [singapore\_vpcs](#input\_singapore\_vpcs) | VPCs information that will be deployed in ap-southeast-1 region | `any` | <pre>{<br>  "egress-vpc": {<br>    "cidr_block": "100.64.0.0/16",<br>    "name": "egress-vpc",<br>    "private_subnets": [<br>      "100.64.0.0/24",<br>      "100.64.2.0/24"<br>    ],<br>    "type": "prod"<br>  },<br>  "nonprod-vpc": {<br>    "cidr_block": "10.11.0.0/16",<br>    "name": "nonprod-vpc",<br>    "private_subnets": [<br>      "10.11.0.0/24",<br>      "10.11.2.0/24"<br>    ],<br>    "type": "non-prod"<br>  },<br>  "prod-vpc": {<br>    "cidr_block": "10.10.0.0/16",<br>    "name": "prod-vpc",<br>    "private_subnets": [<br>      "10.10.1.0/24",<br>      "10.10.2.0/24"<br>    ],<br>    "type": "prod"<br>  }<br>}</pre> | no |
| <a name="input_sydney_public_subnets_info"></a> [sydney\_public\_subnets\_info](#input\_sydney\_public\_subnets\_info) | Public Subnets information to be deployed in ap-southeast-2 region | `any` | <pre>[<br>  {<br>    "availability_zone": "ap-southeast-2a",<br>    "cidr_block": "100.64.1.0/24"<br>  },<br>  {<br>    "availability_zone": "ap-southeast-2b",<br>    "cidr_block": "100.64.3.0/24"<br>  }<br>]</pre> | no |
| <a name="input_sydney_vpcs"></a> [sydney\_vpcs](#input\_sydney\_vpcs) | VPCs information that will be deployed in ap-southeast-2 region | `any` | <pre>{<br>  "egress-vpc": {<br>    "cidr_block": "100.64.0.0/16",<br>    "name": "egress-vpc",<br>    "private_subnets": [<br>      "100.64.0.0/24",<br>      "100.64.2.0/24"<br>    ],<br>    "type": "prod"<br>  },<br>  "nonprod-vpc": {<br>    "cidr_block": "10.1.0.0/16",<br>    "name": "nonprod-vpc",<br>    "private_subnets": [<br>      "10.1.0.0/24",<br>      "10.1.2.0/24"<br>    ],<br>    "type": "non-prod"<br>  },<br>  "prod-vpc": {<br>    "cidr_block": "10.0.0.0/16",<br>    "name": "prod-vpc",<br>    "private_subnets": [<br>      "10.0.1.0/24",<br>      "10.0.2.0/24"<br>    ],<br>    "type": "prod"<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_core_nw_attachments_egress_singapore"></a> [core\_nw\_attachments\_egress\_singapore](#output\_core\_nw\_attachments\_egress\_singapore) | n/a |
| <a name="output_core_nw_attachments_egress_sydney"></a> [core\_nw\_attachments\_egress\_sydney](#output\_core\_nw\_attachments\_egress\_sydney) | n/a |
<!-- END_TF_DOCS -->
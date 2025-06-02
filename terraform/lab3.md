# AWS Cloud WAN - Terraform / Lab 3 - Additional inspection scenarios

As Lab 3 in the workshop requires some deletion of resources, we prefer to provide detailed instructions on what to change in the provided repo rather than complicating the code itself.

## 1 - Update Core Network policy

1. Create a new policy document under `cloudwan_policy.tf`:

```hcl
data "aws_networkmanager_core_network_policy_document" "lab3_core_nw_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65534"]

    edge_locations { location = var.aws_regions.oregon }
    edge_locations { location = var.aws_regions.stockholm }
  }

  segments {
    name = "prod"
    edge_locations = [
      var.aws_regions.oregon,
      var.aws_regions.stockholm
    ]
    require_attachment_acceptance = true
    isolate_attachments           = false
  }

  segments {
    name = "thirdparty"
    edge_locations = [
      var.aws_regions.oregon,
      var.aws_regions.stockholm
    ]
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  segments {
    name = "onpremises"
  }

  segments {
    name = "legacy"
    edge_locations = [
      var.aws_regions.oregon,
      var.aws_regions.stockholm
    ]
    require_attachment_acceptance = false
  }

  network_function_groups {
    name                          = "EgressInspectionVpcs"
    require_attachment_acceptance = false
  }

  network_function_groups {
    name                          = "InspectionVpcs"
    require_attachment_acceptance = false
  }

  segment_actions {
    action     = "share"
    mode       = "attachment-route"
    segment    = "legacy"
    share_with = ["prod"]
  }

  segment_actions {
    action  = "send-to"
    segment = "prod"

    via {
      network_function_groups = ["EgressInspectionVpcs"]
    }
  }

  segment_actions {
    action  = "send-to"
    segment = "thirdparty"

    via {
      network_function_groups = ["EgressInspectionVpcs"]
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "thirdparty"
    mode    = "single-hop"

    when_sent_to {
      segments = ["prod"]
    }

    via {
      network_function_groups = ["EgressInspectionVpcs"]
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "prod"
    mode    = "single-hop"

    when_sent_to {
      segments = ["onpremises"]
    }

    via {
      network_function_groups = ["EgressInspectionVpcs"]
      with_edge_override {
        edge_sets         = [["us-west-2", "eu-north-1"]]
        use_edge_location = "eu-north-1"
      }
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "thirdparty"
    mode    = "single-hop"

    via {
      network_function_groups = ["EgressInspectionVpcs"]
      with_edge_override {
        edge_sets         = [["us-west-2", "eu-north-1"]]
        use_edge_location = "eu-north-1"
      }
    }
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "nfg"
      value    = "inspection"
    }
    action {
      add_to_network_function_group = "InspectionVpcs"
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "nfg"
      value    = "egressinspection"
    }
    action {
      add_to_network_function_group = "EgressInspectionVpcs"
    }
  }

  attachment_policies {
    rule_number     = 300
    condition_logic = "or"

    conditions {
      type = "tag-exists"
      key  = "domain"
    }
    action {
      association_method = "tag"
      tag_value_of_key   = "domain"
    }
  }

  attachment_policies {
    rule_number     = 400
    condition_logic = "or"
    conditions {
      type     = "attachment-type"
      operator = "equals"
      value    = "transit-gateway-route-table"
    }
    action {
      association_method = "constant"
      segment            = "legacy"
    }
  }
}
```

2. With the new policy document defined, update the Core Network policy (`main.tf` - line 17) with the new version:

```hcl
module "cloud_wan" {
  source  = "aws-ia/cloudwan/aws"
  version = "3.3.0"

  global_network = { description = "Global Network - ${var.project_identifier}" }

  core_network = {
    description     = "Core Network - ${var.project_identifier}"
    policy_document = data.aws_networkmanager_core_network_policy_document.lab3_core_nw_policy.json
  }
}
```

3. Enable routing to the on-premises environment at the Egress VPC by updating the firewall subnet route tables.

As the VPC module used admits either a CIDR block or a [managed prefix list](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-aws-managed-prefix-lists.html) (for multiple blocks), we will need to add the following code - we recommend to add the new code in a new file `prefix.tf`:

```hcl
resource "aws_ec2_managed_prefix_list" "oregon_prefix_list" {
  provider = aws.awsoregon

  name           = "Oregon - Egress CIDRs"
  address_family = "IPv4"
  max_entries    = 2

  entry {
    cidr        = "10.0.0.0/8"
    description = "AWS environment"
  }

  entry {
    cidr        = "192.168.100.0/24"
    description = "On-premises environment"
  }
}

resource "aws_ec2_managed_prefix_list" "stockholm_prefix_list" {
  provider = aws.awsstockholm

  name           = "Stockholm - Egress CIDRs"
  address_family = "IPv4"
  max_entries    = 2

  entry {
    cidr        = "10.0.0.0/8"
    description = "AWS environment"
  }

  entry {
    cidr        = "192.168.100.0/24"
    description = "On-premises environment"
  }
}
```

Update the Egress VPC definitions to use the managed prefix lists created (`main.tf` - lines 135 and 302):

```hcl
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
    inspection = aws_ec2_managed_prefix_list.oregon_prefix_list.id
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
```

```hcl
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
    inspection = aws_ec2_managed_prefix_list.stockholm_prefix_list.id
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
```

3. Deploy using `terraform apply`. Once deployed, you can test following the [workshop guide](https://catalog.workshops.aws/cloudwan/en-US/3-labs/lab3/step-3).

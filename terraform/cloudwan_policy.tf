# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/cloudwan_policy.tf ---

# AWS Cloud WAN Core Network Policy
data "aws_networkmanager_core_network_policy_document" "core_nw_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64512-64555"]

    edge_locations {
      location = "us-east-1"
      asn      = 64512
    }
    edge_locations {
      location = "eu-west-1"
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
    require_attachment_acceptance = true
  }

  segments {
    name                          = "nonprod"
    description                   = "Segment for non-prod services"
    require_attachment_acceptance = false
  }

  # segment_actions {
  #   action  = "create-route"
  #   segment = "prod"
  #   destination_cidr_blocks = [
  #     "0.0.0.0/0"
  #   ]
  #   destinations = [
  #     ***INSERT_OUTPUTS_FROM_PREVIOUS_APPLY***
  #   ]
  # }
  # segment_actions {
  #   action  = "create-route"
  #   segment = "nonprod"
  #   destination_cidr_blocks = [
  #     "0.0.0.0/0"
  #   ]
  #   destinations = [
  #     ***INSERT_OUTPUTS_FROM_PREVIOUS_APPLY***
  #   ]
  # }

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
      type     = "tag-value"
      operator = "equals"
      key      = "env"
      value    = "nonprod"
    }
    action {
      association_method = "constant"
      segment            = "nonprod"
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "env"
      value    = "prod"
    }
    action {
      association_method = "constant"
      segment            = "prod"
    }
  }

  attachment_policies {
    rule_number     = 300
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "env"
      value    = "inspection"
    }
    action {
      association_method = "constant"
      segment            = "shared"
    }
  }
}


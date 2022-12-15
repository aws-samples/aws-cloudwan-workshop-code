# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/cloudwan_policy.tf ---

# AWS Cloud WAN Core Network Policy
data "aws_networkmanager_core_network_policy_document" "core_nw_policy" {
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
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  segments {
    name = "nonprod"
    edge_locations = [
      var.aws_regions.oregon,
      var.aws_regions.stockholm
    ]
    require_attachment_acceptance = false
  }

  segments {
    name = "sharedservices"
  }

  # segments {
  #   name = "legacy"
  #   edge_locations = [
  #     var.aws_regions.oregon,
  #     var.aws_regions.stockholm
  #   ]
  #   require_attachment_acceptance = false
  # }

  # attachment_policies {
  #   rule_number     = 100
  #   condition_logic = "or"

  #   conditions {
  #     type = "tag-exists"
  #     key  = "prod"
  #   }
  #   action {
  #     association_method = "constant"
  #     segment            = "prod"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 200
  #   condition_logic = "or"

  #   conditions {
  #     type = "tag-exists"
  #     key  = "nonprod"
  #   }
  #   action {
  #     association_method = "constant"
  #     segment            = "nonprod"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 300
  #   condition_logic = "or"

  #   conditions {
  #     type = "tag-exists"
  #     key  = "sharedservices"
  #   }
  #   action {
  #     association_method = "constant"
  #     segment            = "sharedservices"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 400
  #   condition_logic = "or"

  #   conditions {
  #     type = "tag-exists"
  #     key  = "legacy"
  #   }
  #   action {
  #     association_method = "constant"
  #     segment            = "legacy"
  #   }
  # }

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

  # segment_actions {
  #   action     = "share"
  #   mode       = "attachment-route"
  #   segment    = "sharedservices"
  #   share_with = ["*"]
  # }

  # segment_actions {
  #   action  = "share"
  #   mode    = "attachment-route"
  #   segment = "legacy"
  #   share_with = [
  #     "prod",
  #     "nonprod"
  #   ]
  # }
}


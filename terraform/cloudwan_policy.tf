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

  # segments {
  #   name = "legacy"
  #   edge_locations = [
  #     var.aws_regions.oregon,
  #     var.aws_regions.stockholm
  #   ]
  #   require_attachment_acceptance = false
  # }

  network_function_groups {
    name                          = "EgressInspectionVpcs"
    require_attachment_acceptance = false
  }

  network_function_groups {
    name                          = "InspectionVpcs"
    require_attachment_acceptance = false
  }

  # segment_actions {
  #   action     = "share"
  #   mode       = "attachment-route"
  #   segment    = "onpremises"
  #   share_with = ["prod"]
  # }

  # segment_actions {
  #   action     = "share"
  #   mode       = "attachment-route"
  #   segment    = "legacy"
  #   share_with = ["prod"]
  # }

  # segment_actions {
  #   action  = "send-to"
  #   segment = "prod"

  #   via {
  #     network_function_groups = ["EgressInspectionVpcs"]
  #   }
  # }

  # segment_actions {
  #   action  = "send-to"
  #   segment = "thirdparty"

  #   via {
  #     network_function_groups = ["EgressInspectionVpcs"]
  #   }
  # }

  # segment_actions {
  #   action  = "send-via"
  #   segment = "thirdparty"
  #   mode    = "dual-hop"

  #   when_sent_to {
  #     segments = ["prod"]
  #   }

  #   via {
  #     network_function_groups = ["InspectionVpcs"]
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 100
  #   condition_logic = "or"

  #   conditions {
  #     type     = "tag-value"
  #     operator = "equals"
  #     key      = "nfg"
  #     value    = "inspection"
  #   }
  #   action {
  #     add_to_network_function_group = "InspectionVpcs"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 200
  #   condition_logic = "or"

  #   conditions {
  #     type     = "tag-value"
  #     operator = "equals"
  #     key      = "nfg"
  #     value    = "egressinspection"
  #   }
  #   action {
  #     add_to_network_function_group = "EgressInspectionVpcs"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 300
  #   condition_logic = "or"

  #   conditions {
  #     type = "tag-exists"
  #     key  = "domain"
  #   }
  #   action {
  #     association_method = "tag"
  #     tag_value_of_key   = "domain"
  #   }
  # }

  # attachment_policies {
  #   rule_number     = 400
  #   condition_logic = "or"
  #   conditions {
  #     type     = "attachment-type"
  #     operator = "equals"
  #     value    = "transit-gateway-route-table"
  #   }
  #   action {
  #     association_method = "constant"
  #     segment            = "legacy"
  #   }
  # }
}


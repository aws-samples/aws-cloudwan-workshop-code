# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/network_firewall.tf ---

resource "aws_networkfirewall_firewall" "egress_vpc_fw" {
  #Create AWS Network Firewall with the subnets mapped to Network Firewall VPC
  name                = "aws-network-firewall-cloudwan"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.egress_vpc_fw_policy.arn
  vpc_id              = var.network_firewall_vpc

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall_subnets[*].id

    content {
      subnet_id = subnet_mapping.value
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "egress_vpc_fw_policy" {
  #Network Firewall Policy to forward non-matching packets/fragmented UDP packets for stateful inspection
  name = "firewall-policy-cloudwan"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful_rule_group.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "icmp_alert_stateful_rule_group" {
  #Create Network Firewall rule group to create ICMP alerts
  capacity = 100
  name     = "icmp-alert"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          direction        = "ANY"
          protocol         = "ICMP"
          destination      = "ANY"
          source           = "ANY"
          destination_port = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }

}

resource "aws_networkfirewall_rule_group" "domain_allow_stateful_rule_group" {
  capacity = 100
  name     = "domain-allow"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["10.0.0.0/8"]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".amazon.com"]
      }
    }
  }

}
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/firewall_policy/main.tf ---

data "aws_region" "current" {}

# Firewall Policy (Egress firewall)
resource "aws_networkfirewall_firewall_policy" "egress_fwpolicy" {
  name = "firewall-policy-egress-${data.aws_region.current.name}"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.drop_remote_stateless_rule_group.arn
      priority     = 1
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_allow_alert_stateful_rule_group.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful_rule_group.arn
    }
  }
}

# Firewall Policy (East-West firewall)
resource "aws_networkfirewall_firewall_policy" "eastwest_fwpolicy" {
  name = "firewall-policy-eastwest-${data.aws_region.current.name}"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.drop_remote_stateless_rule_group.arn
      priority     = 1
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_allow_alert_stateful_rule_group.arn
    }
  }
}

# Stateless Rule Group (Drop SSH)
resource "aws_networkfirewall_rule_group" "drop_remote_stateless_rule_group" {
  capacity = 10
  name     = "drop-remote"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }
      }
    }
  }
}

# Stateful Rule Group
resource "aws_networkfirewall_rule_group" "domain_allow_stateful_rule_group" {
  capacity = 50
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

resource "aws_networkfirewall_rule_group" "icmp_allow_alert_stateful_rule_group" {
  capacity = 100
  name     = "icmp-allow-alert"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
        alert icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Alert on ICMP traffic between/within Prod and Third Party VPCs"; sid:199407051; rev:1;)
        pass icmp 10.0.0.0/8 any -> 10.0.0.0/8 any (msg:"Allow ICMP traffic between/within Prod and Third Party VPCs"; sid:199407052; rev:1;)
        alert icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Alert on ICMP traffic from Prod/Third Party to On-Premises"; sid:199407053; rev:1;)
        pass icmp 10.0.0.0/8 any -> 192.168.100.0/24 any (msg:"Allow ICMP traffic from Prod/Third Party to On-Premises"; sid:199407054; rev:1;)
      EOF
    }
  }
}
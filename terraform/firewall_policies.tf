# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/firewall_policies.tf ---

# Firewall Policy to apply in N. Virginia (us-east-1)
resource "aws_networkfirewall_firewall_policy" "oregon_fwpolicy" {
  provider = aws.awsoregon

  name = "firewall-policy-cloudwan"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_oregon.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_oregon.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "icmp_alert_stateful_rule_group_oregon" {
  provider = aws.awsoregon

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

resource "aws_networkfirewall_rule_group" "domain_allow_stateful_rule_group_oregon" {
  provider = aws.awsoregon

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

# Firewall Policy to apply in Stockholm (eu-north-1)
resource "aws_networkfirewall_firewall_policy" "stockholm_fwpolicy" {
  provider = aws.awsstockholm

  name = "firewall-policy-cloudwan"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group_stockholm.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful_rule_group_stockholm.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "icmp_alert_stateful_rule_group_stockholm" {
  provider = aws.awsstockholm

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

resource "aws_networkfirewall_rule_group" "domain_allow_stateful_rule_group_stockholm" {
  provider = aws.awsstockholm

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
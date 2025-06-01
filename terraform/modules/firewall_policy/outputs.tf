# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/firewall_policy/outputs.tf ---

output "egress_policy_arn" {
  description = "Network Firewall policy (Egress)"
  value       = aws_networkfirewall_firewall_policy.egress_fwpolicy.arn
}

output "eastwest_policy_arn" {
  description = "Network Firewall policy (East-West)"
  value       = aws_networkfirewall_firewall_policy.eastwest_fwpolicy.arn
}
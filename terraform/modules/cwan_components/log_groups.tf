# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/log_groups.tf ---

resource "aws_kms_key" "cloudwan_kms" {
  description = "This key is used to encrypt Egress VPC Firewall Log flow and alert groups"
  policy      = data.aws_iam_policy_document.cw_log_group_kms_policy.json
}

resource "aws_cloudwatch_log_group" "egress_vpc_firewall_log_flow_group" {
  #Log group for Egress VPCs to capture Flow information
  name              = format("%s/%s", "/anfw/flow", var.deployment_region)
  retention_in_days = 1
  kms_key_id        = aws_kms_key.cloudwan_kms.arn

}
resource "aws_cloudwatch_log_group" "egress_vpc_firewall_log_alert_group" {
  #Log group for Egress VPCs to capture Alerts information
  name              = format("%s/%s", "/anfw/alert", var.deployment_region)
  retention_in_days = 1
  kms_key_id        = aws_kms_key.cloudwan_kms.arn
}

resource "aws_networkfirewall_logging_configuration" "egress_vpc_firewall_log" {
  #Logging Configuration  for Network Firewall
  firewall_arn = aws_networkfirewall_firewall.egress_vpc_fw.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.egress_vpc_firewall_log_alert_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.egress_vpc_firewall_log_flow_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
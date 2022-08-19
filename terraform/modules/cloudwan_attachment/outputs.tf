# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cloudwan_attachment/outputs.tf ---

output "cloudwan_attachment" {
  description = "Cloud WAN Attachment."
  value       = aws_networkmanager_vpc_attachment.cwan_attachment
}
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/kms/outputs.tf ---

output "kms_arn" {
  value       = aws_kms_key.log_key.arn
  description = "ARN of the KMS key created."
}

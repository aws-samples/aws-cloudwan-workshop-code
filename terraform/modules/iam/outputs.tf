# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/iam_kms/outputs.tf ---

output "vpc_flowlog_role" {
  value       = aws_iam_role.vpc_flowlogs_role.arn
  description = "ARN of the role to use in the VPC Flow Logs to create."
}

output "ec2_iam_instance_profile" {
  value       = aws_iam_instance_profile.ec2_instance_profile.id
  description = "EC2 instance profile to use in the EC2 instace(s) to create."
}

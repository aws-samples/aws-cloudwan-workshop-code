# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/iam.tf ---

resource "aws_iam_role" "ssm_role" {
  #Create SSM role that enables an instance to use Systems Manager core service functionality
  count               = var.deploy_global_resources ? 1 : 0
  name                = "ssm_role_cloudwan_workshop"
  assume_role_policy  = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"] #Use AmazonSSMManagedInstanceCore instead of AmazonEC2RoleforSSM (will be deprecated soon)
  path                = "/"
}

resource "aws_iam_instance_profile" "ssm_role_instance_profile" {
  #Create a corresponding Instance profile to be attached to test instances
  count = var.deploy_global_resources ? 1 : 0
  name  = "ssm_instance_profile_cloudwan_workshop"
  role  = aws_iam_role.ssm_role[0].name
  depends_on = [
    aws_iam_role.ssm_role
  ]
}

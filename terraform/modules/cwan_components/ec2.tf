# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/cwan_components/ec2.tf ---

resource "aws_instance" "nonprod_instance" {
  #Test EC2 instances to validate configurations
  count = length(var.ec2_instances)

  ami                         = data.aws_ami.get_amazon_linux_2_ami.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = var.ec2_instances[count.index]["subnet_id"]
  vpc_security_group_ids      = var.ec2_instances[count.index]["vpc_security_group_ids"]
  iam_instance_profile        = var.deploy_global_resources ? aws_iam_instance_profile.ssm_role_instance_profile[0].name : "ssm_instance_profile_cloudwan_workshop"
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true
  # metadata_options {
  #   http_endpoint = "disabled"
  # }
  root_block_device {
    encrypted = true
  }
  tags = {
    Name = format("%s-%s-%s", var.ec2_instances[count.index]["ec2_name"], var.aws_region, "cloudwan")
  }

  depends_on = [
    aws_iam_role.ssm_role, aws_iam_instance_profile.ssm_role_instance_profile
  ]
}

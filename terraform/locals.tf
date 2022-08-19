/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

locals {
  north_virginia = {
    security_groups = {
      instance = {
        name        = "instance_security_group"
        description = "Instance SG (Allowing ICMP and HTTP/HTTPS access)"
        ingress = {
          icmp = {
            description = "Allowing ICMP traffic"
            from        = -1
            to          = -1
            protocol    = "icmp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
        egress = {
          any = {
            description = "Any traffic"
            from        = 0
            to          = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }

      endpoints = {
        name        = "endpoints_sg"
        description = "Security Group for SSM connection"
        ingress = {
          https = {
            description = "Allowing HTTPS"
            from        = 443
            to          = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
        egress = {
          any = {
            description = "Any traffic"
            from        = 0
            to          = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }

    endpoint_service_names = {
      ssm = {
        name        = "com.amazonaws.${var.aws_regions.north_virginia}.ssm"
        type        = "Interface"
        private_dns = true
      }
      ssmmessages = {
        name        = "com.amazonaws.${var.aws_regions.north_virginia}.ssmmessages"
        type        = "Interface"
        private_dns = true
      }
      ec2messages = {
        name        = "com.amazonaws.${var.aws_regions.north_virginia}.ec2messages"
        type        = "Interface"
        private_dns = true
      }
    }
  }

  ireland = {
    security_groups = {
      instance = {
        name        = "instance_security_group"
        description = "Instance SG (Allowing ICMP and HTTP/HTTPS access)"
        ingress = {
          icmp = {
            description = "Allowing ICMP traffic"
            from        = -1
            to          = -1
            protocol    = "icmp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
        egress = {
          any = {
            description = "Any traffic"
            from        = 0
            to          = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }

      endpoints = {
        name        = "endpoints_sg"
        description = "Security Group for SSM connection"
        ingress = {
          https = {
            description = "Allowing HTTPS"
            from        = 443
            to          = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
        egress = {
          any = {
            description = "Any traffic"
            from        = 0
            to          = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }

    endpoint_service_names = {
      ssm = {
        name        = "com.amazonaws.${var.aws_regions.ireland}.ssm"
        type        = "Interface"
        private_dns = true
      }
      ssmmessages = {
        name        = "com.amazonaws.${var.aws_regions.ireland}.ssmmessages"
        type        = "Interface"
        private_dns = true
      }
      ec2messages = {
        name        = "com.amazonaws.${var.aws_regions.ireland}.ec2messages"
        type        = "Interface"
        private_dns = true
      }
    }
  }
}



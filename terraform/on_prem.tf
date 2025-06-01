# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/on_prem.tf ---

# VPC
module "on_prem_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.4"
  providers = { aws = aws.awslondon }

  name       = "on-prem"
  cidr_block = "172.31.0.0/16"
  az_count   = 1

  subnets = {
    public = { netmask = 28 }
  }
}

# Data source for Ubuntu AMI
data "aws_ssm_parameter" "ubuntu_ami" {
  provider = aws.awslondon

  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/arm64/hvm/ebs-gp2/ami-id"
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "instance_role" {
  provider = aws.awslondon

  name = "onprem-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_ssm" {
  provider = aws.awslondon

  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for VPN connection description
resource "aws_iam_policy" "describe_vpn_connections" {
  provider = aws.awslondon

  name        = "DescribeVpnConnections"
  description = "Allow describing VPN connections"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeVpnConnections"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "vpn_policy_attachment" {
  provider = aws.awslondon

  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.describe_vpn_connections.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  provider = aws.awslondon

  name = "onprem-instance-profile"
  role = aws_iam_role.instance_role.name
}

# Security Group
resource "aws_security_group" "cgw_sg" {
  provider = aws.awslondon

  name        = "onprem-sg"
  description = "onprem"
  vpc_id      = module.on_prem_vpc.vpc_attributes.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "onprem"
  }
}

# EC2 Instance
resource "aws_instance" "cgw" {
  provider = aws.awslondon

  ami                  = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type        = "t4g.micro"
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  subnet_id              = values({ for k, v in module.on_prem_vpc.public_subnet_attributes_by_az : k => v.id })[0]
  vpc_security_group_ids = [aws_security_group.cgw_sg.id]

  tags = {
    Name = "onprem"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash -xe

    apt update
    apt -y install python3-pip
    pip3 install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz

    # Install required packages
    apt update
    apt -y install apparmor-utils frr net-tools strongswan dnsmasq

    # Configure hostname
    echo "onprem" > /etc/hostname
    hostname onprem

    # Install boto3
    pip3 install boto3

    # Configure FRR for BGP
    sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons

    # Fix strongswan apparmor issues
    aa-complain /usr/lib/ipsec/charon
    aa-complain /usr/lib/ipsec/stroke

    # Configure loopback interface
    cat > /etc/netplan/01-loopback.yaml << 'NETPLAN'
    network:
      ethernets:
          lo:
              match:
                  name: lo
              addresses:
                - 192.168.100.53/24
      version: 2
    NETPLAN

    # Apply netplan configuration
    netplan apply

    # Configure DNS
    cat > /etc/dnsmasq.d/unicornrentals.cfg << 'DNSMASQ'
    listen-address=192.168.100.53
    bind-interfaces
    auth-server=stables.unicorn.rentals
    auth-zone=stables.unicorn.rentals
    auth-soa=2021120811,hostmaster.unicorn.rentals,1200,120,604800
    auth-ttl=5
    host-record=stables.unicorn.rentals,192.168.100.80
    host-record=dns.stables.unicorn.rentals,192.168.100.53
    host-record=www.stables.unicorn.rentals,192.168.100.80
    ptr-record=53.100.168.192.in-addr.arpa,dns.stables.unicorn.rentals
    ptr-record=80.100.168.192.in-addr.arpa,www.stables.unicorn.rentals
    DNSMASQ

    # Create VPN configuration script
    cat > /usr/local/sbin/configure-vpn << 'VPNSCRIPT'
    #!/usr/bin/env python3

    import json
    import os
    import string
    import subprocess
    import sys
    import xml.etree.ElementTree

    import boto3
    import botocore

    IPSEC_CONF = string.Template("""conn %default
      leftauth=psk
      rightauth=psk
      ike=aes256-sha512-modp2048s256!
      ikelifetime=28800s
      aggressive=no
      esp=aes128-sha512-modp2048s256!
      lifetime=3600s
      type=tunnel
      dpddelay=10s
      dpdtimeout=30s
      keyexchange=ikev1
      keyingtries=%forever
      rekey=yes
      reauth=no
      dpdaction=restart
      closeaction=restart
      left=%defaultroute
      leftsubnet=0.0.0.0/0,::/0
      rightsubnet=0.0.0.0/0,::/0
      leftupdown=/etc/strongswan.d/ipsec-vti.sh
      installpolicy=yes
      compress=no
      mobike=no

    conn AWS-TUNNEL-1
      left=%any4
      right=$${tunnel_1_outside_vgw}
      auto=start
      mark=100

    conn AWS-TUNNEL-2
      left=%any4
      right=$${tunnel_2_outside_vgw}
      auto=start
      mark=200
    """)

    IPSEC_VTI_SH = string.Template("""#!/bin/bash

    IP=$$(which ip)
    IPTABLES=$$(which iptables)

    PLUTO_MARK_OUT_ARR=($$PLUTO_MARK_OUT)
    PLUTO_MARK_IN_ARR=($$PLUTO_MARK_IN)
    case "$$PLUTO_CONNECTION" in
      AWS-TUNNEL-1)
        VTI_INTERFACE=vti1
        VTI_LOCALADDR=$${tunnel_1_inside_cgw}
        VTI_REMOTEADDR=$${tunnel_1_inside_vgw}
        ;;
      AWS-TUNNEL-2)
        VTI_INTERFACE=vti2
        VTI_LOCALADDR=$${tunnel_2_inside_cgw}
        VTI_REMOTEADDR=$${tunnel_2_inside_vgw}
        ;;
    esac

    case "$$PLUTO_VERB" in
        up-client)
            $$IP link add $$VTI_INTERFACE type vti local $$PLUTO_ME \\
                remote $$PLUTO_PEER okey $$(echo $$PLUTO_MARK_OUT | cut -d'/' -f1) \\
                ikey $$(echo $$PLUTO_MARK_IN | cut -d'/' -f1)
            sysctl -w net.ipv4.conf.$$VTI_INTERFACE.disable_policy=1
            sysctl -w net.ipv4.conf.$$VTI_INTERFACE.rp_filter=2 || \\
                sysctl -w net.ipv4.conf.$$VTI_INTERFACE.rp_filter=0
            $$IP addr add $$VTI_LOCALADDR remote $$VTI_REMOTEADDR \\
                dev $$VTI_INTERFACE
            $$IP link set $$VTI_INTERFACE up mtu 1436
            $$IPTABLES -t mangle -I FORWARD -o $$VTI_INTERFACE -p tcp -m tcp \\
                --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
            $$IPTABLES -t mangle -I INPUT -p esp -s $$PLUTO_PEER \\
                -d $$PLUTO_ME -j MARK --set-xmark $$PLUTO_MARK_IN
            $$IP route flush table 220
            ;;
        down-client)
            $$IP link del $$VTI_INTERFACE
            $$IPTABLES -t mangle -D FORWARD -o $$VTI_INTERFACE -p tcp -m tcp \\
                --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
            $$IPTABLES -t mangle -D INPUT -p esp -s $$PLUTO_PEER \\
                -d $$PLUTO_ME -j MARK --set-xmark $$PLUTO_MARK_IN
            ;;
    esac
    """)

    IPSEC_SECRETS = string.Template("""
    $${tunnel_1_outside_vgw} : PSK "$${tunnel_1_psk}"
    $${tunnel_2_outside_vgw} : PSK "$${tunnel_2_psk}"
    """)

    FRR_CONFIG = string.Template("""
    log syslog informational
    !
    router bgp $${cgw_asn}
      bgp router-id $${cgw_router_id}
      no bgp ebgp-requires-policy
      neighbor $${tunnel_1_inside_vgw} remote-as $${tunnel_1_aws_asn}
      neighbor $${tunnel_2_inside_vgw} remote-as $${tunnel_2_aws_asn}
      !
      address-family ipv4 unicast
        network $${cgw_cidr}
        neighbor $${tunnel_1_inside_vgw} prefix-list AWS-IN in
        neighbor $${tunnel_1_inside_vgw} prefix-list AWS-OUT out
        neighbor $${tunnel_2_inside_vgw} prefix-list AWS-IN in
        neighbor $${tunnel_2_inside_vgw} prefix-list AWS-OUT out
      exit-address-family
    exit
    !
    ip prefix-list AWS-IN seq 10 permit 10.0.0.0/8 le 32
    ip prefix-list AWS-IN seq 999 deny any
    ip prefix-list AWS-OUT seq 10 permit $${cgw_cidr}
    ip prefix-list AWS-OUT seq 999 deny any
    """)


    def get_vpn_config(ec2, vpn_id):
        try:
            vpns = ec2.describe_vpn_connections(VpnConnectionIds=[vpn_id])
        except botocore.exceptions.ClientError as exc:
            if exc.response['Error']['Code'] == 'InvalidVpnConnectionID.NotFound':
                print(f"VPN ID {vpn_id} not found")
                return None
            else:
                raise
        vpns = vpns['VpnConnections']
        if len(vpns) != 1:
            print(f"Found <>1 VPN for VPN ID {vpn_id}")
            return None
        vpn = vpns[0]

        data = {}
        root = xml.etree.ElementTree.fromstring(
            vpn['CustomerGatewayConfiguration']
        )
        for idx, tunnel in enumerate(root.findall('ipsec_tunnel')):
            idx += 1
            data[f'tunnel_{idx}_outside_vgw'] = tunnel.find(
                './vpn_gateway/tunnel_outside_address/ip_address').text
            data[f'tunnel_{idx}_psk'] = tunnel.find('./ike/pre_shared_key').text
            data[f'tunnel_{idx}_inside_cgw'] = tunnel.find(
                './customer_gateway/tunnel_inside_address/ip_address').text
            data[f'tunnel_{idx}_inside_vgw'] = tunnel.find(
                './vpn_gateway/tunnel_inside_address/ip_address').text
            data[f'tunnel_{idx}_aws_asn'] = tunnel.find(
                './vpn_gateway/bgp/asn').text
        return data


    def main(region, vpn_id, cgw_asn, cgw_cidr, cgw_router_id):
        ec2 = boto3.client('ec2', region_name=region)
        vpn_info = get_vpn_config(ec2, vpn_id)
        if not vpn_info:
          return

        for path, mode, template, mapping in (
            ('/etc/ipsec.conf', 600, IPSEC_CONF, {
                'tunnel_1_outside_vgw': vpn_info['tunnel_1_outside_vgw'],
                'tunnel_2_outside_vgw': vpn_info['tunnel_2_outside_vgw'],
            }),
            ('/etc/strongswan.d/ipsec-vti.sh', 700, IPSEC_VTI_SH, {
                'tunnel_1_inside_cgw': vpn_info['tunnel_1_inside_cgw'],
                'tunnel_1_inside_vgw': vpn_info['tunnel_1_inside_vgw'],
                'tunnel_2_inside_cgw': vpn_info['tunnel_2_inside_cgw'],
                'tunnel_2_inside_vgw': vpn_info['tunnel_2_inside_vgw'],
            }),
            ('/etc/ipsec.secrets', 600, IPSEC_SECRETS, {
                'tunnel_1_outside_vgw': vpn_info['tunnel_1_outside_vgw'],
                'tunnel_1_psk': vpn_info['tunnel_1_psk'],
                'tunnel_2_outside_vgw': vpn_info['tunnel_2_outside_vgw'],
                'tunnel_2_psk': vpn_info['tunnel_2_psk'],
            }),
            ('/etc/frr/frr.conf', 644, FRR_CONFIG, {
                'cgw_asn': cgw_asn,
                'cgw_cidr': cgw_cidr,
                'cgw_router_id': cgw_router_id,
                'tunnel_1_inside_vgw': vpn_info['tunnel_1_inside_vgw'],
                'tunnel_1_aws_asn': vpn_info['tunnel_1_aws_asn'],
                'tunnel_2_inside_vgw': vpn_info['tunnel_2_inside_vgw'],
                'tunnel_2_aws_asn': vpn_info['tunnel_2_aws_asn'],
            }),
        ):
            with open(path, 'w', encoding='utf-8') as f:
                f.write(template.substitute(mapping))
                print(f"Wrote {path}")
            os.chmod(path, mode)

        for service in ('strongswan-starter.service', 'frr.service'):
            subprocess.run(['systemctl', 'restart', service], check=False)
            print(f"Restarted {service}")


    if __name__ == '__main__':
        main('eu-north-1', sys.argv[1], '64512', '192.168.100.0/24', '192.168.100.0')
    VPNSCRIPT

    chmod 700 /usr/local/sbin/configure-vpn
  EOF
  )
}

# Elastic IP for the instance
resource "aws_eip" "cgw_eip" {
  provider = aws.awslondon

  domain = "vpc"
}

# Associate EIP with the network interface
resource "aws_eip_association" "cgw_eip_assoc" {
  provider = aws.awslondon

  instance_id   = aws_instance.cgw.id
  allocation_id = aws_eip.cgw_eip.id
}

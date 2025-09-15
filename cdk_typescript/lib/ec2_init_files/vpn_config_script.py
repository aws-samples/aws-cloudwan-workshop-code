#!/usr/bin/env python3
import os
import string
import subprocess
import sys
import xml.etree.ElementTree

import boto3
import botocore

IPSEC_CONF = string.Template(
    """
	conn %default
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
		right=${tunnel_1_outside_vgw}
		auto=start
		mark=100

	conn AWS-TUNNEL-2
		left=%any4
		right=${tunnel_2_outside_vgw}
		auto=start
		mark=200
	"""
)

IPSEC_VTI_SH = string.Template(
    """
	#!/bin/bash

	IP=$$(which ip)
	IPTABLES=$$(which iptables)

	PLUTO_MARK_OUT_ARR=($${PLUTO_MARK_OUT//// })
	PLUTO_MARK_IN_ARR=($${PLUTO_MARK_IN//// })
	case "$${PLUTO_CONNECTION}" in
	AWS-TUNNEL-1)
		VTI_INTERFACE=vti1
		VTI_LOCALADDR=${tunnel_1_inside_cgw}
		VTI_REMOTEADDR=${tunnel_1_inside_vgw}
		;;
	AWS-TUNNEL-2)
		VTI_INTERFACE=vti2
		VTI_LOCALADDR=${tunnel_2_inside_cgw}
		VTI_REMOTEADDR=${tunnel_2_inside_vgw}
		;;
	esac

	case "$${PLUTO_VERB}" in
		up-client)
			$$IP link add $${VTI_INTERFACE} type vti local $${PLUTO_ME} \\
				remote $${PLUTO_PEER} okey $${PLUTO_MARK_OUT_ARR[0]} \\
				ikey $${PLUTO_MARK_IN_ARR[0]}
			sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.disable_policy=1
			sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=2 || \\
				sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=0
			$$IP addr add $${VTI_LOCALADDR} remote $${VTI_REMOTEADDR} \\
				dev $${VTI_INTERFACE}
			$$IP link set $${VTI_INTERFACE} up mtu 1436
			$$IPTABLES -t mangle -I FORWARD -o $${VTI_INTERFACE} -p tcp -m tcp \\
				--tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
			$$IPTABLES -t mangle -I INPUT -p esp -s $${PLUTO_PEER} \\
				-d $${PLUTO_ME} -j MARK --set-xmark $${PLUTO_MARK_IN}
			$$IP route flush table 220
			;;
		down-client)
			$$IP link del $${VTI_INTERFACE}
			$$IPTABLES -t mangle -D FORWARD -o $${VTI_INTERFACE} -p tcp -m tcp \\
				--tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
			$$IPTABLES -t mangle -D INPUT -p esp -s $${PLUTO_PEER} \\
				-d $${PLUTO_ME} -j MARK --set-xmark $${PLUTO_MARK_IN}
			;;
	esac
	"""
)

IPSEC_SECRETS = string.Template(
    """
	${tunnel_1_outside_vgw} : PSK "${tunnel_1_psk}"
	${tunnel_2_outside_vgw} : PSK "${tunnel_2_psk}"
	"""
)

FRR_CONFIG = string.Template(
    """
	log syslog informational
	!
	router bgp ${cgw_asn}
	bgp router-id ${cgw_router_id}
	no bgp ebgp-requires-policy
	neighbor ${tunnel_1_inside_vgw} remote-as ${tunnel_1_aws_asn}
	neighbor ${tunnel_2_inside_vgw} remote-as ${tunnel_2_aws_asn}
	!
	address-family ipv4 unicast
		network ${cgw_cidr}
		neighbor ${tunnel_1_inside_vgw} prefix-list AWS-IN in
		neighbor ${tunnel_1_inside_vgw} prefix-list AWS-OUT out
		neighbor ${tunnel_2_inside_vgw} prefix-list AWS-IN in
		neighbor ${tunnel_2_inside_vgw} prefix-list AWS-OUT out
	exit-address-family
	exit
	!
	ip prefix-list AWS-IN seq 10 permit 10.0.0.0/8 le 32
	ip prefix-list AWS-IN seq 999 deny any
	ip prefix-list AWS-OUT seq 10 permit ${cgw_cidr}
	ip prefix-list AWS-OUT seq 999 deny any
	"""
)


def get_vpn_config(ec2, vpn_id):
    try:
        vpns = ec2.describe_vpn_connections(VpnConnectionIds=[vpn_id])
    except botocore.exceptions.ClientError as exc:
        if exc.response["Error"]["Code"] == "InvalidVpnConnectionID.NotFound":
            print(f"VPN ID {vpn_id} not found")
            return None
        else:
            raise
    vpns = vpns["VpnConnections"]
    if len(vpns) != 1:
        print(f"Found <>1 VPN for VPN ID {vpn_id}")
        return None
    vpn = vpns[0]

    data = {}
    root = xml.etree.ElementTree.fromstring(vpn["CustomerGatewayConfiguration"])
    for idx, tunnel in enumerate(root.findall("ipsec_tunnel")):
        idx += 1
        data[f"tunnel_{idx}_outside_vgw"] = tunnel.find(
            "./vpn_gateway/tunnel_outside_address/ip_address"
        ).text
        data[f"tunnel_{idx}_psk"] = tunnel.find("./ike/pre_shared_key").text
        data[f"tunnel_{idx}_inside_cgw"] = tunnel.find(
            "./customer_gateway/tunnel_inside_address/ip_address"
        ).text
        data[f"tunnel_{idx}_inside_vgw"] = tunnel.find(
            "./vpn_gateway/tunnel_inside_address/ip_address"
        ).text
        data[f"tunnel_{idx}_aws_asn"] = tunnel.find("./vpn_gateway/bgp/asn").text
    return data


def main(region, vpn_id, cgw_asn, cgw_cidr, cgw_router_id):
    ec2 = boto3.client("ec2", region_name=region)
    vpn_info = get_vpn_config(ec2, vpn_id)
    if not vpn_info:
        return

    for path, mode, template, mapping in (
        (
            "/etc/ipsec.conf",
            600,
            IPSEC_CONF,
            {
                "tunnel_1_outside_vgw": vpn_info["tunnel_1_outside_vgw"],
                "tunnel_2_outside_vgw": vpn_info["tunnel_2_outside_vgw"],
            },
        ),
        (
            "/etc/strongswan.d/ipsec-vti.sh",
            700,
            IPSEC_VTI_SH,
            {
                "tunnel_1_inside_cgw": vpn_info["tunnel_1_inside_cgw"],
                "tunnel_1_inside_vgw": vpn_info["tunnel_1_inside_vgw"],
                "tunnel_2_inside_cgw": vpn_info["tunnel_2_inside_cgw"],
                "tunnel_2_inside_vgw": vpn_info["tunnel_2_inside_vgw"],
            },
        ),
        (
            "/etc/ipsec.secrets",
            600,
            IPSEC_SECRETS,
            {
                "tunnel_1_outside_vgw": vpn_info["tunnel_1_outside_vgw"],
                "tunnel_1_psk": vpn_info["tunnel_1_psk"],
                "tunnel_2_outside_vgw": vpn_info["tunnel_2_outside_vgw"],
                "tunnel_2_psk": vpn_info["tunnel_2_psk"],
            },
        ),
        (
            "/etc/frr/frr.conf",
            644,
            FRR_CONFIG,
            {
                "cgw_asn": cgw_asn,
                "cgw_cidr": cgw_cidr,
                "cgw_router_id": cgw_router_id,
                "tunnel_1_inside_vgw": vpn_info["tunnel_1_inside_vgw"],
                "tunnel_1_aws_asn": vpn_info["tunnel_1_aws_asn"],
                "tunnel_2_inside_vgw": vpn_info["tunnel_2_inside_vgw"],
                "tunnel_2_aws_asn": vpn_info["tunnel_2_aws_asn"],
            },
        ),
    ):
        with open(path, "w", encoding="utf-8") as f:
            f.write(template.substitute(mapping))
            print(f"Wrote {path}")
        os.chmod(path, mode)

    for service in ("strongswan-starter.service", "frr.service"):
        subprocess.run(["systemctl", "restart", service], check=False)
        print(f"Restarted {service}")


if __name__ == "__main__":
    main("eu-north-1", sys.argv[1], "64512", "192.168.100.0/24", "192.168.100.0")

#! /bin/bash

## CONF

CREATE_BRIDGE=0
BRIDGE_IF=""
TAP_IF=""

NAT=0
NAT_IF=""
NET_IP=""
PREFIX=0

VM_IP=""

DHCP_PORT=67
DNS_PORT=53

DNSMASK_CNF=/etc/dnsmasq-qemu.conf
DISABLE_DNSMASQ=0

## END_CONF

usage()
{
	echo "Usage: network-up.sh [ -b | --bridge-if BRIDGE_INTERFACE ] [ -t | --tap-if TAP_INTERFACE ]
							   [ -c | --create-bridge ] [ --vm-address VM_IP_ADDRESS ]
							   [ -a | --network-address NETWORK_ADDRESS ] [ -p | --prefix PREFIX ]
							   [ -n | --nat NAT_IF ] [ --dnsmasq-conf DNSMASQ_CONFIGURATION ]
							   [ --disable-dnsmasq ]
							   [ --dhcp-port DHCP_PORT ] [ --dns-port DNS_PORT ]"
}

bridge_if_setup()
{
	# Network interface
	ip link add "$BRIDGE_IF" type bridge
	ip address add "$NET_IP"/"$PREFIX" dev "$BRIDGE_IF"
	ip link set dev br0 up

	if [ "$NAT" = 0 ]; then
		ip link set dev "$NAT_IF" master "$BRIDGE_IF"
	fi
}

tap_if_setup()
{
	modprobe tap

	ip tuntap add dev "$TAP_IF" mode tap
	ip address add "$VM_IP"/"$PREFIX" dev "$TAP_IF"

	ip link set dev "$TAP_IF" master "$BRIDGE_IF"
	ip link set dev "$TAP_IF" up
}

firewall_conf()
{
	# Firewall configuration
	iptables -t nat -A POSTROUTING -o "$NAT_IF" -j MASQUERADE
	iptables -t filter -A FORWARD -i "$BRIDGE_IF" -o "$NAT_IF" -j ACCEPT
	iptables -t filter -A FORWARD -i "$NAT_IF" -o "$BRIDGE_IF" -j ACCEPT
}

dnsmasq_settings()
{
	# DHCP configuration
	iptables -t filter -A UDP -p udp -m udp --dport "$DHCP_PORT" -j ACCEPT
	iptables -t filter -A UDP -p udp -m udp --dport "$DNS_PORT"  -j ACCEPT # Enable DNS port
	iptables -t filter -A TCP -p tcp -m tcp --dport "$DNS_PORT"  -j ACCEPT
	dnsmasq --conf-file="$DNSMASK_CNF" &
}

if [ "$EUID" != 0 ]; then
	echo "network-up: Error, this script requires root privileges"
	exit 1
fi

# Parse arguments
PARSED_ARGUMENTS=$(getopt -a -n network-up -o b:t:ca:p:n: -l bridge-if:,tap-if:,create-bridge,vm-address:,network-address:,prefix:,nat,dnsmasq-conf:,dhcp-port:,dns-port:,disable-dnsmasq)
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
	case "$1" in
		-b | --bridge-if) 		BRIDGE_IF="$2" 	  ; shift 2 ;;
		-t | --tap-if) 			TAP_IF="$2" 	  ; shift 2 ;;
		-c | --create-bridge) 	CREATE_BRIDGE=0   ; shift 	;;
		--vm-address) 			VM_IP="$2" 		  ; shift 2 ;;
		-a | --network-address) NET_IP="$2" 	  ; shift 2 ;;
		-p | --prefix) 			PREFIX="$2" 	  ; shift 2 ;;
		-n | --nat) 			NAT=1 			  ; shift 	;;
		--disable-dnsmasq) 		DISABLE_DNSMASQ=1 ; shift 	;;
		--dnsmasq-conf) 		DNSMASK_CNF="$2"  ; shift 2 ;;
		--dhcp-port) 			DHCP_PORT="$2" 	  ; shift 2 ;;
		--dns-port) 			DNS_PORT="$2" 	  ; shift 2 ;;
		--) shift; break ;;
		*) echo "network-up: Unexpected option: $1"
		   usage ;;
	esac
done

if [ "$CREATE_BRIDGE" ]; then
	bridge_if_setup
fi

if [ "$NAT" ]; then
	tap_if_setup
	firewall_conf
fi

if [ "$DISABLE_DNSMASQ" = 0 ]; then
	dnsmasq_settings
fi

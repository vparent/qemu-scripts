#! /bin/bash

## CONF

DHCP_PORT=67
DNS_PORT=53
NET_IP=172.30.0.1

inet_interf=wlo1
dnsmask_cnf=/etc/dnsmasq-qemu.conf
mode=nat

## END_CONF

# Network interface
ip link add br0 type bridge
ip link set dev tap0 master br0

if [ "$mode" == nat ]; then
	modprobe tap

	ip tuntap add dev tap0 mode tap

	ip address add 172.30.0.1/16 dev br0
	ip  address add 172.30.0.10/16 dev tap0
else
	ip link set dev $inet_interf master br0
fi

ip link set dev br0 up
ip link set dev tap0 up

# Enable nat
sysctl net.ipv4.ip_forward=1

# Firewall configuration
iptables -t nat -A POSTROUTING -o "$inet_interf" -j MASQUERADE
iptables -t filter -A FORWARD -i br0 -o "$inet_interf" -j ACCEPT
iptables -t filter -A FORWARD -i "$inet_interf" -o br0 -j ACCEPT

# DHCP configuration
iptables -t filter -A UDP -p udp -m udp --dport "$DHCP_PORT"-j ACCEPT
iptables -t filter -A UDP -p udp -m udp --dport "$DNS_PORT" -j ACCEPT # Enable DNS port
iptables -t filter -A TCP -p tcp -m tcp --dport "$DNS_PORT" -j ACCEPT
dnsmasq --conf-file="$dnsmask_cnf"

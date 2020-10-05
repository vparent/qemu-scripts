#! /bin/bash

inet_interf=wlo1
dnsmask_cnf=/etc/dnsmasq-qemu.conf

# Load necessary kernel module for networking (the necessary modules are tun and tap,
# tun is already loaded by default)
sudo modprobe tun
sudo modprobe tap

# Network interface
sudo ip link add br0 type bridge
sudo ip tuntap add dev tap0 mode tap
sudo ip link set dev tap0 master br0
# sudo ip link set dev $inet_interf master br0
sudo ip address add 172.30.0.1/16 dev br0
sudo ip  address add 172.30.0.10/16 dev tap0
sudo ip link set dev br0 up
sudo ip link set dev tap0 up

# Enable nat
sudo sysctl net.ipv4.ip_forward=1

# Firewall configuration
sudo iptables -t nat -A POSTROUTING -o $inet_interf -j MASQUERADE
sudo iptables -t filter -A FORWARD -i br0 -o $inet_interf -j ACCEPT
sudo iptables -t filter -A FORWARD -i $inet_interf -o br0 -j ACCEPT

# DHCP configuration
sudo iptables -t filter -A UDP -p udp -m udp --dport 67 -j ACCEPT
sudo iptables -t filter -A UDP -p udp -m udp --dport 53 -j ACCEPT # Enable DNS port
sudo iptables -t filter -A TCP -p tcp -m tcp --dport 53 -j ACCEPT
sudo dnsmasq --conf-file=$dnsmask_cnf

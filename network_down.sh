#! /bin/bash

inet_interf=wlp0s20f0u7
dnsmask_cnf=/etc/dnsmasq-qemu.conf
	
dnsmasq_pid=$(ps aux | grep "dnsmasq --conf-file=$dnsmask_cnf$" | awk '{print $2}')
kill "$dnsmasq_pid"

systemctl restart iptables

sysctl net.ipv4.ip_forward=0

ip link set dev tap0 down
ip link set br0 up down

ip address del 172.30.0.10/16 dev tap0
ip address del 172.30.0.1/16 dev br0

ip tuntap del dev tap0 mode tap
ip link del br0 type bridge

rmmod tap
rmmod tun

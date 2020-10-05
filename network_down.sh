#! /bin/bash

inet_interf=wlp0s20f0u7
dnsmask_cnf=/etc/dnsmasq-qemu.conf
	
dnsmasq_pid=$(ps aux | grep "dnsmasq --conf-file=$dnsmask_cnf$" | awk '{print $2}')
sudo kill $dnsmasq_pid

sudo systemctl restart iptables

sudo sysctl net.ipv4.ip_forward=0

sudo ip link set dev tap0 down
sudo ip link set br0 up down

sudo ip address del 172.30.0.10/16 dev tap0
sudo ip address del 172.30.0.1/16 dev br0

sudo ip tuntap del dev tap0 mode tap
sudo ip link del br0 type bridge

sudo rmmod tap
sudo rmmod tun

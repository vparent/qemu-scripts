#! /bin/bash

## CONF

DELETE_BRIDGE=0
REMOVE_MODULES=0
RESTART_IPTABLES=0
KILL_DNSMASQ=0
DISABLE_IP_FORWARDING=0

NAT_IF=""
BRIDGE_IF=""
TAP_IF=""

NET_IP=""
VM_IP=""
PREFIX=0

DNSMASQ_CNF=/etc/dnsmasq-qemu.conf

## END_CONF

usage()
{
    echo "Usage: network-down.sh [ -b | --bridge-if BRIDGE_INTERFACE ] [ -t | --tap-if TAP_INTERFACE ]
                                 [ -a | --network-address NETWORK_ADDRESS ] [ --vm-address VM_IP_ADDRESS ]
                                 [ -p | --prefix PREFIX ] [ --dnsmasq-conf DNSMASQ_CONFIGURATION ]
                                 [ -f | --disable-ip-forwarding ] [ -i | --restart-iptables ]
                                 [ -m | --remove-modules ] [ -k | --kill-dnsmasq ]"
}

if [ "$EUID" != 0 ]; then
    echo "network-down: Error, this script requires root privileges"
    exit 1
fi

PARSED_ARGUMENTS=$(getopt -a -n network-down -o b:t:a:p:fimk -l bridge-if,tap-if,network-address,vm-address,prefix,dnsmasq-conf,disable-ip-forwarding,restart-iptables,remove-modules,kill-dnsmasq)
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
    usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
      case "$1" in
          -b | --bridge-if) BRIDGE_IF="$2" ; shift 2 ;;
          -t | --tap-if) TAP_IF="$2" ; shift 2 ;;
          -a | --network-address) NET_IP="$2" ; shift 2 ;;
          --vm-address) VM_IP="$2" ; shift 2 ;;
          -p | --prefix) PREFIX="$2" ; shift 2 ;;
          --dnsmasq-conf) DNSMASQ_CNF="$2" ; shift 2 ;;
          -f | --disable-ip-forwarding) DISABLE_IP_FORWARDING=1 ; shift ;;
          -i | --restart-iptables) RESTART_IPTABLES=1 ; shift ;;
          -m | --remove-modules) REMOVE_MODULES=1 ; shift ;;
          -k | --kill-dnsmasq) KILL_DNSMASQ=1 ; shift ;;
          --) shift ; break ;;
          *) echo "network-down Unexpected option: $1"
             usage ;;
      esac
done

if [ "$KILL_DNSMASQ" ]; then
    dnsmasq_pid=$(ps aux | grep "dnsmasq --conf-file=$DNSMASQ_CNF$" | awk '{print $2}')
    kill "$dnsmasq_pid"
fi

if [ "$RESTART_IPTABLES" ]; then
    systemctl restart iptables
fi

if [ "$DISABLE_IP_FORWARDING" ]; then
    sysctl net.ipv4.ip_forward=0
fi

if [ "$TAP_IF" ]; then
    ip link set dev "$TAP_IF" down
    ip address del "$VM_IP"/"$PREFIX" dev "$TAP_IF"
    ip tuntap del dev "$TAP_IF" mode tap
fi

if [ "$BRIDGE_IF" ]; then
    ip link set dev "$BRIDGE_IF" up down
    ip address del "$NET_IP"/"$PREFIX" dev "$BRIDGE_IF"
    ip link del "$BRIDGE_IF" type bridge
fi

if [ "$REMOVE_MODULES" ]; then
    rmmod tap
    rmmod tun
fi

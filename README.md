# Qemu scripts

The settings in the dnsmasq configuration file located in the conf/dnsmasq-qemu.conf must be equal to the arguments passed to the scripts.

## Network creation script

Usage: network-up.sh [ -b | --bridge-if BRIDGE_INTERFACE ] [ -t | --tap-if TAP_INTERFACE ]
                            [ -c | --create-bridge ] [ --vm-address VM_IP_ADDRESS ]
                            [ -a | --network-address NETWORK_ADDRESS ] [ -p | --prefix PREFIX ]
                            [ -n | --nat NAT_IF ] [ --dnsmasq-conf DNSMASQ_CONFIGURATION ]
                            [ --disable-dnsmasq ]
                            [ --dhcp-port DHCP_PORT ] [ --dns-port DNS_PORT ]

## Network reset script

Usage: network-down.sh [ -b | --bridge-if BRIDGE_INTERFACE ] [ -t | --tap-if TAP_INTERFACE ]
                                [ -a | --network-address NETWORK_ADDRESS ] [ --vm-address VM_IP_ADDRESS ]
                                [ -p | --prefix PREFIX ] [ --dnsmasq-conf DNSMASQ_CONFIGURATION ]
                                [ -f | --disable-ip-forwarding ] [ -i | --restart-iptables ]
                                [ -m | --remove-modules ] [ -k | --kill-dnsmasq ]

## Template VM script

This script should be modified according to the parameters of the VM to be started.

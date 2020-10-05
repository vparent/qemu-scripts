#! /bin/bash

[[ -z $1 ]] && echo "usage $0 <hard drive file> [<drive file format>]" && exit 127

disk=${1:-arch_1.qcow2}
format=${2:-qcow2}

qemu-system-x86_64 -boot d \
			   -machine q35 -device intel-iommu -m 4096 -smp 4 \
			   -enable-kvm -drive file=$disk,format=$format \
			   -nic tap,id=net0,ifname=tap0,mac=02:ca:fe:f0:1d:01,script=no \
			   -vga qxl \
			   -audiodev pa,id=pa -soundhw hda \
			   -cdrom /mnt/Stock/rei/Iso/pop-os_20.04_amd64_intel_9.iso

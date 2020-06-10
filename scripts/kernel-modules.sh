#!/bin/bash

modprobe uio
modprobe openvswitch
modprobe vfio-pci

cd /home/opnfv/vswitchperf/src/dpdk/dpdk
(lsmod | grep igb_uio > /dev/null) || insmod ./x86_64-native-linuxapp-gcc/kmod/igb_uio.ko

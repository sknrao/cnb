# The Issues:

## The queues configuration: 
Currently when dpdk-app is running with the following configuration

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/bccdd931d211-net1 --vdev=virtio_user1,path=/var/run/openvswitch/bccdd931d211-net2 --no-pci -- -p 0x3 -T 120 --no-mac-updating

When, I check the dpdk-info, I can see this:
bccdd931d211-net1 3/4: (dpdkvhostuser: configured_rx_queues=1, configured_tx_queues=1, mtu=1500, requested_rx_queues=1, requested_tx_queues=1)
bccdd931d211-net2 4/5: (dpdkvhostuser: configured_rx_queues=1, configured_tx_queues=1, mtu=1500, requested_rx_queues=1, requested_tx_queues=1)

Is it possible to increase the number of queues? If so, should we do it on the ovs in host? Is there a userspace-cni configuration for that?

## CPU Pinning for containers.
Currently, when we run the pod, we do not have control on which core they should run. 

## SRIOV 
We have 4 scenarios, and all 4 have issues. We should focus on 2 and 4.

### Scenario-1: pf and vf using ixgbe and ixgbevf
EAL: VFIO support initialized
EAL: PCI device 0000:06:10.0 on NUMA socket 0
EAL:   probe driver: 8086:10ed net_ixgbe_vf
EAL: PCI device 0000:06:10.1 on NUMA socket 0
EAL:   probe driver: 8086:10ed net_ixgbe_vf
MAC updating disabled
EAL: Error - exiting with code: 1
  Cause: No Ethernet ports - bye
### Scenario-2 pf using ixgbe and vf using igb_uio
EAL: PCI device 0000:06:10.0 on NUMA socket 0
EAL:   probe driver: 8086:10ed net_ixgbe_vf
EAL: Cannot open /sys/class/uio/uio0/device/config: Read-only file system
EAL: Requested device 0000:06:10.0 cannot be used
EAL: PCI device 0000:06:10.1 on NUMA socket 0
EAL:   probe driver: 8086:10ed net_ixgbe_vf
EAL: Cannot open /sys/class/uio/uio1/device/config: Read-only file system
EAL: Requested device 0000:06:10.1 cannot be used
MAC updating disabled
EAL: Error - exiting with code: 1
  Cause: No Ethernet ports - bye

### Scenario-3: both pf and vf using igb_uio 
container fails to start, see this error in /var/log/messages..
LoadConf(): failed to get VF information: "lstat /sys/bus/pci/devices/0000:06:10.0/physfn/net: no such file or directory"

### Scenario-4: pf using ixgbe vf using VFIO_PCI
vfio-pci: probe of 0000:06:00.0 failed with error -22

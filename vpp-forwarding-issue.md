# Userspace CNI VPP Forwarding Issue


## Test Setup:
```
Direction1:
Trex0-phy ---> TenGigabitEthernet6/0/0 ---> memif1/0 ---> net_memif1
DPDK l2fwd app in pod: net_memif1 ---> net_memif2
Trex1-phy <--- TenGigabitEthernet6/0/1 <--- memif2/0 <--- net_memif2
Direction2:
Trex0-phy ---> TenGigabitEthernet6/0/0 ---> memif2/0 ---> net_memif2
DPDK l2fwd app in pod: net_memif2 ---> net_memif1
Trex1-phy <--- TenGigabitEthernet6/0/1 <--- memif1/0 <--- net_memif1
```
## Pod used
[https://github.com/openshift/app-netutil/tree/master/samples/dpdk_app/dpdk-app-centos](https://github.com/openshift/app-netutil/tree/master/samples/dpdk_app/dpdk-app-centos)

## Network Attachment:
```
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: userspace-vpp-net
spec:
  config: '{
        "cniVersion": "0.3.1",
        "type": "userspace",
        "name": "userspace-vpp-net",
        "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig",
        "logFile": "/var/log/userspace-vpp-net-1-cni.log",
        "logLevel": "debug",
        "host": {
                "engine": "vpp",
                "iftype": "memif",
                "netType": "interface",
                "memif": {
                        "role": "master",
                        "mode": "ethernet"
                }
        },
        "container": {
                "engine": "vpp",
                "iftype": "memif",
                "netType": "interface",
                "memif": {
                        "role": "slave",
                        "mode": "ethernet"
                }
        }
    }'
```
## VPP Configuration
```
unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
}
api-trace {
  on
}
api-segment {
  gid vpp
}
socksvr {
  default
}
cpu {
        main-core 2
        corelist-workers 3-6
}
buffers {
        buffers-per-numa 128000
}
dpdk {
        dev default {
                num-rx-queues 4
                num-tx-queues 4
        }
        ## Whitelist specific interface by specifying PCI address
        dev 0000:06:00.0
        dev 0000:06:00.1
 }
plugins {
        plugin dpdk_plugin.so { enable }
 }
```

## VPP Version:
```
vpp v19.04.4-rc0~4-g8f2ac2b~b137 built by root on dbcd84b03fad at Wed Jan  1 17:31:21 UTC 2020
```

## # L2 patch setup - commands used.
```
Direction:1
sudo vppctl test l2patch rx TenGigabitEthernet6/0/0 tx memif1/0
sudo vppctl test l2patch rx memif2/0 tx TenGigabitEthernet6/0/1
Direction:2
sudo vppctl test l2patch rx TenGigabitEthernet6/0/1 tx memif2/0
sudo vppctl test l2patch rx memif1/0 tx TenGigabitEthernet6/0/0

```

# Issue
## Both All 4 L2 patches setup (PROBLEM)
The Interfaces, Patches and Mode
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0
TenGigabitEthernet6/0/1           2      up          9000/0/0/0
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0
memif2/0                          4      up          9000/0/0/0
vpp# show l2patch
   TenGigabitEthernet6/0/0 -> memif1/0
   TenGigabitEthernet6/0/1 -> memif2/0
                  memif1/0 -> TenGigabitEthernet6/0/0
                  memif2/0 -> TenGigabitEthernet6/0/1
vpp# show mode
l3 local0
l3 TenGigabitEthernet6/0/0
l3 TenGigabitEthernet6/0/1
l3 memif1/0
l3 memif2/0
```
The traffic stats:
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0     rx packets              70598102
                                                                    rx bytes             79993565352
                                                                    tx packets             616631302
                                                                    tx bytes            696194649320
                                                                    tx-error               458997285
TenGigabitEthernet6/0/1           2      up          9000/0/0/0     rx packets              70587607
                                                                    rx bytes             79981831588
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0     rx packets             616631302
                                                                    rx bytes            696194649320
                                                                    tx packets              70598102
                                                                    tx bytes             79993565352
memif2/0                          4      up          9000/0/0/0     tx packets              70587607
                                                                    tx bytes             79981831588
```
Stats Inside the pod:
```
Port statistics ====================================
Statistics for port 0 ------------------------------
Packets sent:                 70573813
Packets received:             70597918
Packets dropped:                 10756
Statistics for port 1 ------------------------------
Packets sent:                 70587129
Packets received:             70584569
Packets dropped:                 10789
Aggregate statistics ===============================
Total packets sent:          141160942
Total packets received:      141182487
Total packets dropped:           21545
====================================================
```
## Only Direction-1 L2 Patches (PROBLEM)
The Interfaces
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0
TenGigabitEthernet6/0/1           2      up          9000/0/0/0
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0
memif2/0                          4      up          9000/0/0/0
```
The L2patches
```
vpp# show l2patch
   TenGigabitEthernet6/0/0 -> memif1/0
                  memif2/0 -> TenGigabitEthernet6/0/1
```
Interface stats after traffic:
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0     rx packets              22087212
                                                                    rx bytes             25041709392
TenGigabitEthernet6/0/1           2      up          9000/0/0/0
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0     rx packets              22086947
                                                                    rx bytes             25041439092
                                                                    tx packets              22087212
                                                                    tx bytes             25041709392
                                                                    drops                   22086947
                                                                    ip4                     22086947
memif2/0                          4      up          9000/0/0/0
```
Stats Inside the pod
```
dpdk-app -n 4 -l 7-10 --master-lcore 7 --vdev=net_memif1,socket=/run/memif-dfa9b2387258-net1.sock,role=slave --vdev=net_memif2,socket=/run/memif-dfa9b2387258-net2.sock,role=slave --no-pci -- -p 0x3 -T 120 --no-mac-updating
EAL: Detected 44 lcore(s)
EAL: Detected 2 NUMA nodes
EAL: Multi-process socket /var/run/dpdk/rte/mp_socket
EAL: Selected IOVA mode 'VA'
EAL: No available hugepages reported in hugepages-2048kB
EAL: Probing VFIO support...
EAL: VFIO support initialized
MAC updating disabled
Lcore 7: RX port 0
Lcore 8: RX port 1
Initializing port 0... done:
Port 0, MAC address: EE:AB:A8:C5:E1:1F

Initializing port 1... done:
Port 1, MAC address: 9E:83:48:5A:FA:C3


Checking link status.done
Port0 Link Up. Speed 0 Mbps - half-duplex

Port1 Link Up. Speed 0 Mbps - half-duplex

L2FWD: entering main loop on lcore 8
L2FWD:  -- lcoreid=8 portid=1
L2FWD: entering main loop on lcore 7
L2FWD:  -- lcoreid=7 portid=0

Port statistics ====================================
Statistics for port 0 ------------------------------
Packets sent:                        0
Packets received:             22086947
Packets dropped:                     0
Statistics for port 1 ------------------------------
Packets sent:                 22086947
Packets received:                    0
Packets dropped:                     0
Aggregate statistics ===============================
Total packets sent:           22086947
Total packets received:       22086947
Total packets dropped:               0
====================================================
```
Output of show memif:
```
sockets
  id  listener    filename
  2   yes (1)     /run/memif-dfa9b2387258-net2.sock
  0   no          /run/vpp/memif.sock
  1   yes (1)     /run/memif-dfa9b2387258-net1.sock

interface memif1/0
  remote-name "DPDK 19.08.0"
  remote-interface "(null)"
  socket-id 1 id 0 mode ethernet
  flags admin-up connected
  listener-fd 42 conn-fd 44
  num-s2m-rings 1 num-m2s-rings 1 buffer-size 0 num-regions 1
  region 0 size 4227328 fd 46
    master-to-slave ring 0:
      region 0 offset 16512 ring-size 1024 int-fd 50
      head 2339 tail 1315 flags 0x0001 interrupts 0
    slave-to-master ring 0:
      region 0 offset 0 ring-size 1024 int-fd 48
      head 1315 tail 1315 flags 0x0001 interrupts 0
interface memif2/0
  remote-name "DPDK 19.08.0"
  remote-interface "(null)"
  socket-id 2 id 0 mode ethernet
  flags admin-up connected
  listener-fd 43 conn-fd 45
  num-s2m-rings 1 num-m2s-rings 1 buffer-size 0 num-regions 1
  region 0 size 4227328 fd 47
    master-to-slave ring 0:
      region 0 offset 16512 ring-size 1024 int-fd 51
      head 1024 tail 0 flags 0x0001 interrupts 0
    slave-to-master ring 0:
      region 0 offset 0 ring-size 1024 int-fd 49
      head 0 tail 0 flags 0x0001 interrupts 0
```
## Only Direction-2 L2 Patches (NO PROBLEM)
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0
TenGigabitEthernet6/0/1           2      up          9000/0/0/0
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0
memif2/0                          4      up          9000/0/0/0

vpp# show mode
l3 local0
l3 TenGigabitEthernet6/0/0
l3 TenGigabitEthernet6/0/1
l3 memif1/0
l3 memif2/0

vpp# show l2patch
   TenGigabitEthernet6/0/1 -> memif2/0
                  memif1/0 -> TenGigabitEthernet6/0/0

vpp# show memif
sockets
  id  listener    filename
  2   yes (1)     /run/memif-60ce97b645d8-net2.sock
  0   no          /run/vpp/memif.sock
  1   yes (1)     /run/memif-60ce97b645d8-net1.sock

interface memif1/0
  socket-id 1 id 0 mode ethernet
  flags admin-up
  listener-fd 43 conn-fd 0
  num-s2m-rings 0 num-m2s-rings 0 buffer-size 0 num-regions 0
interface memif2/0
  socket-id 2 id 0 mode ethernet
  flags admin-up
  listener-fd 44 conn-fd 0
  num-s2m-rings 0 num-m2s-rings 0 buffer-size 0 num-regions 0

vpp# show version
vpp v19.04.4-rc0~4-g8f2ac2b~b137 built by root on dbcd84b03fad at Wed Jan  1 17:31:21 UTC 2020

```
Inside the pod:
```
ENTER dpdk-app:
 argc=1
 l2fwd
  cpuRsp.CPUSet = 0-43
  Interface[0]:
    IfName="eth0"  Name="cbr0"  Type=unknown
    MAC="52:b5:55:04:47:6c"  IP="10.244.1.86"
  Interface[1]:
    IfName="net1"  Name="userspace-vpp-net"  Type=memif
    MAC=""
    Role=slave  Mode=ethernet  Socketpath="/run/memif-60ce97b645d8-net1.sock"
  Interface[2]:
    IfName="net2"  Name="userspace-vpp-net"  Type=memif
    MAC=""
    Role=slave  Mode=ethernet  Socketpath="/run/memif-60ce97b645d8-net2.sock"
 myArgc=16
 dpdk-app -n 4 -l 7-10 --master-lcore 7 --vdev=net_memif1,socket=/run/memif-60ce97b645d8-net1.sock,role=slave --vdev=net_memif2,socket=/run/memif-60ce97b645d8-net2.sock,role=slave --no-pci -- -p 0x3 -T 120 --no-mac-updating
EAL: Detected 44 lcore(s)
EAL: Detected 2 NUMA nodes
EAL: Multi-process socket /var/run/dpdk/rte/mp_socket
EAL: Selected IOVA mode 'VA'
EAL: No available hugepages reported in hugepages-2048kB
EAL: Probing VFIO support...
EAL: VFIO support initialized
MAC updating disabled
Lcore 7: RX port 0
Lcore 8: RX port 1
Initializing port 0... done:
Port 0, MAC address: FE:00:19:7D:07:0A

Initializing port 1... done:
Port 1, MAC address: 1E:61:1B:F5:0B:00


Checking link status.done
Port0 Link Up. Speed 0 Mbps - half-duplex

Port1 Link Up. Speed 0 Mbps - half-duplex

L2FWD: entering main loop on lcore 8
L2FWD:  -- lcoreid=8 portid=1
L2FWD: lcore 9 has nothing to do
L2FWD: lcore 10 has nothing to do
L2FWD: entering main loop on lcore 7
L2FWD:  -- lcoreid=7 portid=0

Port statistics ====================================
Statistics for port 0 ------------------------------
Packets sent:                 24461379
Packets received:                    0
Packets dropped:                     0
Statistics for port 1 ------------------------------
Packets sent:                        0
Packets received:             24461379
Packets dropped:                     0
Aggregate statistics ===============================
Total packets sent:           24461379
Total packets received:       24461379
Total packets dropped:               0
====================================================
```
Traffic Stats:
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0     tx packets              24461379
                                                                    tx bytes             24950606580
TenGigabitEthernet6/0/1           2      up          9000/0/0/0     rx packets              24463193
                                                                    rx bytes             24952456860
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0     rx packets              24461379
                                                                    rx bytes             24950606580
memif2/0                          4      up          9000/0/0/0     tx packets              24463193
                                                                    tx bytes             24952456860

vpp# show l2patch
   TenGigabitEthernet6/0/1 -> memif2/0
                  memif1/0 -> TenGigabitEthernet6/0/0


interface memif1/0
  remote-name "DPDK 19.08.0"
  remote-interface "(null)"
  socket-id 1 id 0 mode ethernet
  flags admin-up connected
  listener-fd 43 conn-fd 42
  num-s2m-rings 1 num-m2s-rings 1 buffer-size 0 num-regions 1
  region 0 size 4227328 fd 46
    master-to-slave ring 0:
      region 0 offset 16512 ring-size 1024 int-fd 50
      head 1024 tail 0 flags 0x0001 interrupts 0
    slave-to-master ring 0:
      region 0 offset 0 ring-size 1024 int-fd 48
      head 16451 tail 16451 flags 0x0001 interrupts 0
interface memif2/0
  remote-name "DPDK 19.08.0"
  remote-interface "(null)"
  socket-id 2 id 0 mode ethernet
  flags admin-up connected
  listener-fd 44 conn-fd 45
  num-s2m-rings 1 num-m2s-rings 1 buffer-size 0 num-regions 1
  region 0 size 4227328 fd 47
    master-to-slave ring 0:
      region 0 offset 16512 ring-size 1024 int-fd 51
      head 17475 tail 16451 flags 0x0001 interrupts 0
    slave-to-master ring 0:
      region 0 offset 0 ring-size 1024 int-fd 49
      head 0 tail 0 flags 0x0001 interrupts 0
```

# Other Failed Configurations:
## xconnect instead of l2patch.
Sample output
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0     rx packets              18375275
                                                                    rx bytes             18742780500
                                                                    tx packets              98683497
                                                                    tx bytes            100657166940
                                                                    tx-error                74199352
TenGigabitEthernet6/0/1           2      up          9000/0/0/0     rx packets              18371587
                                                                    rx bytes             18739018740
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0     rx packets              98683497
                                                                    rx bytes            100657166940
                                                                    tx packets              18375275
                                                                    tx bytes             18742780500
memif2/0                          4      up          9000/0/0/0     tx packets              18371587
                                                                    tx bytes             18739018740
vpp# show mode
l3 local0
l2 xconnect TenGigabitEthernet6/0/0 memif1/0
l2 xconnect TenGigabitEthernet6/0/1 memif2/0
l2 xconnect memif1/0 TenGigabitEthernet6/0/0
l2 xconnect memif2/0 TenGigabitEthernet6/0/1
```


## memifs in bridge-domains along with physical interfaces
Sample output:

```
vpp# show mode
l3 local0
l2 xconnect TenGigabitEthernet6/0/0 memif1/0
l2 xconnect TenGigabitEthernet6/0/1 memif2/0
l2 xconnect memif1/0 TenGigabitEthernet6/0/0
l2 xconnect memif2/0 TenGigabitEthernet6/0/1

vpp# show bridge-domain 4 detail
  BD-ID   Index   BSN  Age(min)  Learning  U-Forwrd   UU-Flood   Flooding  ARP-Term   BVI-Intf
    4       1      0     off       off        on       flood       off       off        N/A

           Interface           If-idx ISN  SHG  BVI  TxFlood        VLAN-Tag-Rewrite
           memif1/0              3     5    0    -      *                 none
    TenGigabitEthernet6/0/0      1     1    0    -      *                 none
  vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
TenGigabitEthernet6/0/0           1      up          9000/0/0/0     rx packets              88403498
                                                                    rx bytes            100222833752
                                                                    tx packets                579130
                                                                    tx bytes               590712600
                                                                    tx-error                  341951
TenGigabitEthernet6/0/1           2      up          9000/0/0/0     rx packets              88391124
                                                                    rx bytes            100208948912
local0                            0     down          0/0/0/0
memif1/0                          3      up          9000/0/0/0     rx packets             309558412
                                                                    rx bytes            342477952976
                                                                    tx packets              88403498
                                                                    tx bytes            100222833752
                                                                    drops                  308979282
memif2/0                          4      up          9000/0/0/0     tx packets              88391124
                                                                    tx bytes            100208948912
 ```
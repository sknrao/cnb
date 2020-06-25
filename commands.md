ommands to Run
## On Worker Node.
### For SRIOV
Go to scripts folder
Run script to bind VFs to DPDK.
```
./bind-to-dpdk.sh
```
Ensure that the NICs are VFs.
```
0000:06:10.0
0000:06:10.1
```
Ensure that PF is still managed by kernel driver ixgbe.
run this script to constantly check the status of the nic
```
./print-nic-status.sh
```
Running the Test:
Currently, with T-Rex you will have to modify the srcmac and destmac configuration in vsperf before running the test. Please modify values in this file:
```
/home/opnfv/vswitchperf/conf/03_traffic.conf
```
PS: This is only required for SRIOV. Please revert the changes for other CNIs.
The modifications required is as follows. When you run l2fwd inside the pod, and If you see this in pod 
```
Lcore 7: RX port 0
Lcore 8: RX port 1
Initializing port 0... done:
Port 0, MAC address: 02:09:C0:38:4C:32

Initializing port 1... done:
Port 1, MAC address: 02:09:C0:D9:A1:A5
```
then,  set  srcmac in traffic as 02:09:C0:D9:A1:A5 and  set dstmac in traffic as 02:09:C0:38:4C:32 

Once you have modified the mac addresses, you are all set to run the test.
```
source vsperfenv/bin/activate
cd vswitchperf
./vsperf --conf-file ~/conf/vsperf-trex-tgen.conf  --mode trafficgen phy2phy_tput
```
Once the test completes, you can down the results from /tmp folder. The exact path will be shown at the end of the test. 

You can use to the unbinding script - unbind the NIC (VF) from the DPDK.

### For OVS-DPDK
Run vswitchperf in trafficgen-off mode.
```
source vsperfenv/bin/activate
cd vswitchperf
./vsperf --conf-file ~/conf/vsperf-trex-notgen.conf  --mode trafficgen-off phy2phy_tput
```
Once the Pod is UP, run script to setup flows
```
cd scripts
./setup-flows.sh
```
Scripts to run to view the status, information and statistics
```
./show-info.sh
./show-dpdk-info.sh  
./show-stats.sh
```
Once the Pod is setup, you can run VSPERF (in separated window) in tgen mode to run the test.
```
source vsperfenv/bin/activate
cd vswitchperf
./vsperf --conf-file ~/conf/vsperf-trex-tgen.conf  --mode trafficgen phy2phy_tput
```
Once the test completes, you can down the results from /tmp folder. The exact path will be shown at the end of the test. 

### For VPP
Location of the configuration file: 
```
/etc/vpp/startup.conf
```
What to check?
```
main-core 2
corelist-workers 3-6
num-rx-queues 4
num-tx-queues 4
dev 0000:06:00.0
dev 0000:06:00.1
socket-mem 1024,1024
no-tx-checksum-offload
```
Starting the VPP:
```
sudo systemctl start vpp
sudo systemctl restart vpp (to restart)
```
Commands for checking configurations. You can enter vppctl once and type these commands.
```
show interface
show mode
show l2patch
```
Bring up whitelisted NICs:
```
sudo vppctl set interface state TenGigabitEthernet6/0/0 up
sudo vppctl set interface state TenGigabitEthernet6/0/1 up
```

After the Pod is up, setup L2-Connectivity. Two approaches. Use the script setup_xconnect.sh in scripts folder.

1. Using l2patch:
```
sudo vppctl test l2patch rx TenGigabitEthernet6/0/0 tx memif1/0
sudo vppctl test l2patch rx TenGigabitEthernet6/0/1 tx memif2/0
sudo vppctl test l2patch rx memif1/0 tx TenGigabitEthernet6/0/0
sudo vppctl test l2patch rx memif2/0 tx TenGigabitEthernet6/0/1
```
2. Using XConnect:
```
sudo vppctl set interface l2 xconnect TenGigabitEthernet6/0/0 memif1/0
sudo vppctl set interface l2 xconnect TenGigabitEthernet6/0/1 memif2/0
sudo vppctl set interface l2 xconnect memif1/0 TenGigabitEthernet6/0/0
sudo vppctl set interface l2 xconnect memif2/0 TenGigabitEthernet6/0/1
```
Once pod is up, xconnect is setup, l2fwd is started in pod, We can run the test 
```
source vsperfenv/bin/activate
cd vswitchperf
./vsperf --conf-file ~/conf/vsperf-trex-tgen.conf  --mode trafficgen phy2phy_tput
```
Once the test completes, you can down the results from /tmp folder. The exact path will be shown at the end of the test. 

Stopping VPP
```
sudo systemctl stop vpp
```

### General
Mounting Hugepages
Add this entry into /etc/fstab
```
nodev /dev/hugepages1GB hugetlbfs pagesize=1GB 0 0
```
Or, run this command
```
sudo mount -t hugetlbfs hugetlbfs /dev/hugepages-1G -o "pagesize=1G"
```

Running container maually:
```
sudo docker run -it --privileged --cap-add=ALL -v /dev/hugepages1G:/dev/hugepages1G -v /dev/hugepages:/dev/hugepages -v /sys/bus/pci/devices:/sys/bus/pci/devices -v /sys/devices/system/node:/sys/devices/system/node -v /dev:/dev dpdk-app-centos /bin/bash
```
Start app manually
```
export DPDK_PARAMS="-n 4 -l 7-10 --master-lcore 7 --socket-mem 512 --no-pci --vdev=virtio_user0,path=/var/run/openvswitch/2f0b08204dc2-net1 --vdev=virtio_user1,path=/var/run/openvswitch/2f0b08204dc2-net2"
export TESTPMD_PARAMS="-p 0x3 -T 120 --no-mac-updating"
l2fwd $DPDK_PARAMS -- $TESTPMD_PARAMS
```
Commands that failed inside the pod:
```
testpmd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/15f96819ed59-net1,queues=4 --vdev=virtio_user1,path=/var/run/openvswitch/15f96819ed59-net2,queues=4 --no-pci -- --auto-start --no-lsc-interrupt --forward-mode=io --txq=3 --rxq=3 --stats-period 60

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/bccdd931d211-net1,queues=2 --vdev=virtio_user1,path=/var/run/openvswitch/bccdd931d211-net2,queues=2 --no-pci -- -p 0x3 -q 2 -T 120 --no-mac-updating

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/bccdd931d211-net1,queues=2 --vdev=virtio_user1,path=/var/run/openvswitch/bccdd931d211-net2,queues=2 --no-pci -- -p 0x3 -T 120 --no-mac-updating

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/6c7dd25993c4-net1,queues=2 --vdev=virtio_user1,path=/var/run/openvswitch/6c7dd25993c4-net2,queues=2 --no-pci -- -p 0x3 -q 2 -T 120 --no-mac-updating

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/6c7dd25993c4-net1,queues=1 --vdev=virtio_user1,path=/var/run/openvswitch/6c7dd25993c4-net2,queues=1 --no-pci -- -p 0x3 -q 2 -T 120 --no-mac-updating

l2fwd -n 4 -l 7-10 --master-lcore 7 --vdev=virtio_user0,path=/var/run/openvswitch/dpdkvhostuser0 --vdev=virtio_user1,path=/var/run/openvswitch/dpdkvhostuser1 --no-pci -- -p 0x3 -q 2 -T 120 --no-mac-updating
```

## On Master Node
### For SRIOV
Create the Network-Attachment-Definition for each desired network
This setup assumes there are two networks, one network for each PF. The
following commands setup those networks:
```
kubectl create -f netAttach-sriov-dpdk-a.yaml
kubectl create -f netAttach-sriov-dpdk-b.yaml
```
The following command can be used to determine the set of
Network-Attachment-Definitions currently created on the system:
```
kubectl get network-attachment-definitions
```
The following command creates the configMap. The ConfigMap provides the
filters to the SR-IOV Device-Plugin to allow it to select the set of VFs
that are available to a given Network-Attachment-Definition.

```
kubectl create -f ./configMap.yaml
kubectl get configmaps  --all-namespaces
```
The following command starts the SR-IOV Device Plugin as a
daemonset container:
```
kubectl create -f sriovdp-daemonset.yaml
```
The above 4 create steps can be run by running **attach.sh** script.

Once the SR-IOV Device Plugin is started, it probes the system
looking for VFs that meet the selector’s criteria. This takes a
couple of seconds to collect. The following command can be used to
determine the number of detected VFs.

```
kubectl get node worker -o json | jq '.status.allocatable'
```

Use the following command to start the DPDK based container using
SR-IOV Interfaces:
```
kubectl create -f sriov-pod.yaml
```
The following steps are used to stop the container and SR-IOV Device
Plugin. You can run **detach.sh** script.
```
kubectl delete pod sriov-pod
kubectl delete -f sriovdp-daemonset.yaml
kubectl delete -f configMap.yaml
kubectl delete -f netAttach-sriov-dpdk-b.yaml
kubectl delete -f netAttach-sriov-dpdk-a.yaml
```

### For Userspace CNI (OVS)
Go to userspace/ovsdpdk folder.
1. Create network attachment:
```
 kubectl create -f userspace-ovs-netAttach.yaml
```
2. Create Pod.
``` 
kubectl create -f userspace-ovs-netapp-pod.yaml 
```
You can run attach.sh script, which runs the above 2 commands
Next go inside the pod, to start the application:
```
kubectl exec -it userspace-ovs-pod -- /bin/bash
```
To teardown: run detach.sh script.

### For Userspace CNI (VPP)
Go to userspace/vpp folder.
```
 kubectl create -f userspace-vpp-netAttach-memif.yaml
```
2. Create Pod.
``` 
kubectl create -f userspace-vpp-pod.yaml
```
You can run attach.sh script, which runs the above 2 commands.
Next go inside the pod, to start the application:
```
kubectl exec -it userspace-vpp-pod -- /bin/bash
```
To teardown: run detach.sh script.

### General
Starting Trex TGen.
Config file is in
```
/etc/trex_cfg.yml
```
login as root.
```
cd v2.48
./t-rex-64 -i --no-scapy-server --nc --no-watchdog
```
Get a pod shell:
```
   kubectl exec -it <pod_name> -- /bin/bash
```
Other useful commands:
```
kubectl get pods -A

kubectl describe node worker
kubectl describe pod <pod_name>
```

## Inside the Pod
```
l2fwd
```


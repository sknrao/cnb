# Some commands for reference
## On Worker Node.
### For SRIOV
Go to scripts folder
Run script to bind VFs to DPDK.
```
./bind-to-dpdk.sh
```

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
sudo docker run -it --privileged --cap-add=ALL -v /dev/hugepages1G:/dev/hugepages1G -v /dev/hugepages:/dev/hugepages -v /sys/bus/pci/devices:/sys/bus/pci/devices -v /sys/devices/system/node:/sys/devices/system/node -v /dev:/dev dpdk-app-centos /bin/bash

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
Plugin:
```
kubectl delete pod sriov-pod
kubectl delete -f sriovdp-daemonset.yaml
kubectl delete -f configMap.yaml
kubectl delete -f netAttach-sriov-dpdk-b.yaml
kubectl delete -f netAttach-sriov-dpdk-a.yaml
```

### For Userspace CNI (OVS)

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

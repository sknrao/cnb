# VSPERF CNB - FAQs

 - Q1. How to start Spirent Virtual TGen.
login to master node (10.10.120.22) as a root. Check the running virtual machines.
```
virsh list 
```
if you don't see 'stc' and 'labserver in the entries, run them.
```
virsh start stc
virsh start labserver
```
Ensure that T-Rex is not Running.

 - Q2. How to stop these virtual TGens running as VMs.
Ideally it should be with first set of commands, however, sometimes this may not work. Please use the second command set.
```
 sudo virsh shutdown stc --mode acpi
 sudo virsh shutdown labserver --mode acpi
 -- If it fails to shutdown --
 sudo virsh destroy stc
 sudo virsh destroy labserver
```
 - Q3. Which configuration file to use and modify for Spirent? Mention important fields to look out.
The file to use is:
```
/home/opnfv/conf/vsperf-spirent.conf
```
Important fields to look out for:
```
TRAFFICGEN_STC_TRIAL_DURATION_SEC = "10"
TRAFFICGEN_STC_RATE_LOWER_LIMIT_PCT = "1.0"
TRAFFICGEN_STC_RATE_UPPER_LIMIT_PCT = "99.0"
TRAFFICGEN_STC_RATE_INITIAL_PCT = "99.0"
TRAFFICGEN_PKT_SIZES = (64, 128, 256, 512, 1024, 1280, 1518)
```

 - Q4. How to setup SRIOV?
For now, you can run SRIOV tests with only TREX. With Spirent, unfortunately, this support is not yet there in VSPERF. You would need a GUI application.

On Node-1, if working with Virtual TGen, the PCIs are:
PF1: 06:00.0 
PF2: 06:00.1
VF1 of PF1: 06:10.0 
VF1 of PF2: 06:10.1

 Follow the below steps
 
 1. Ensure PFs are not bound to dpdk: Run  script ```  unbind-from-dpdk.sh``` , after ensuring the correct PCI Ids are used. Run ``` unset-vfs.sh ``` .
 2. Ensure that atleast/only 1 VF is enabled for each PF: Run ``` setup-vfs```.
 3. Ensure atleast/only 1 VF from each nic is associated with DPDK driver: Run ```bind-to-dpdk.sh ```
 4.  While doing  above steps regularly run ``` print-nic-status.sh ``` script.
 5. After Step-3 you are ready to start the pod.
 6. Once pod is started, and you run l2fwd. Node the 2 Mac addresses for port-0 and port-1. These are are VF1 or PF1 and VF2 of PF2 mac addresses, respectively. You need this to use in the Traffic Generator.  Let us say port-0 mac address is - PM1, and port-1 mac address is PM2.
 7. Open file  ``` /home/opnfv/vswitchperf/conf/03_traffic.conf```.  Under TRAFFIC/l2/ you will see ```srcmac and dstmac``` fields.  Which are set to all zeroes.
 8. Set PM2 to srcmac and PM1 to dstmac. 
 9. YOU SHOULD REVERT TO all-zeroes for NON-SRIOV tests.
 

- Q5. What to check for on worker node during test run
With VPP:
```
show interface : no tx errors and tx misses.
Inside the pod: No drastically uneven packet drops between two ports.
```
 With OVS:
 You may see some connect reset when you start the pod. It should be fine.
 ```
show-stats.sh : no tx or rx drops for physical interface.
Inside the pod: No drastically uneven packet drops between two ports.
```

- Q6. What other steps I should be aware of?
Please do regular clean of hugepages (unreleased). run the command ``` cleanup-hugepages.sh```

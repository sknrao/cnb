# Environment Details.
| Category | Value |
|---|---|
| Operating System | Centos 7 (7.7)|
| K8s Version      | 1.18     |
| Worker Nodes     |  1       |
| Master Nodes     |  1       |
| Connectivity b/w master and worker | Direct |
| Traffic Generators | T-Rex, Ixnet |
| Traffic Generator Running on | Master Node |
| Topology   | PVP : traffic from Tgen to worker host, to pod in worker, to worker host, to tgen |
| DPDK Version | Host:18.11 (for ovs-dpdk) , Pod: 19.08 | 
| OVS version | 2.12 |
| VPP Version | 19.08 |
| Pod   | dpdk-app-centos (https://github.com/intel/userspace-cni-network-plugin/tree/master/docker/dpdk-app-centos) |
| NICs  | Intel 82599 10G |
| ixgbe version | 5.1.0-k-rh7.7 |
| ixgbevf version | 4.1.0-k-rh7.7 |

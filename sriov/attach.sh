kubectl create -f netAttach-sriov-dpdk-a.yaml
kubectl create -f netAttach-sriov-dpdk-b.yaml
kubectl create -f configMapIgb.yaml
kubectl create -f sriovdp-daemonset.yaml

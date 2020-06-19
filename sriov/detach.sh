kubectl delete pod --force sriov-pod
kubectl delete -f sriovdp-daemonset.yaml
kubectl delete -f configMap.yaml
kubectl delete -f netAttach-sriov-dpdk-a.yaml
kubectl delete -f netAttach-sriov-dpdk-b.yaml

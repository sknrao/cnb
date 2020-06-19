#kubectl delete pod --force userspace-ovs-pod
#kubectl delete -f userspace-ovs-netAttach.yaml
kubectl create -f userspace-ovs-netAttach.yaml
kubectl create -f userspace-ovs-netapp-pod.yaml
#kubectl exec -it userspace-ovs-pod -- /bin/bash


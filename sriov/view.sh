kubectl get network-attachment-definitions
kubectl get configmaps  --all-namespaces
kubectl get node worker -o json | jq '.status.allocatable'
kubectl describe node worker

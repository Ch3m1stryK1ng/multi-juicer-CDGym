# helm delete monitoring --namespace monitoring
# helm delete loki --namespace monitoring
# helm delete promtail --namespace monitoring
# helm delete multi-juicer 

# kubectl delete namespace monitoring

# kubectl get configmaps --all-namespaces
# kubectl delete configmaps --all --all-namespaces

# kubectl get secrets --all-namespaces
# kubectl delete secrets --all --all-namespaces

# minikube cache delete
# minikube stop
# minikube delete --all --purge

# ----------------------------------------------------------------------------------------

#!/usr/bin/env bash

echo "Uninstalling MultiJuicer and cleaning up Kubernetes resources..."

# Delete Helm releases
helm delete monitoring --namespace monitoring || true
helm delete loki --namespace monitoring || true
helm delete promtail --namespace monitoring || true
helm delete multi-juicer || true

# Delete Kubernetes namespaces (if they exist)
kubectl delete namespace monitoring --ignore-not-found

# Delete all resources associated with MultiJuicer in the default namespace
kubectl delete all -l app.kubernetes.io/instance=multi-juicer -n default --ignore-not-found

# Delete any remaining deployments, services, replicasets, pods, and cronjobs related to multi-juicer
kubectl delete deployment,service,replicaset,pod,cronjob -l app=juice-balancer -n default --ignore-not-found
kubectl delete deployment,service,replicaset,pod -l app=progress-watchdog -n default --ignore-not-found
kubectl delete cronjob -l app=cleanup-job -n default --ignore-not-found

# Delete any remaining resources with specific names
kubectl delete deployment juice-balancer --ignore-not-found
kubectl delete deployment progress-watchdog --ignore-not-found
kubectl delete service juice-balancer --ignore-not-found
kubectl delete service progress-watchdog --ignore-not-found
kubectl delete replicaset -l app=juice-balancer -n default --ignore-not-found
kubectl delete replicaset -l app=progress-watchdog -n default --ignore-not-found
kubectl delete pod -l app=juice-balancer -n default --ignore-not-found
kubectl delete pod -l app=progress-watchdog -n default --ignore-not-found

# Delete any remaining ConfigMaps and Secrets related to MultiJuicer
kubectl delete configmaps,secret -l app.kubernetes.io/instance=multi-juicer --all-namespaces --ignore-not-found

# Remove local Docker images
docker rmi -f local/juice-balancer || true
docker rmi -f local/cleaner || true
docker rmi -f local/progress-watchdog || true
docker rmi -f local/juice-shop || true

# Clean up Docker caches and dangling images
echo "Cleaning up Docker resources..."
docker system prune -af || true
docker volume prune -f || true
docker builder prune -f || true
docker image prune -af || true

# If using Minikube, delete the cache and the cluster
minikube cache delete || true
minikube stop || true
minikube delete --all --purge || true

# If using Kind, delete the Kind cluster
# Uncomment the following line if you are using Kind
# kind delete cluster --name kind || true

echo "Cleanup complete."


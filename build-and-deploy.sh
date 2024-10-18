#!/usr/bin/env bash

echo "This Script can be used to 'easily' build all MultiJuicer components and install them to a local kubernetes cluster"
echo "For this to work the local kubernetes cluster must have access to the same local registry / image cache which 'docker build ...' writes its image to"
echo "For example docker-desktop with its included k8s cluster"

echo "Usage: ./build-and-deploy.sh"

docker rmi local/juice-balancer:$version
docker rmi local/cleaner:$version
docker rmi local/progress-watchdog:$version
docker rmi local/juice-shop:$version

version="$(uuidgen)"

minikube status || minikube start
eval $(minikube docker-env)

docker build --progress plain -t local/juice-balancer:$version ./juice-balancer &
docker build --progress plain -t local/cleaner:$version ./cleaner &
docker build --progress plain -t local/progress-watchdog:$version ./progress-watchdog &
docker build --progress plain -t local/juice-shop:$version ./juice-shop &

wait

if [ "$(kubectl config current-context)" = "kind-kind" ]; then
  kind load docker-image "local/progress-watchdog:$version" &
  kind load docker-image "local/cleaner:$version" &
  kind load docker-image "local/juice-balancer:$version" &
  # load juice-shop local image into kind cluster
  kind load docker-image "local/juice-shop:$version" &

  wait
fi

helm upgrade --install multi-juicer ./helm/multi-juicer \
  --set="imagePullPolicy=IfNotPresent" \
  --set="balancer.repository=local/juice-balancer" \
  --set="balancer.tag=$version" \
  --set="progressWatchdog.repository=local/progress-watchdog" \
  --set="progressWatchdog.tag=$version" \
  --set="juiceShopCleanup.repository=local/cleaner" \
  --set="juiceShopCleanup.tag=$version"
  --set="juiceShop.image=local/juice-shop" \
  --set="juiceShop.tag=$version"

kubectl get all
eval $(minikube docker-env -u)

# kubectl port-forward --namespace="default" service/juice-balancer 3000:3000

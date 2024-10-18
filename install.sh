# Install Prometheus, Grafana & Grafana Loki
minikube start
## uncomment if needed
# helm registry login ghcr.io -u Ch3m1stryK1ng --password <github_token>

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

echo "Installing Prometheus Operator & Grafana"
helm --namespace monitoring upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --version 62.7.0 --values prometheus-operator-config.yaml \
  --set prometheusOperator.createCustomResource=true \
  --set serviceMonitor.enabled=false

echo "Installing Loki"
helm install loki grafana/loki \
  --namespace monitoring \
  --values /home/a347908610/multi-juicer-CDGym/loki-values.yaml \
  --set serviceMonitor.enabled=true

echo "Installing Loki/Promtail"
helm install promtail grafana/promtail \
  --namespace monitoring \
  --values /home/a347908610/multi-juicer-CDGym/promtail-local-config.yaml \
  --set serviceMonitor.enabled=true

  # --set "config.lokiAddress=http://loki:3100/loki/api/v1/push" 
echo "Installing MultiJuicer"
helm install multi-juicer oci://ghcr.io/juice-shop/multi-juicer/helm/multi-juicer --set="balancer.metrics.enabled=true" --set="balancer.metrics.dashboards.enabled=true" --set="balancer.metrics.serviceMonitor.enabled=true" \
  --set="balancer.service.type=LoadBalancer"

# wget https://raw.githubusercontent.com/juice-shop/multi-juicer/main/guides/k8s/k8s-juice-service.yaml
kubectl apply -f k8s-juice-service.yaml
kubectl describe svc multi-juicer-loadbalancer
minikube service multi-juicer-loadbalancer --url


# minikube service monitoring-grafana --url -n monitoring

# kubectl port-forward --namespace="monitoring" service/monitoring-grafana 8080:80 # password: prom-operator

# kubectl port-forward --namespace="monitoring" service/monitoring-kube-prometheus-prometheus 9090:9090

# kubectl port-forward --namespace="monitoring" svc/loki-gateway 3100:80

# kubectl --namespace="monitoring" port-forward daemonset/promtail 3101

# kubectl port-forward --namespace="default" service/juice-balancer 3000:3000
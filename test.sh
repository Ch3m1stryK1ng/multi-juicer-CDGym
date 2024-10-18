# kubectl port-forward --namespace="monitoring" service/monitoring-grafana 8080:80

# kubectl port-forward --namespace="monitoring" service/monitoring-kube-prometheus-prometheus 9090:9090

# kubectl port-forward --namespace="monitoring" svc/loki-gateway 3100:80

# kubectl --namespace="monitoring" port-forward daemonset/promtail 3101

# kubectl port-forward --namespace="default" service/juice-balancer 3000:3000

# Install Prometheus, Grafana & Grafana Loki

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

kubectl create namespace monitoring

echo "Installing prometheus-operator"
wget https://raw.githubusercontent.com/juice-shop/multi-juicer/main/guides/monitoring-setup/prometheus-operator-config.yaml

echo "Installing Prometheus Operator & Grafana"
helm --namespace monitoring upgrade --install monitoring prometheus-community/kube-prometheus-stack --version 13.3.0 --values prometheus-operator-config.yaml

echo "Installing loki"
helm --namespace monitoring upgrade --install loki grafana/loki --version 2.3.0 --set="serviceMonitor.enabled=true"

echo "Installing loki/promtail"
helm --namespace monitoring upgrade --install promtail grafana/promtail --version 3.0.4 --set "config.lokiAddress=http://loki:3100/loki/api/v1/push" --set="serviceMonitor.enabled=true"

echo "Installing MultiJuicer"
helm install multi-juicer oci://ghcr.io/juice-shop/multi-juicer/helm/multi-juicer --set="balancer.metrics.enabled=true" --set="balancer.metrics.dashboards.enabled=true" --set="balancer.metrics.serviceMonitor.enabled=true"

helm delete monitoring --namespace monitoring
helm delete loki --namespace monitoring
helm delete promtail --namespace monitoring
helm delete multi-juicer 
 
# kubectl delete namespace monitoring
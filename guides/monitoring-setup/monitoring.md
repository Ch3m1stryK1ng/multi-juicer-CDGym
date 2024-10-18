# MultiJuicer Monitoring Setups

This is a short and temporary guide on how to install MultiJuicer together with Prometheus, Grafana & Grafana Loki to get nice monitoring setup for your MultiJuicer installation.

After you have everything installed you can locally port forward the grafana port by running: `kubectl -n monitoring port-forward service/monitoring-grafana 8080:80` and access Grafana in your browser on [http://localhost:8080](http://localhost:8080). The default admin password for the Grafana Setup is: `prom-operator`. You can overwrite this by adding `set="grafana.adminPassword=yourPasswordHere"` to the helm install command for the prometheus-operator.

`kubectl -n monitoring port-forward service/monitoring-grafana 8080:80` 
`kubectl port-forward --namespace="monitoring" service/monitoring-kube-prometheus-prometheus 9090:9090`
`kubectl port-forward --namespace monitoring svc/loki-gateway 3100:80`
`kubectl --namespace monitoring port-forward daemonset/promtail 3101`
`curl http://127.0.0.1:3101/metrics`

```
curl -H "Content-Type: application/json" -XPOST -s "http://127.0.0.1:3100/loki/api/v1/push"  \
--data-raw "{\"streams\": [{\"stream\": {\"job\": \"test\"}, \"values\": [[\"$(date +%s)000000000\", \"fizzbuzz\"]]}]}" \
-H X-Scope-OrgId:foo

Then verify that Loki did received the data using the following command:
curl "http://127.0.0.1:3100/loki/api/v1/query_range" --data-urlencode 'query={job="test"}' -H X-Scope-OrgId:foo | jq .data.result
```

`kubectl port-forward --namespace="default" service/juice-balancer 3000:3000`

```
To administrate the cluster you can log into the JuiceBalancer with the admin account:
Username: admin
Password: ${kubectl get secrets juice-balancer-secret --namespace="default" -o=jsonpath='{.data.adminPassword}' | base64 --decode}
```

```sh
# Install Prometheus, Grafana & Grafana Loki

helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

`kubectl get crd | grep monitoring.coreos.com`

echo "Installing prometheus-operator"
wget https://raw.githubusercontent.com/juice-shop/multi-juicer/main/guides/monitoring-setup/prometheus-operator-config.yaml

echo "Installing Prometheus Operator & Grafana"
helm --namespace monitoring upgrade --install monitoring prometheus-community/kube-prometheus-stack --values prometheus-operator-config.yaml --create-namespace --set prometheusOperator.createCustomResource=true

echo "Installing loki"
helm install loki grafana/loki --namespace monitoring
  --values /home/a347908610/multi-juicer-CDGym/loki-values.yaml
  --set="serviceMonitor.enabled=true"

# helm install loki grafana/loki --namespace monitoring --values /home/a347908610/multi-juicer-CDGym/loki-default-values.yaml 

echo "Installing loki/promtail"
helm --namespace monitoring upgrade --install promtail grafana/promtail --set "config.lokiAddress=http://loki:3100/loki/api/v1/push" --set="serviceMonitor.enabled=true"

echo "Installing MultiJuicer"
helm install multi-juicer oci://ghcr.io/juice-shop/multi-juicer/helm/multi-juicer --set="balancer.metrics.enabled=true" --set="balancer.metrics.dashboards.enabled=true" --set="balancer.metrics.serviceMonitor.enabled=true"
```


`744B17C1`
`D3B7FE45`
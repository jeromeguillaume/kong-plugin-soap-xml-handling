#!/bin/bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts 
helm repo add influxdata https://helm.influxdata.com
helm repo update

echo "Installing Prometheus"
helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace -f prometheusValues.yaml

kubectl -n monitoring expose service prometheus-server --type=LoadBalancer --target-port=9090 --name=prometheus-server-ext

echo "Installing influxDB"
# Add a default database
helm upgrade --install influxdb \
  --namespace monitoring \
  --set persistence.enabled=true,persistence.size=50Gi \
  --set "env[0].name=INFLUXDB_DB" \
  --set "env[0].value=k6" \
    influxdata/influxdb

echo "Installing Grafana"
helm install grafana grafana/grafana --namespace monitoring --create-namespace
kubectl -n monitoring expose service grafana --type=LoadBalancer --target-port=3000 --name=grafana-ext

PASSWORD=$(kubectl -n monitoring get secret grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "The Grafana username/password is admin/$PASSWORD"
echo "Execute this command to get the Grafana EXTERNAL-IP: "
echo "kubectl get svc grafana-ext -n monitoring"
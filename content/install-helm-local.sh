#helm uninstall dailyfeed-content -n dailyfeed
#helm install -n dailyfeed dailyfeed-content dailyfeed-backend-chart-0.1.0.tgz -f values-local-content.yaml
helm upgrade --install -n dailyfeed dailyfeed-content dailyfeed-backend-chart-0.1.0.tgz -f values-local-content.yaml
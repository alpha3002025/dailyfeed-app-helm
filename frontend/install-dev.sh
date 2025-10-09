kubectl apply -f k8s/configmap-local-k8s.yaml
kubectl apply -f k8s/deployment.yaml


## 참고) istio ingrss 로 전환 예정
kubectl apply -f k8s/ingress.yaml


## sudo sh -c 'echo "127.0.0.1    dailyfeed.local" >> /etc/hosts'
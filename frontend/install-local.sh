kubectl apply -f k8s/configmap-local-k8s.yaml
kubectl apply -f k8s/deployment.yaml

# HPA 적용
echo "📈 Applying HPA for frontend service..."
kubectl apply -f ../hpa-configs/hpa-frontend.yaml

## 참고) istio ingrss 로 전환 예정
kubectl apply -f k8s/ingress.yaml

echo "✅ Frontend service installation completed"

## sudo sh -c 'echo "127.0.0.1    dailyfeed.local" >> /etc/hosts'
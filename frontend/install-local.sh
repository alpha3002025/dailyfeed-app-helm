#!/bin/bash

# Check if IMAGE_VERSION is provided
if [ -z "$1" ]; then
  echo "❌ Error: IMAGE_VERSION is required"
  echo "Usage: $0 <IMAGE_VERSION>"
  echo "Example: $0 cbt-20251103-1"
  exit 1
fi

IMAGE_VERSION=$1
echo "🚀 Installing frontend service with image version: ${IMAGE_VERSION}"

# Apply ConfigMap
kubectl apply -f k8s/configmap-local-k8s.yaml

# Apply deployment with image version replacement
cat k8s/deployment.yaml | sed "s/{IMAGE_VERSION}/${IMAGE_VERSION}/g" | kubectl apply -f -

# HPA 적용
echo "📈 Applying HPA for frontend service..."
kubectl apply -f ../hpa-configs/hpa-frontend.yaml

## 참고) istio ingrss 로 전환 예정
kubectl apply -f k8s/ingress.yaml

echo "✅ Frontend service installation completed with image version: ${IMAGE_VERSION}"

## sudo sh -c 'echo "127.0.0.1    dailyfeed.local" >> /etc/hosts'
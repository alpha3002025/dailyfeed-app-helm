#!/bin/bash

# Usage: ./install-helm-local.sh <IMAGE_TAG>
# Example: ./install-helm-local.sh beta-20251023-1234

if [ -z "$1" ]; then
  echo "Error: IMAGE_TAG is required"
  echo "Usage: $0 <IMAGE_TAG>"
  echo "Example: $0 beta-20251023-1234"
  exit 1
fi

IMAGE_TAG=$1

# Istio DestinationRule 및 VirtualService 적용
echo "📡 Applying Istio configurations for member service..."
kubectl apply -f ../istio-configs/destinationrule-member.yaml
kubectl apply -f ../istio-configs/virtualservice-member.yaml
echo ""

# Helm 설치
echo "📦 Installing member service..."
helm install -n dailyfeed dailyfeed-member \
  dailyfeed-backend-chart-1.0.1.tgz \
  -f values-local-member.yaml \
  --set imageTag=${IMAGE_TAG}

# HPA 적용
echo "📈 Applying HPA for member service..."
kubectl apply -f ../hpa-configs/hpa-member.yaml

echo "✅ Member service installation completed"

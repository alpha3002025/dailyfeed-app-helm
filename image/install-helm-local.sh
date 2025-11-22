#!/bin/bash

# Usage: ./install-helm-local.sh <IMAGE_TAG>
# Example: ./install-helm-local.sh beta-20251023-1234

if [ -z "$1" ]; then
  echo "Error: IMAGE_TAG is required"
  echo "Usage: $0 <IMAGE_TAG>"
  echo "Example: $0 beta-20251023-1234"
  return 1
fi

IMAGE_TAG=$1

# Istio DestinationRule 및 VirtualService 적용
echo "📡 Applying Istio configurations for image service..."
kubectl apply -f ../istio-configs/destinationrule-image.yaml
kubectl apply -f ../istio-configs/virtualservice-image.yaml
echo ""

# Helm 설치
echo "📦 Installing image service..."
helm install -n dailyfeed dailyfeed-image \
  dailyfeed-backend-chart-1.0.3.tgz \
  -f values-local-image.yaml \
  --set imageTag=${IMAGE_TAG}

# HPA 적용
echo "📈 Applying HPA for image service..."
kubectl apply -f ../hpa-configs/hpa-image.yaml

echo "✅ Image service installation completed"

#!/bin/bash

# Usage: ./install-helm-dev.sh <IMAGE_TAG>
# Example: ./install-helm-dev.sh cbt-20251103-1

if [ -z "$1" ]; then
  echo "Error: IMAGE_TAG is required"
  echo "Usage: $0 <IMAGE_TAG>"
  echo "Example: $0 cbt-20251103-1"
  exit 1
fi

IMAGE_TAG=$1

# Istio DestinationRule 및 VirtualService 적용
echo "📡 Applying Istio configurations for content service..."
kubectl apply -f ../istio-configs/destinationrule-content.yaml
kubectl apply -f ../istio-configs/virtualservice-content.yaml
echo ""

# Helm 설치
echo "📦 Installing content service (dev)..."
helm install -n dailyfeed dailyfeed-content \
  dailyfeed-backend-chart-1.0.2.tgz \
  -f values-dev-content.yaml \
  --set imageTag=${IMAGE_TAG}

# HPA 적용
echo "📈 Applying HPA for content service..."
kubectl apply -f ../hpa-configs/hpa-content.yaml

echo "✅ Content service installation completed"
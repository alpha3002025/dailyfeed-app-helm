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
echo "📡 Applying Istio configurations for timeline service..."
kubectl apply -f ../istio-configs/destinationrule-timeline.yaml
kubectl apply -f ../istio-configs/virtualservice-timeline.yaml
echo ""

# Helm 설치
echo "📦 Installing timeline service (dev)..."
helm install -n dailyfeed dailyfeed-timeline \
  dailyfeed-backend-chart-1.0.1.tgz \
  -f values-dev-timeline.yaml \
  --set imageTag=${IMAGE_TAG}

# HPA 적용
echo "📈 Applying HPA for timeline service..."
kubectl apply -f ../hpa-configs/hpa-timeline.yaml

echo "✅ Timeline service installation completed"
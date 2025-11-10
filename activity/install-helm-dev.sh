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
echo "📡 Applying Istio configurations for activity service..."
kubectl apply -f ../istio-configs/destinationrule-activity.yaml
kubectl apply -f ../istio-configs/virtualservice-activity.yaml
echo ""

# Helm 설치
echo "📦 Installing activity service (dev)..."
helm install -n dailyfeed dailyfeed-activity \
  dailyfeed-backend-chart-1.0.2.tgz \
  -f values-dev-activity.yaml \
  --set imageTag=${IMAGE_TAG}

# HPA 적용
echo "📈 Applying HPA for activity service..."
kubectl apply -f ../hpa-configs/hpa-activity.yaml

echo "✅ Activity service installation completed"
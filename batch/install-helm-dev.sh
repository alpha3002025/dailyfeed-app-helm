#!/bin/bash

# Usage: ./install-helm-dev.sh <IMAGE_TAG>
# Example: ./install-helm-dev.sh beta-20251023-1234

if [ -z "$1" ]; then
  echo "Error: IMAGE_TAG is required"
  echo "Usage: $0 <IMAGE_TAG>"
  echo "Example: $0 beta-20251023-1234"
  return 1
fi

IMAGE_TAG=$1

helm install -n dailyfeed dailyfeed-batch \
  dailyfeed-batch-chart-1.0.0.tgz \
  -f values-dev-batch.yaml \
  --set imageTag=${IMAGE_TAG}

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

helm install -n dailyfeed dailyfeed-search \
  dailyfeed-backend-chart-0.1.0.tgz \
  -f values-local-search.yaml \
  --set imageTag=${IMAGE_TAG}

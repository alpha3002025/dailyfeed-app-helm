# DailyFeed Frontend Helm Chart

This Helm chart deploys the DailyFeed Frontend application to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Nginx Ingress Controller (if ingress is enabled)

## Installation

### Install with default values

```bash
helm install dailyfeed-frontend ./helm -n dailyfeed --create-namespace
```

### Install with custom image tag

```bash
helm install dailyfeed-frontend ./helm \
  --set image.tag=cbt-20251103-1 \
  -n dailyfeed --create-namespace
```

### Install with custom values file

```bash
helm install dailyfeed-frontend ./helm \
  -f custom-values.yaml \
  -n dailyfeed --create-namespace
```

## Upgrade

```bash
# Upgrade with new image tag
helm upgrade dailyfeed-frontend ./helm \
  --set image.tag=cbt-20251103-2 \
  -n dailyfeed

# Upgrade with custom values
helm upgrade dailyfeed-frontend ./helm \
  -f custom-values.yaml \
  -n dailyfeed
```

## Uninstall

```bash
helm uninstall dailyfeed-frontend -n dailyfeed
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `ghcr.io/alpha3002025/dailyfeed-frontend` |
| `image.tag` | Image tag | `cbt-20251103-1` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `namespace` | Kubernetes namespace | `dailyfeed` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `3000` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts[0].host` | Hostname | `dailyfeed.local` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |

### Backend Service URLs

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backendServices.memberService.url` | Member service URL | `http://dailyfeed-member-svc:8080` |
| `backendServices.contentService.url` | Content service URL | `http://dailyfeed-content-svc:8080` |
| `backendServices.timelineService.url` | Timeline service URL | `http://dailyfeed-timeline-svc:8080` |
| `backendServices.activityService.url` | Activity service URL | `http://dailyfeed-activity-svc:8080` |
| `backendServices.imageService.url` | Image service URL | `http://dailyfeed-image-svc:8080` |
| `backendServices.searchService.url` | Search service URL | `http://dailyfeed-search-svc:8080` |

## Examples

### Example 1: Install with specific image version

```bash
helm install dailyfeed-frontend ./helm \
  --set image.tag=v1.2.3 \
  -n dailyfeed --create-namespace
```

### Example 2: Install with custom backend URLs

```bash
helm install dailyfeed-frontend ./helm \
  --set backendServices.memberService.url=http://custom-member-svc:8080 \
  --set backendServices.contentService.url=http://custom-content-svc:8080 \
  -n dailyfeed --create-namespace
```

### Example 3: Install with increased resources

```bash
helm install dailyfeed-frontend ./helm \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi \
  -n dailyfeed --create-namespace
```

### Example 4: Disable ingress

```bash
helm install dailyfeed-frontend ./helm \
  --set ingress.enabled=false \
  -n dailyfeed --create-namespace
```

## Testing

### Template rendering test

```bash
helm template dailyfeed-frontend ./helm --debug
```

### Dry-run installation

```bash
helm install dailyfeed-frontend ./helm --dry-run --debug -n dailyfeed
```

### Verify installation

```bash
# Check release status
helm status dailyfeed-frontend -n dailyfeed

# List all releases
helm list -n dailyfeed

# Get all resources
kubectl get all -n dailyfeed -l app.kubernetes.io/name=dailyfeed-frontend
```

## Troubleshooting

### View pod logs

```bash
kubectl logs -n dailyfeed -l app=dailyfeed-frontend --tail=100 -f
```

### Describe pod

```bash
kubectl describe pod -n dailyfeed -l app=dailyfeed-frontend
```

### Check configmap

```bash
kubectl get configmap -n dailyfeed dailyfeed-frontend-config -o yaml
```

### Check ingress

```bash
kubectl get ingress -n dailyfeed dailyfeed-frontend
kubectl describe ingress -n dailyfeed dailyfeed-frontend
```

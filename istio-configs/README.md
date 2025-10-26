# Istio Traffic Management Configuration

각 서비스(activity, content, image, member, search, timeline)에 대한 Istio DestinationRule 및 VirtualService 설정 파일입니다.

## 개요

이 디렉토리는 DailyFeed 마이크로서비스에 대한 고급 Istio 트래픽 관리 설정을 포함합니다:

- **DestinationRule**: 연결 풀, Circuit Breaker, 로드밸런싱 정책 설정
- **VirtualService**: 라우팅, 재시도, 타임아웃 정책 설정

## 주요 설정 내용

### 1. DestinationRule 설정

#### Load Balancing
- **알고리즘**: `LEAST_REQUEST` (최소 요청 기반 로드밸런싱)
- **이유**: ROUND_ROBIN보다 부하 분산 효율적, 응답 시간 개선
- **choiceCount**: 2 (2개 인스턴스 중 최소 요청 선택)

#### Connection Pool Settings

**HTTP 설정**:
```yaml
http1MaxPendingRequests: 100-150  # HTTP/1.1 대기 요청 수
http2MaxRequests: 500-600         # HTTP/2 최대 요청 수
maxRequestsPerConnection: 5-10    # 연결당 최대 요청 수
maxRetries: 2-3                   # 최대 재시도 수
idleTimeout: 30-60s              # 유휴 연결 타임아웃
```

**TCP 설정**:
```yaml
maxConnections: 100-150           # TCP 최대 연결 수
connectTimeout: 3s                # 연결 타임아웃
tcpKeepalive:                     # TCP Keepalive
  time: 7200s                     # 2시간
  interval: 75s
  probes: 9
```

#### Circuit Breaker (Outlier Detection)

```yaml
consecutive5xxErrors: 5           # 연속 5xx 에러 5회 → 제거
consecutiveGatewayErrors: 3       # 연속 게이트웨이 에러 3회 → 제거
interval: 1m                      # 분석 간격
baseEjectionTime: 5m              # 기본 제거 시간
maxEjectionPercent: 50            # 최대 50%까지만 제거 (가용성 보장)
minHealthPercent: 30              # 최소 30% 건강한 인스턴스 유지
```

### 2. VirtualService 설정

#### Timeout & Retry

**기본 서비스** (activity, content, member, timeline):
```yaml
timeout: 10s
retries:
  attempts: 5
  perTryTimeout: 3s
  retryOn: gateway-error,connect-failure,refused-stream,5xx,retriable-4xx,reset
```

**Image 서비스** (대용량 처리):
```yaml
timeout: 30s
retries:
  attempts: 3
  perTryTimeout: 10s
  retryOn: gateway-error,connect-failure,refused-stream,reset
```

**Search 서비스** (검색 처리):
```yaml
timeout: 15s
retries:
  attempts: 5
  perTryTimeout: 4s
```

## 서비스별 최적화

### Image Service
- **더 많은 연결**: `maxConnections: 150`, `http2MaxRequests: 600`
- **긴 타임아웃**: 이미지 업로드/다운로드 시간 고려 (`timeout: 30s`)
- **적은 재시도**: 중복 업로드 방지 (`attempts: 3`, `maxRetries: 2`)
- **연결당 적은 요청**: 큰 페이로드 고려 (`maxRequestsPerConnection: 5`)

### Search Service
- **중간 타임아웃**: 검색 처리 시간 고려 (`timeout: 15s`)
- **더 많은 연결**: 검색 부하 처리 (`maxConnections: 120`)
- **적절한 재시도**: 검색 결과 일관성 유지

### 기타 서비스 (Activity, Content, Member, Timeline)
- **표준 설정**: 일반적인 CRUD 작업에 최적화
- **빠른 응답**: `timeout: 10s`, `perTryTimeout: 3s`
- **적극적 재시도**: 일시적 장애 극복

## 사용 방법

### 1. 자동 적용 (권장)

각 서비스의 `install-helm-local.sh` 스크립트가 자동으로 Istio 설정을 적용합니다:

```bash
cd activity
./install-helm-local.sh test-20251025-1
```

### 2. 수동 적용

모든 서비스에 대해 한 번에 적용:

```bash
cd istio-configs
./apply-istio-configs.sh
```

특정 서비스만 적용:

```bash
./apply-istio-configs.sh activity
```

개별 파일 적용:

```bash
kubectl apply -f destinationrule-activity.yaml
kubectl apply -f virtualservice-activity.yaml
```

### 3. 설정 확인

```bash
# DestinationRule 확인
kubectl get destinationrules -n dailyfeed
kubectl describe destinationrule dailyfeed-activity -n dailyfeed

# VirtualService 확인
kubectl get virtualservices -n dailyfeed
kubectl describe virtualservice dailyfeed-activity -n dailyfeed

# Istio 프록시 설정 확인
istioctl proxy-config routes <pod-name> -n dailyfeed
istioctl proxy-config clusters <pod-name> -n dailyfeed
```

## 모니터링 및 디버깅

### Circuit Breaker 상태 확인

```bash
# Kiali 대시보드에서 확인 (추천)
kubectl port-forward -n istio-system svc/kiali 20001:20001

# Istio 메트릭 확인
kubectl exec -it <pod-name> -n dailyfeed -c istio-proxy -- pilot-agent request GET stats | grep outlier
```

### 재시도 및 타임아웃 모니터링

```bash
# Prometheus 쿼리
istio_requests_total{response_code="503"}  # Circuit breaker triggered
istio_request_duration_seconds             # Request duration

# Jaeger 트레이싱
kubectl port-forward -n istio-system svc/tracing 16686:16686
```

### 연결 풀 상태 확인

```bash
istioctl proxy-config cluster <pod-name> -n dailyfeed --fqdn dailyfeed-activity.dailyfeed.svc.cluster.local -o json
```

## 파일 구조

```
istio-configs/
├── README.md                           # 이 문서
├── apply-istio-configs.sh              # 설정 적용 스크립트
├── destinationrule-activity.yaml       # Activity 서비스 DestinationRule
├── destinationrule-content.yaml        # Content 서비스 DestinationRule
├── destinationrule-image.yaml          # Image 서비스 DestinationRule
├── destinationrule-member.yaml         # Member 서비스 DestinationRule
├── destinationrule-search.yaml         # Search 서비스 DestinationRule
├── destinationrule-timeline.yaml       # Timeline 서비스 DestinationRule
├── virtualservice-activity.yaml        # Activity 서비스 VirtualService
├── virtualservice-content.yaml         # Content 서비스 VirtualService
├── virtualservice-image.yaml           # Image 서비스 VirtualService
├── virtualservice-member.yaml          # Member 서비스 VirtualService
├── virtualservice-search.yaml          # Search 서비스 VirtualService
└── virtualservice-timeline.yaml        # Timeline 서비스 VirtualService
```

## 주요 개선 사항

원본 요구사항 대비 추가된 기능:

1. **LoadBalancer 최적화**: LEAST_REQUEST 알고리즘 사용
2. **TCP Keepalive**: 장기 연결 안정성 향상
3. **HTTP/2 업그레이드**: 성능 향상 (`h2UpgradePolicy: UPGRADE`)
4. **추가 Circuit Breaker**: `consecutiveGatewayErrors`, `maxEjectionPercent`, `minHealthPercent`
5. **향상된 Retry 정책**: `retriable-4xx`, `reset` 추가, `retryRemoteLocalities` 활성화
6. **서비스별 최적화**: 각 서비스 특성에 맞는 설정 (Image, Search 등)
7. **세분화된 타임아웃**: 서비스 특성에 따른 적절한 타임아웃 설정

## 설정 튜닝 가이드

### 부하가 높을 때

```yaml
# DestinationRule에서 증가
connectionPool:
  tcp:
    maxConnections: 200
  http:
    http2MaxRequests: 1000
```

### Circuit Breaker 민감도 조정

```yaml
# 더 민감하게 (빠른 제거)
outlierDetection:
  consecutive5xxErrors: 3
  consecutiveGatewayErrors: 2
  baseEjectionTime: 3m

# 덜 민감하게 (안정적 운영)
outlierDetection:
  consecutive5xxErrors: 10
  consecutiveGatewayErrors: 5
  baseEjectionTime: 10m
```

### 타임아웃 조정

```yaml
# VirtualService에서 조정
timeout: 20s              # 전체 타임아웃 증가
retries:
  perTryTimeout: 5s       # 시도당 타임아웃 증가
```



  각 서비스의 install-helm-local.sh가 Helm 설치 전에 자동으로 Istio 설정을 적용합니다:

  ./local-install-infra-and-app.sh test-20251025-1

  수동 적용



# 요약

# 모든 서비스
```
cd dailyfeed-app-helm/istio-configs
./apply-istio-configs.sh
```
<br/>

# 특정 서비스만
```
./apply-istio-configs.sh activity
```
<br/>

# 설정 검증
## DestinationRule 확인
```
kubectl get destinationrules -n dailyfeed
kubectl describe destinationrule dailyfeed-activity -n dailyfeed
```
<br/>

## VirtualService 확인
```
kubectl get virtualservices -n dailyfeed
```
<br/>

## Circuit Breaker 작동 확인 (Kiali)
```
kubectl port-forward -n istio-system svc/kiali 20001:20001
```
<br/>

## 모니터링 포인트
1. Circuit Breaker: Kiali 대시보드에서 503 응답 모니터링
2. 재시도 패턴: Jaeger 트레이싱으로 재시도 추적
3. 연결 풀: Prometheus에서 istio_tcp_connections_opened_total 확인
4. 타임아웃: istio_request_duration_seconds 메트릭 분석

  핵심 설정 요약

| 항목            | 설정값            | 이유                     |
| --------------- | ----------------- | ------------------------ |
| Load Balancing  | LEAST_REQUEST     | 응답 시간 기반 부하 분산 |
| Circuit Breaker | 5xx: 5회, GW: 3회 | 빠른 장애 감지           |
| Ejection Time   | 5분               | 적절한 복구 시간         |
| Max Ejection    | 50%               | 가용성 보장              |
| Retry Attempts  | 3-5회             | 일시적 장애 극복         |
| Timeout         | 10-30s            | 서비스별 최적화          |
| Max Connections | 100-150           | 서비스 부하 고려         |


<br/>


# 참고 자료
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Istio DestinationRule](https://istio.io/latest/docs/reference/config/networking/destination-rule/)
- [Istio VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [Istio Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/)

<br/>

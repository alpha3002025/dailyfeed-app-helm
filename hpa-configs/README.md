# HPA (Horizontal Pod Autoscaler) Configuration

DailyFeed 마이크로서비스 각각에 대한 HPA 설정 파일입니다. Metrics Server를 기반으로 CPU 및 메모리 사용률에 따라 자동으로 Pod를 스케일링합니다.

## 목차
- [개요](#개요)
- [전제 조건](#전제-조건)
- [서비스별 HPA 설정](#서비스별-hpa-설정)
- [사용 방법](#사용-방법)
- [모니터링 및 검증](#모니터링-및-검증)
- [부하 테스트](#부하-테스트)
- [튜닝 가이드](#튜닝-가이드)
- [트러블슈팅](#트러블슈팅)

## 개요

HPA는 CPU와 메모리 사용률을 모니터링하여 자동으로 Pod 수를 조정합니다. 이를 통해:
- **비용 최적화**: 부하가 낮을 때 자동으로 축소
- **성능 보장**: 부하가 높을 때 자동으로 확장
- **고가용성**: 트래픽 급증에 빠르게 대응

## 전제 조건

### 1. Metrics Server 설치 필수

HPA가 작동하려면 Metrics Server가 설치되어 있어야 합니다:

```bash
# Metrics Server 설치 확인
kubectl get deployment metrics-server -n kube-system

# 설치되지 않았다면
cd ../../dailyfeed-infrastructure/helm
source install-metrics-server.sh
```

### 2. Pod에 Resources 설정 필요

모든 Pod에 `resources.requests`가 설정되어 있어야 HPA가 정상 작동합니다.

현재 백엔드 서비스 기본 설정:
```yaml
resources:
  requests:
    memory: "500Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

프론트엔드 서비스 설정:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 서비스별 HPA 설정

### 백엔드 서비스 공통 설정

| 서비스 | Min | Max | CPU 임계값 | Memory 임계값 | 특징 |
|--------|-----|-----|-----------|--------------|------|
| **activity** | 2 | 10 | 70% | 80% | 표준 |
| **content** | 2 | 10 | 70% | 80% | 표준 |
| **image** | 2 | 15 | 65% | 75% | 높은 부하, 빠른 확장 |
| **member** | 2 | 12 | 70% | 80% | 높은 가용성 필요 |
| **search** | 2 | 12 | 65% | 75% | 검색 부하 대응 |
| **timeline** | 2 | 10 | 70% | 80% | 표준 |
| **frontend** | 2 | 15 | 60% | 70% | 사용자 경험 최우선 |

### 세부 설정 설명

#### 1. Activity Service
```yaml
minReplicas: 2
maxReplicas: 10
metrics:
  - cpu: 70%
  - memory: 80%
```
- **용도**: 사용자 활동 추적
- **특징**: 일반적인 CRUD 작업
- **스케일링**: 표준 정책

#### 2. Content Service
```yaml
minReplicas: 2
maxReplicas: 10
metrics:
  - cpu: 70%
  - memory: 80%
```
- **용도**: 콘텐츠 관리
- **특징**: 일반적인 CRUD 작업
- **스케일링**: 표준 정책

#### 3. Image Service (특화 설정)
```yaml
minReplicas: 2
maxReplicas: 15
metrics:
  - cpu: 65%        # 더 낮은 임계값 (빠른 대응)
  - memory: 75%     # 더 낮은 임계값
behavior:
  scaleUp:
    periodSeconds: 20    # 20초마다 평가 (빠름)
    value: 5             # 한 번에 최대 5개 추가
```
- **용도**: 이미지 업로드/다운로드/처리
- **특징**: CPU/메모리 집약적 작업
- **이유**:
  - 이미지 처리는 갑작스런 부하 발생 가능
  - 낮은 임계값으로 빠르게 대응
  - 더 많은 replica 허용 (max 15)

#### 4. Member Service
```yaml
minReplicas: 2
maxReplicas: 12
metrics:
  - cpu: 70%
  - memory: 80%
```
- **용도**: 사용자 인증/회원 관리
- **특징**: 항상 가용해야 하는 핵심 서비스
- **이유**: 높은 가용성을 위해 max replica 증가

#### 5. Search Service (특화 설정)
```yaml
minReplicas: 2
maxReplicas: 12
metrics:
  - cpu: 65%        # 검색은 빠른 대응 필요
  - memory: 75%     # 검색 인덱스 메모리 고려
behavior:
  scaleUp:
    periodSeconds: 25    # 25초마다 평가
```
- **용도**: 검색 기능
- **특징**: CPU와 메모리 모두 중요
- **이유**:
  - 검색은 응답 시간이 중요 → 낮은 임계값
  - 검색 인덱스 메모리 사용량 고려

#### 6. Timeline Service
```yaml
minReplicas: 2
maxReplicas: 10
metrics:
  - cpu: 70%
  - memory: 80%
```
- **용도**: 타임라인 피드 생성
- **특징**: 일반적인 데이터 조회/가공
- **스케일링**: 표준 정책

#### 7. Frontend Service (특화 설정)
```yaml
minReplicas: 2
maxReplicas: 15
metrics:
  - cpu: 60%        # 매우 낮은 임계값 (사용자 경험)
  - memory: 70%
behavior:
  scaleUp:
    periodSeconds: 15    # 15초마다 평가 (매우 빠름)
    value: 5             # 한 번에 최대 5개 추가
```
- **용도**: Next.js 프론트엔드 (SSR)
- **특징**: 사용자와 직접 대면하는 서비스
- **이유**:
  - 사용자 경험 최우선 → 매우 낮은 임계값
  - 트래픽 급증 대비 → 빠른 확장 (15초)
  - Next.js SSR은 CPU 집약적

### Behavior 설정 상세

모든 서비스 공통:

**Scale Down (축소)**:
```yaml
stabilizationWindowSeconds: 300  # 5분 안정화
policies:
  - type: Percent
    value: 50                    # 한 번에 최대 50% 축소
    periodSeconds: 60            # 1분마다 평가
  - type: Pods
    value: 2-3                   # 한 번에 최대 2-3개 축소
    periodSeconds: 60
selectPolicy: Min                # 더 보수적인 정책 선택
```
- **목적**: 급격한 축소 방지 (서비스 안정성)
- **5분 안정화**: Flapping 방지 (불필요한 스케일링 반복)

**Scale Up (확장)**:
```yaml
stabilizationWindowSeconds: 0    # 즉시 반응
policies:
  - type: Percent
    value: 100                   # 한 번에 최대 100% 확장
    periodSeconds: 15-30         # 15-30초마다 평가
  - type: Pods
    value: 4-5                   # 한 번에 최대 4-5개 추가
    periodSeconds: 15-30
selectPolicy: Max                # 더 적극적인 정책 선택
```
- **목적**: 부하 급증에 빠른 대응
- **즉시 반응**: 사용자 경험 보호

## 사용 방법

### 1. 자동 적용 (권장)

각 서비스의 `install-helm-local.sh` 스크립트가 자동으로 HPA를 적용합니다:

```bash
# 전체 인프라 + 앱 설치 (HPA 자동 적용)
./local-install-infra-and-app.sh test-20251025-1
```

실행 순서:
1. Istio DestinationRule/VirtualService 적용
2. Helm으로 서비스 배포
3. **HPA 자동 적용** ← 새로 추가됨

### 2. 수동 적용

모든 서비스에 대해 한 번에 적용:

```bash
cd hpa-configs
./apply-hpa-configs.sh
```

특정 서비스만 적용:

```bash
./apply-hpa-configs.sh frontend
./apply-hpa-configs.sh image
```

개별 파일 적용:

```bash
kubectl apply -f hpa-activity.yaml
kubectl apply -f hpa-frontend.yaml
```

## 모니터링 및 검증

### 1. HPA 상태 확인

```bash
# 모든 HPA 확인
kubectl get hpa -n dailyfeed

# 실시간 모니터링
watch kubectl get hpa -n dailyfeed

# 상세 정보 확인
kubectl get hpa -n dailyfeed -o wide
```

출력 예시:
```
NAME                      REFERENCE                   TARGETS         MINPODS   MAXPODS   REPLICAS
dailyfeed-activity-hpa    Deployment/dailyfeed-activity    45%/70%,60%/80%   2         10        3
dailyfeed-frontend-hpa    Deployment/dailyfeed-frontend    80%/60%,65%/70%   2         15        5
```

### 2. 특정 HPA 상세 정보

```bash
kubectl describe hpa dailyfeed-frontend-hpa -n dailyfeed
```

출력 내용:
- 현재 메트릭 값
- 목표 메트릭 값
- 스케일링 이벤트 히스토리
- 현재 replica 수

### 3. 현재 메트릭 확인

```bash
# Pod별 리소스 사용량
kubectl top pods -n dailyfeed

# Node별 리소스 사용량
kubectl top nodes
```

### 4. HPA 이벤트 확인

```bash
# 최근 HPA 이벤트 확인
kubectl get events -n dailyfeed --sort-by='.lastTimestamp' | grep HPA

# 특정 HPA의 이벤트만
kubectl get events -n dailyfeed --field-selector involvedObject.name=dailyfeed-frontend-hpa
```

## 부하 테스트

### 1. 간단한 부하 생성

```bash
# 부하 생성 Pod 실행
kubectl run -n dailyfeed load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://dailyfeed-frontend:3000; done"

# 여러 개 실행 (더 많은 부하)
for i in {1..5}; do
  kubectl run -n dailyfeed load-generator-$i --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://dailyfeed-frontend:3000; done"
done

# 부하 생성 중지
kubectl delete pod -n dailyfeed load-generator
kubectl delete pod -n dailyfeed -l run=load-generator
```

### 2. HPA 동작 관찰

```bash
# 터미널 1: HPA 상태 모니터링
watch kubectl get hpa -n dailyfeed

# 터미널 2: Pod 수 모니터링
watch kubectl get pods -n dailyfeed

# 터미널 3: 리소스 사용량 모니터링
watch kubectl top pods -n dailyfeed
```

### 3. Apache Bench를 사용한 부하 테스트

```bash
# Port-forward로 서비스 노출
kubectl port-forward -n dailyfeed svc/dailyfeed-frontend 3000:3000 &

# Apache Bench 실행 (100 동시 연결, 10000 요청)
ab -n 10000 -c 100 http://localhost:3000/

# HPA 반응 관찰
kubectl get hpa -n dailyfeed -w
```

## 튜닝 가이드

### 1. CPU 임계값 조정

**현재 설정이 너무 민감한 경우** (자주 스케일링):
```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80  # 70 → 80으로 증가
```

**현재 설정이 둔감한 경우** (응답 느림):
```yaml
averageUtilization: 60  # 70 → 60으로 감소
```

### 2. Replica 범위 조정

**더 많은 확장 필요**:
```yaml
minReplicas: 3    # 2 → 3
maxReplicas: 20   # 10 → 20
```

**비용 절감 필요**:
```yaml
minReplicas: 1    # 2 → 1 (주의: 가용성 감소)
maxReplicas: 5    # 10 → 5
```

### 3. 스케일 업 속도 조정

**더 빠른 확장 필요**:
```yaml
scaleUp:
  stabilizationWindowSeconds: 0
  policies:
  - type: Pods
    value: 10              # 4 → 10
    periodSeconds: 10      # 30 → 10
```

**더 안정적 확장 필요**:
```yaml
scaleUp:
  stabilizationWindowSeconds: 60  # 0 → 60
  policies:
  - type: Pods
    value: 2                       # 4 → 2
    periodSeconds: 60              # 30 → 60
```

### 4. 스케일 다운 속도 조정

**더 빠른 축소 (비용 절감)**:
```yaml
scaleDown:
  stabilizationWindowSeconds: 60   # 300 → 60
  policies:
  - type: Percent
    value: 100                     # 50 → 100
    periodSeconds: 30              # 60 → 30
```

**더 보수적 축소 (안정성)**:
```yaml
scaleDown:
  stabilizationWindowSeconds: 600  # 300 → 600 (10분)
  policies:
  - type: Percent
    value: 25                      # 50 → 25
    periodSeconds: 120             # 60 → 120
```

### 5. 서비스별 권장 튜닝

**Frontend (사용자 대면)**:
- CPU 임계값: 50-60% (낮게)
- 스케일 업: 매우 빠르게 (10-15초)
- Max Replicas: 높게 (15-20)

**Image (처리 집약적)**:
- CPU/Memory 임계값: 60-65% (낮게)
- Max Replicas: 높게 (15-20)
- 스케일 업: 빠르게 (20초)

**Member (핵심 서비스)**:
- Min Replicas: 높게 (3-4)
- Max Replicas: 충분히 (12-15)
- 안정적 스케일링

**기타 서비스**:
- 표준 설정 유지
- 필요시 점진적 조정

## 트러블슈팅

### 1. HPA가 메트릭을 표시하지 않음

**증상**:
```
TARGETS: <unknown>/70%
```

**원인 및 해결**:

```bash
# 1. Metrics Server 확인
kubectl get deployment metrics-server -n kube-system

# 2. Metrics Server가 없다면 설치
cd ../../dailyfeed-infrastructure/helm
source install-metrics-server.sh

# 3. Pod에 resources.requests 설정 확인
kubectl get deployment dailyfeed-frontend -n dailyfeed -o yaml | grep -A 4 resources

# 4. 1-2분 대기 (메트릭 수집 시간)
```

### 2. HPA가 스케일링하지 않음

**증상**: 부하가 높은데도 Pod 수가 증가하지 않음

**확인 사항**:

```bash
# 1. HPA 상태 확인
kubectl describe hpa <hpa-name> -n dailyfeed

# 2. 이벤트 확인
kubectl get events -n dailyfeed | grep HPA

# 3. 현재 메트릭 확인
kubectl top pods -n dailyfeed

# 4. Deployment의 maxReplicas 도달 여부 확인
kubectl get hpa -n dailyfeed
```

**해결**:
- maxReplicas 증가
- 임계값 낮추기
- Metrics Server 재시작

### 3. 너무 자주 스케일링 (Flapping)

**증상**: Pod 수가 계속 증가/감소 반복

**해결**:
```yaml
# stabilizationWindow 증가
behavior:
  scaleDown:
    stabilizationWindowSeconds: 600  # 300 → 600
  scaleUp:
    stabilizationWindowSeconds: 60   # 0 → 60
```

### 4. 스케일 다운이 너무 느림

**증상**: 부하가 낮아져도 Pod 수가 줄지 않음

**확인**:
```bash
# HPA behavior 확인
kubectl get hpa <hpa-name> -n dailyfeed -o yaml | grep -A 20 behavior
```

**해결**:
- stabilizationWindowSeconds 감소
- scaleDown policies 조정

### 5. Resource 사용률이 100% 초과로 표시

**증상**:
```
TARGETS: 150%/70%
```

**의미**: Pod의 실제 사용량이 requests의 150%
- 정상 동작: HPA가 스케일 업 시도
- requests 값이 너무 낮을 수 있음

**해결**:
```yaml
# values.yaml에서 resources.requests 증가
resources:
  requests:
    cpu: "1000m"    # 500m → 1000m
    memory: "1Gi"   # 500Mi → 1Gi
```

## 참고 자료

- [Kubernetes HPA 공식 문서](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [HPA Behavior Configuration](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)

## 요약

### 핵심 포인트

1. **Metrics Server 필수**: HPA 작동의 전제 조건
2. **Resources Requests 필수**: 모든 Pod에 설정되어 있어야 함
3. **서비스별 최적화**: Frontend와 Image는 특화 설정
4. **빠른 확장, 느린 축소**: 사용자 경험과 안정성 균형
5. **모니터링 중요**: 지속적인 관찰과 튜닝 필요

### 설치 흐름

```
전체 설치 스크립트 실행
  ↓
Metrics Server 설치 (infrastructure)
  ↓
각 서비스 설치
  ↓
Istio 설정 적용
  ↓
HPA 자동 적용 ← HERE
  ↓
완료
```

### 다음 단계

1. `./local-install-infra-and-app.sh test-20251025-1` 실행
2. 1-2분 대기 (메트릭 수집)
3. `kubectl get hpa -n dailyfeed` 확인
4. 부하 테스트 수행
5. 필요시 튜닝


# 요약
자동 적용 (이미 구현됨)

./local-install-infra-and-app.sh test-20251025-1

수동 적용

## 모든 서비스
cd dailyfeed-app-helm/hpa-configs
./apply-hpa-configs.sh

## 특정 서비스만
./apply-hpa-configs.sh frontend

모니터링

## HPA 상태 확인
kubectl get hpa -n dailyfeed

## 실시간 모니터링
watch kubectl get hpa -n dailyfeed

## 리소스 사용량 확인
kubectl top pods -n dailyfeed

## 상세 정보
kubectl describe hpa dailyfeed-frontend-hpa -n dailyfeed

부하 테스트

## 간단한 부하 생성
kubectl run -n dailyfeed load-generator --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://dailyfeed-frontend:3000; done"

## HPA 동작 관찰
watch kubectl get hpa -n dailyfeed

검증 포인트

1. Metrics Server 작동: kubectl get deployment metrics-server -n kube-system
2. HPA 생성: kubectl get hpa -n dailyfeed (7개 확인)
3. 메트릭 수집: 1-2분 대기 후 TARGETS 값 확인
4. 부하 테스트: 스케일 업/다운 동작 확인

핵심 개선 사항

1. 서비스별 맞춤 설정: Frontend, Image, Search는 특화 설정
2. 빠른 확장, 느린 축소: 사용자 경험과 안정성 균형
3. 적절한 임계값: 서비스 특성에 맞는 CPU/Memory 임계값
4. 자동 적용: 설치 스크립트에 통합되어 수동 작업 불필요
5. 상세한 문서화: 튜닝, 트러블슈팅 가이드 포함
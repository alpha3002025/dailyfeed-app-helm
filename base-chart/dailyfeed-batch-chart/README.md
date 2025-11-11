# DailyFeed Batch Chart

DailyFeed 배치 작업을 위한 Helm Chart입니다.

## 📋 목차

- [개요](#개요)
- [CronJob 스케줄](#cronjob-스케줄)
- [설치 방법](#설치-방법)
- [환경별 설정](#환경별-설정)
- [CronJob 관리](#cronjob-관리)
- [모니터링](#모니터링)

## 개요

이 Chart는 다음 배치 작업들을 Kubernetes CronJob으로 실행합니다:

1. **JWT Key Rotation**: JWT 서명 키 로테이션
2. **Token Cleanup**: 만료된 토큰 정리

## CronJob 스케줄

### 환경별 JWT Key Rotation 스케줄

| 환경 | 스케줄 | 설명 |
|------|--------|------|
| **Local** | `0 * * * *` | 매 시간 정각 실행 (00:00, 01:00, ..., 23:00) |
| **Dev** | `0 10-17 * * *` | 10시~17시 사이 매 시간 실행 (10:00, 11:00, ..., 17:00) |
| **Production** | `0 2 * * *` | 매일 새벽 2시 실행 |

### Token Cleanup 스케줄

모든 환경에서 **매일 새벽 3시** (`0 3 * * *`)에 실행됩니다.

## 설치 방법

### 1. Local 환경

```bash
# Local 환경 배포
helm install dailyfeed-batch . \
  -f values-local-batch.yaml \
  --set imageTag=1.0.0 \
  --namespace dailyfeed
```

### 2. Dev 환경

```bash
# Dev 환경 배포
helm install dailyfeed-batch . \
  -f values-dev-batch.yaml \
  --set imageTag=1.0.0 \
  --namespace dailyfeed
```

### 3. Production 환경

```bash
# Production 환경 배포 (기본 values.yaml 사용)
helm install dailyfeed-batch . \
  --set imageTag=1.0.0 \
  --set profile=production \
  --namespace dailyfeed
```

## 환경별 설정

### Values 파일

- `values.yaml`: Production 환경 기본 설정
- `values-local.yaml`: Local 환경 전용 설정
- `values-dev.yaml`: Dev 환경 전용 설정

### 주요 설정 값

```yaml
cronJobs:
  jwtKeyRotation:
    enabled: true                      # CronJob 활성화 여부
    schedule: "0 2 * * *"             # Cron 스케줄
    concurrencyPolicy: "Forbid"       # 동시 실행 방지
    successfulJobsHistoryLimit: 3     # 성공한 Job History 보관 개수
    failedJobsHistoryLimit: 3         # 실패한 Job History 보관 개수
    ttlSecondsAfterFinished: 3600     # Job 완료 후 Pod 유지 시간 (초)
    backoffLimit: 2                   # 재시도 횟수
    restartPolicy: "Never"            # Pod 재시작 정책
    resources:                        # 리소스 설정
      memory:
        requests: "256Mi"
        limits: "512Mi"
      cpu:
        requests: "200m"
        limits: "500m"
```

## CronJob 관리

### CronJob 목록 확인

```bash
# 모든 CronJob 확인
kubectl get cronjobs -n dailyfeed

# 출력 예시:
# NAME                                  SCHEDULE        SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# dailyfeed-batch-jwt-key-rotation     0 10-17 * * *   False     0        2h              5d
# dailyfeed-batch-token-cleanup        0 3 * * *       False     0        20h             5d
```

### CronJob 상세 정보

```bash
# JWT Key Rotation CronJob 상세 정보
kubectl describe cronjob dailyfeed-batch-jwt-key-rotation -n dailyfeed

# Token Cleanup CronJob 상세 정보
kubectl describe cronjob dailyfeed-batch-token-cleanup -n dailyfeed
```

### 실행된 Job 확인

```bash
# Job 목록 확인
kubectl get jobs -n dailyfeed

# 특정 Job의 Pod 확인
kubectl get pods -n dailyfeed -l job-type=jwt-key-rotation

# Pod 로그 확인
kubectl logs -n dailyfeed <pod-name>
```

### 수동 실행

CronJob을 대기하지 않고 즉시 실행하려면:

```bash
# JWT Key Rotation 수동 실행
kubectl create job --from=cronjob/dailyfeed-batch-jwt-key-rotation \
  manual-jwt-key-rotation-$(date +%Y%m%d%H%M%S) \
  -n dailyfeed

# Token Cleanup 수동 실행
kubectl create job --from=cronjob/dailyfeed-batch-token-cleanup \
  manual-token-cleanup-$(date +%Y%m%d%H%M%S) \
  -n dailyfeed
```

### CronJob 일시 중지/재개

```bash
# CronJob 일시 중지
kubectl patch cronjob dailyfeed-batch-jwt-key-rotation \
  -n dailyfeed \
  -p '{"spec":{"suspend":true}}'

# CronJob 재개
kubectl patch cronjob dailyfeed-batch-jwt-key-rotation \
  -n dailyfeed \
  -p '{"spec":{"suspend":false}}'
```

### 스케줄 변경

```bash
# Helm으로 스케줄 변경
helm upgrade dailyfeed-batch . \
  -f values-dev-batch.yaml \
  --set cronJobs.jwtKeyRotation.schedule="0 */2 * * *" \
  --namespace dailyfeed

# 또는 직접 패치
kubectl patch cronjob dailyfeed-batch-jwt-key-rotation \
  -n dailyfeed \
  -p '{"spec":{"schedule":"0 */2 * * *"}}'
```

## 모니터링

### Job 실행 이력

```bash
# 최근 실행된 Job 확인 (시간순 정렬)
kubectl get jobs -n dailyfeed --sort-by=.status.startTime

# 실패한 Job만 확인
kubectl get jobs -n dailyfeed --field-selector status.successful=0

# 성공한 Job만 확인
kubectl get jobs -n dailyfeed --field-selector status.successful=1
```

### Job 로그 확인

```bash
# 가장 최근 JWT Key Rotation Job의 로그
kubectl logs -n dailyfeed \
  $(kubectl get pods -n dailyfeed -l job-type=jwt-key-rotation \
    --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{.items[-1].metadata.name}')

# 가장 최근 Token Cleanup Job의 로그
kubectl logs -n dailyfeed \
  $(kubectl get pods -n dailyfeed -l job-type=token-cleanup \
    --sort-by=.metadata.creationTimestamp \
    -o jsonpath='{.items[-1].metadata.name}')
```

### Job 실행 통계

```bash
# CronJob별 통계
kubectl get cronjobs -n dailyfeed -o json | \
  jq -r '.items[] | "\(.metadata.name): Active=\(.status.active // 0), LastSchedule=\(.status.lastScheduleTime)"'
```

## Cron 표현식 참고

| 표현식 | 의미 |
|--------|------|
| `0 * * * *` | 매 시간 정각 |
| `0 10-17 * * *` | 10시~17시 매 시간 |
| `0 */2 * * *` | 2시간마다 |
| `0 2 * * *` | 매일 새벽 2시 |
| `0 2 * * 1` | 매주 월요일 새벽 2시 |
| `0 2 1 * *` | 매월 1일 새벽 2시 |

## 문제 해결

### Job이 실행되지 않는 경우

```bash
# CronJob이 suspend 상태인지 확인
kubectl get cronjob dailyfeed-batch-jwt-key-rotation -n dailyfeed -o jsonpath='{.spec.suspend}'

# CronJob 이벤트 확인
kubectl describe cronjob dailyfeed-batch-jwt-key-rotation -n dailyfeed | grep Events -A 10
```

### Job이 실패하는 경우

```bash
# 실패한 Pod 로그 확인
kubectl logs -n dailyfeed <failed-pod-name>

# Job 상세 정보 확인
kubectl describe job <job-name> -n dailyfeed
```

### 리소스 부족

```bash
# Pod의 리소스 사용량 확인
kubectl top pods -n dailyfeed -l app=dailyfeed-batch

# 리소스 제한 증가
helm upgrade dailyfeed-batch . \
  -f values-dev-batch.yaml \
  --set cronJobs.jwtKeyRotation.resources.memory.limits=1Gi \
  --namespace dailyfeed
```

## 업그레이드

```bash
# Helm Chart 업그레이드
helm upgrade dailyfeed-batch . \
  -f values-dev-batch.yaml \
  --set imageTag=1.0.1 \
  --namespace dailyfeed

# 업그레이드 이력 확인
helm history dailyfeed-batch -n dailyfeed

# 롤백 (이전 버전으로)
helm rollback dailyfeed-batch 1 -n dailyfeed
```

## 삭제

```bash
# Helm Release 삭제
helm uninstall dailyfeed-batch -n dailyfeed

# CronJob과 Job은 자동으로 삭제되지만,
# 남아있는 리소스 확인
kubectl get all -n dailyfeed -l app=dailyfeed-batch
```
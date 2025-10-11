# DailyFeed Frontend - K8s 배포 가이드

## 변경 사항 요약

### 문제점
기존 구조에서는 `NEXT_PUBLIC_*` 환경 변수를 사용했습니다. 이러한 변수는 **빌드 타임**에 코드에 하드코딩되어, 런타임에 ConfigMap으로 변경할 수 없었습니다.

결과적으로:
- 로컬에서 빌드한 이미지는 `localhost:8084`로 하드코딩됨
- K8s에 배포해도 여전히 localhost를 호출하여 실패
- 환경마다 다른 이미지를 빌드해야 하는 불편함

### 해결 방법
**API 프록시 패턴**을 도입하여 모든 백엔드 API 호출을 Next.js 서버를 통해 프록시합니다.

**장점:**
- 런타임에 환경 변수 적용 가능 (K8s ConfigMap 사용)
- 단일 Docker 이미지로 모든 환경 대응
- CORS 문제 해결 (Same Origin)
- 보안 향상 (백엔드 URL이 클라이언트에 노출되지 않음)

## 아키텍처

### Before (문제 상황)
```
브라우저 --[http://localhost:8084/api/...]→ ❌ 연결 실패
```

### After (해결)
```
브라우저 --[/api/proxy/authentication/login]→ Next.js Server --[http://dailyfeed-member:8080/api/authentication/login]→ Backend Service
```

## 주요 변경 파일

### 1. API 프록시 라우트 생성
**파일:** `src/app/api/proxy/[...path]/route.ts`

모든 HTTP 메서드(GET, POST, PUT, DELETE 등)를 처리하며, 요청 경로에 따라 적절한 백엔드 서비스로 라우팅합니다.

**라우팅 규칙:**
- `/api/proxy/authentication/*` → Member Service
- `/api/proxy/members/*` → Member Service
- `/api/proxy/posts*` → Content Service
- `/api/proxy/comments*` → Content Service
- `/api/proxy/timeline/*` → Timeline Service
- `/api/proxy/images/*` → Image Service
- `/api/proxy/search/*` → Search Service
- `/api/proxy/activity/*` → Activity Service

### 2. 환경 변수 설정 변경
**파일:** `src/config/env.ts`

모든 서비스 URL을 `/api/proxy`로 변경하여 클라이언트 코드가 항상 프록시를 통하도록 수정했습니다.

### 3. Dockerfile 간소화
**파일:** `Dockerfile`

빌드 시 `NEXT_PUBLIC_*` ARG를 더 이상 전달하지 않습니다. 모든 백엔드 URL은 런타임에 결정됩니다.

### 4. ConfigMap 업데이트
**파일:** `k8s/configmap-local-k8s.yaml`

- `NEXT_PUBLIC_MEMBER_SERVICE_URL` → `MEMBER_SERVICE_URL`
- `NEXT_PUBLIC_CONTENT_SERVICE_URL` → `CONTENT_SERVICE_URL`
- 등등...

서버 사이드 환경 변수로 변경하여 API 프록시가 읽을 수 있도록 했습니다.

### 5. Deployment 업데이트
**파일:** `k8s/deployment.yaml`

- 이미지 태그: `v0.0.1` → `v0.0.2`
- 환경 변수 키 이름 변경 (NEXT_PUBLIC 접두사 제거)

## 배포 절차

### 1단계: 새 이미지 빌드 및 푸시

```bash
./docker-build-and-push.sh
```

이 스크립트는 `v0.0.2` 태그로 이미지를 빌드하고 Docker Hub에 푸시합니다.

### 2단계: ConfigMap 업데이트

```bash
kubectl apply -f k8s/configmap-local-k8s.yaml
```

### 3단계: Deployment 업데이트

```bash
kubectl apply -f k8s/deployment.yaml
```

또는 이미지만 업데이트:

```bash
kubectl set image deployment/dailyfeed-frontend \
  dailyfeed-frontend=alpha300uk/dailyfeed-frontend:v0.0.2 \
  -n dailyfeed
```

### 4단계: 롤아웃 확인

```bash
# 배포 상태 확인
kubectl rollout status deployment/dailyfeed-frontend -n dailyfeed

# Pod 상태 확인
kubectl get pods -n dailyfeed -l app=dailyfeed-frontend

# 로그 확인
kubectl logs -n dailyfeed -l app=dailyfeed-frontend --tail=100
```

## 테스트

### 로컬 테스트
로컬에서 실행할 때도 프록시가 작동합니다:

```bash
npm run dev
```

브라우저에서 `http://localhost:3000/login`에 접속하여 로그인을 시도하면, 요청이 `/api/proxy/authentication/login`으로 전송되고, Next.js 서버가 이를 `http://localhost:8084/api/authentication/login`으로 프록시합니다.

### K8s 환경 테스트
K8s에 배포 후:

```bash
# Ingress를 통해 접근
curl http://dailyfeed.local/login
```

브라우저에서 로그인을 시도하면:
1. 클라이언트가 `/api/proxy/authentication/login`으로 POST 요청
2. Next.js 서버가 `http://dailyfeed-member:8080/api/authentication/login`으로 프록시
3. Member Service에서 응답 반환
4. 클라이언트로 응답 전달

## 환경별 설정

### Local Development (로컬 개발)
```bash
# .env.local 파일 (선택 사항)
MEMBER_SERVICE_URL=http://localhost:8084
CONTENT_SERVICE_URL=http://localhost:8081
TIMELINE_SERVICE_URL=http://localhost:8082
ACTIVITY_SERVICE_URL=http://localhost:8086
IMAGE_SERVICE_URL=http://localhost:8085
SEARCH_SERVICE_URL=http://localhost:8083
```

### Local K8s (로컬 Kubernetes)
ConfigMap에 정의됨:
```yaml
MEMBER_SERVICE_URL: "http://dailyfeed-member:8080"
CONTENT_SERVICE_URL: "http://dailyfeed-content:8080"
...
```

### Production (운영 환경)
환경에 맞게 ConfigMap을 생성하여 적용:
```yaml
MEMBER_SERVICE_URL: "http://dailyfeed-member.prod.svc.cluster.local:8080"
...
```

## 트러블슈팅

### 문제: API 호출이 실패함
**확인 사항:**
1. ConfigMap이 올바르게 적용되었는지 확인
   ```bash
   kubectl get configmap dailyfeed-frontend-config -n dailyfeed -o yaml
   ```

2. Pod에 환경 변수가 주입되었는지 확인
   ```bash
   kubectl exec -n dailyfeed <pod-name> -- env | grep SERVICE_URL
   ```

3. 프록시 로그 확인
   ```bash
   kubectl logs -n dailyfeed <pod-name> | grep "API Proxy"
   ```

### 문제: 백엔드 서비스에 연결할 수 없음
**확인 사항:**
1. 백엔드 서비스가 실행 중인지 확인
   ```bash
   kubectl get svc -n dailyfeed
   ```

2. DNS 해석이 작동하는지 확인
   ```bash
   kubectl exec -n dailyfeed <frontend-pod> -- nslookup dailyfeed-member
   ```

3. 네트워크 정책이 통신을 차단하지 않는지 확인

### 문제: 이미지가 pull되지 않음
**확인 사항:**
1. 이미지가 Docker Hub에 푸시되었는지 확인
   ```bash
   docker pull alpha300uk/dailyfeed-frontend:v0.0.2
   ```

2. imagePullPolicy 확인 (현재는 `IfNotPresent`)

## 향후 개선 사항

1. **Rate Limiting**: API 프록시에 rate limiting 추가
2. **Caching**: 자주 요청되는 데이터에 대한 캐싱 레이어 추가
3. **Monitoring**: 프록시 메트릭 수집 및 모니터링
4. **Error Handling**: 더 세밀한 에러 처리 및 재시도 로직
5. **Health Check**: 백엔드 서비스 health check 통합

## 참고 자료

- [Next.js API Routes](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- [Next.js Environment Variables](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [BFF Pattern (Backend for Frontend)](https://learn.microsoft.com/en-us/azure/architecture/patterns/backends-for-frontends)

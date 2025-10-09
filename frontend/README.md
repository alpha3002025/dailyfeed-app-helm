# Dailyfeed Frontend Kubernetes Deployment Guide

이 문서는 dailyfeed-frontend-svc를 Kubernetes 환경에 배포하는 방법을 설명합니다.

## 아키텍처 개요

현재 프로젝트는 **환경변수 기반 엔드포인트 전환** 방식을 사용하여, 로컬 개발환경과 Kubernetes 환경 모두에서 동작할 수 있도록 구성되어 있습니다.

### 백엔드 서비스 구성

**로컬 WAS 환경** (각 서비스별 고유 포트):
```
dailyfeed-member-svc     → 8084 포트 (인증, 회원 관리)
dailyfeed-content-svc    → 8081 포트 (게시글, 댓글)
dailyfeed-timeline-svc   → 8082 포트 (타임라인)
dailyfeed-activity-svc   → 8086 포트 (활동 로그)
dailyfeed-image-svc      → 8085 포트 (이미지 업로드)
dailyfeed-search-svc     → 8083 포트 (검색)
```

**Kubernetes 환경** (모든 서비스 통일 포트):
```
모든 서비스 → 8080 포트
```

### 환경별 구성

1. **로컬 개발 환경** (`.env` 파일)
   - Frontend가 로컬에서 실행되며 로컬 WAS의 백엔드 서비스와 통신
   - 각 서비스별 고유 포트 사용
   - 예: `http://localhost:8084`, `http://localhost:8081`, ...

2. **Local WAS 프로필** (`configmap-local-was.yaml`)
   - Frontend가 K8s에 배포되어 있지만, 로컬 WAS의 백엔드와 통신
   - 각 서비스별 고유 포트 사용
   - URL: `http://host.docker.internal:808x` (Mac/Windows)
   - Linux/Minikube의 경우 호스트 IP로 변경 필요

3. **Local K8s 프로필** (`configmap-local-k8s.yaml`)
   - Frontend와 Backend 모두 K8s 클러스터 내부에서 통신
   - 모든 서비스가 **8080 포트** 사용
   - URL: `http://dailyfeed-{service}:8080` (K8s 내부 DNS)

## 🚀 빠른 시작 가이드

### Ingress를 통한 80 포트 외부 접속

**1. Nginx Ingress Controller 설치**

```bash
# Helm으로 설치
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 설치 확인
kubectl get pods -n ingress-nginx
```

**2. Frontend 배포**

```bash
# ConfigMap 선택 (local-was 또는 local-k8s)
kubectl apply -f k8s/configmap-local-k8s.yaml

# Deployment
kubectl apply -f k8s/deployment.yaml

# Ingress
kubectl apply -f k8s/ingress.yaml
```

**3. hosts 파일 설정 (로컬 테스트)**

```bash
# Mac/Linux
sudo nano /etc/hosts

# 추가
127.0.0.1  dailyfeed.local
```

**4. 접속**

브라우저에서 `http://dailyfeed.local` 접속

### 📝 Ingress 설정 커스터마이즈

**실제 도메인 사용 시** `k8s/ingress.yaml` 수정:

```yaml
spec:
  rules:
  - host: dailyfeed.yourdomain.com  # 실제 도메인으로 변경
```

**HTTPS 설정 시**:
1. TLS 인증서 생성 (Let's Encrypt, cert-manager 등)
2. `ingress.yaml`의 `tls` 섹션 주석 해제
3. Secret에 인증서 저장

---



## 배포 단계

### 1. Prerequisites

- Kubernetes 클러스터
  - **Docker Desktop** (Mac/Windows) - Kubernetes 기능 활성화
  - **OrbStack** (Mac) - 권장, 더 빠른 성능
  - **Minikube** (Mac/Linux/Windows)
  - 또는 실제 클러스터 (EKS, GKE, AKS 등)
- kubectl CLI 설치 및 구성
- `dailyfeed` 네임스페이스 생성됨
- Docker 이미지 빌드 완료

```bash
# 네임스페이스 확인
kubectl get namespace dailyfeed

# 없다면 생성
kubectl create namespace dailyfeed
```

### 2. ConfigMap 배포

#### Local WAS 프로필 (Frontend는 K8s, Backend는 로컬 WAS)

```bash
kubectl apply -f k8s/configmap-local-was.yaml
```

**참고**:
- **Docker Desktop / OrbStack (Mac/Windows)**: `host.docker.internal` 그대로 사용 가능
- **Minikube / Linux**: `configmap-local-was.yaml` 파일을 열어 `host.docker.internal`을 실제 호스트 머신의 IP 주소로 변경
  - 예: `http://192.168.1.100:8084`
  - Mac에서 호스트 IP 확인: `ipconfig getifaddr en0`
  - Linux에서 호스트 IP 확인: `ip addr show | grep inet`

#### Local K8s 프로필 (Frontend와 Backend 모두 K8s)

```bash
kubectl apply -f k8s/configmap-local-k8s.yaml
```

### 3. Deployment 배포

```bash
kubectl apply -f k8s/deployment.yaml
```

### 4. Ingress 배포 (선택사항 - 외부 접속용)

80 포트로 외부에서 접속하려면 Ingress를 배포하세요:

```bash
kubectl apply -f k8s/ingress.yaml
```

자세한 설정 방법은 아래 "[Ingress를 통한 외부 접속](#ingress를-통한-외부-접속-포트-80)" 섹션을 참고하세요.

### 5. 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -n dailyfeed -l app=dailyfeed-frontend

# Service 확인
kubectl get svc -n dailyfeed dailyfeed-frontend

# Ingress 확인 (배포한 경우)
kubectl get ingress -n dailyfeed dailyfeed-frontend

# Logs 확인
kubectl logs -n dailyfeed -l app=dailyfeed-frontend --tail=100 -f

# ConfigMap 확인
kubectl describe configmap dailyfeed-frontend-config -n dailyfeed
```

### 6. 접속 테스트

#### Port Forward를 통한 로컬 접속

```bash
kubectl port-forward -n dailyfeed svc/dailyfeed-frontend 3000:3000
```

브라우저에서 `http://localhost:3000` 접속

#### Ingress를 통한 외부 접속 (포트 80)

Ingress를 통해 80 포트로 외부에서 접속하려면:

**1. Nginx Ingress Controller 설치 (미설치 시)**

```bash
# Nginx Ingress Controller 설치 (Helm)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# 또는 kubectl로 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# 설치 확인
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

**2. Ingress 리소스 배포**

```bash
kubectl apply -f k8s/ingress.yaml
```

**3. hosts 파일 설정 (로컬 테스트용)**

```bash
# Mac/Linux
sudo nano /etc/hosts

# Windows
# C:\Windows\System32\drivers\etc\hosts

# 다음 라인 추가
127.0.0.1  dailyfeed.local
```

**4. 접속**

브라우저에서 `http://dailyfeed.local` 접속

**참고**: 실제 도메인을 사용하는 경우, `ingress.yaml` 파일의 `host` 필드를 실제 도메인으로 변경하세요.

## 환경 전환

### Local WAS → Local K8s 프로필

```bash
# Local WAS ConfigMap 삭제
kubectl delete configmap dailyfeed-frontend-config -n dailyfeed

# Local K8s ConfigMap 적용
kubectl apply -f k8s/configmap-local-k8s.yaml

# Deployment 재시작 (환경변수 반영)
kubectl rollout restart deployment/dailyfeed-frontend -n dailyfeed
```

### Local K8s → Local WAS 프로필

```bash
# Local K8s ConfigMap 삭제
kubectl delete configmap dailyfeed-frontend-config -n dailyfeed

# Local WAS ConfigMap 적용
kubectl apply -f k8s/configmap-local-was.yaml

# Deployment 재시작
kubectl rollout restart deployment/dailyfeed-frontend -n dailyfeed
```

## 트러블슈팅

### 1. Pod가 CrashLoopBackOff 상태

```bash
# Pod 상세 정보 확인
kubectl describe pod -n dailyfeed <pod-name>

# 로그 확인
kubectl logs -n dailyfeed <pod-name>
```

**일반적인 원인**:
- 환경변수 미설정 또는 잘못된 값
- 이미지 Pull 실패
- 백엔드 서비스 연결 불가

### 2. 백엔드 서비스 연결 실패

**Local WAS 프로필:**
- `host.docker.internal` 해석 실패:
  - **Docker Desktop / OrbStack**: 정상 작동해야 함. 재시작 시도
  - **Minikube / Linux**: `host.docker.internal`을 실제 호스트 IP로 변경
    ```bash
    # Mac
    ipconfig getifaddr en0

    # Linux
    ip addr show | grep "inet " | grep -v 127.0.0.1
    ```
- 방화벽 확인: 로컬 WAS 포트가 컨테이너에서 접근 가능한지 확인
- 로컬 WAS가 실제로 실행 중인지 확인: `curl http://localhost:8084`

**Local K8s 프로필:**
- 백엔드 서비스가 배포되어 있는지 확인: `kubectl get svc -n dailyfeed`
- 서비스 이름과 포트 번호 확인
- NetworkPolicy가 트래픽을 차단하고 있지 않은지 확인

### 3. 환경변수 확인

```bash
# ConfigMap에 정의된 환경변수 확인
kubectl get configmap dailyfeed-frontend-config -n dailyfeed -o yaml

# Pod에 주입된 환경변수 확인
kubectl exec -n dailyfeed <pod-name> -- env | grep NEXT_PUBLIC
```

### 4. Ingress 접속 불가

```bash
# Ingress 상태 확인
kubectl get ingress -n dailyfeed dailyfeed-frontend
kubectl describe ingress -n dailyfeed dailyfeed-frontend

# Ingress Controller 확인
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

**일반적인 원인**:
- Ingress Controller가 설치되지 않음 → 위 "[Ingress를 통한 외부 접속](#ingress를-통한-외부-접속-포트-80)" 섹션 참고
- hosts 파일이 설정되지 않음 → `/etc/hosts`에 `127.0.0.1 dailyfeed.local` 추가
- Ingress Controller의 External IP가 pending 상태:
  ```bash
  # LoadBalancer 타입 확인
  kubectl get svc -n ingress-nginx
  
  # 로컬 환경(Docker Desktop/Minikube)에서는 NodePort로 접근:
  kubectl get svc -n ingress-nginx ingress-nginx-controller
  # NodePort를 확인하고 http://localhost:<nodeport> 로 접속
  ```
- 방화벽이 80 포트를 차단하고 있는 경우

## Docker 이미지 빌드

### Dockerfile 구조

프로젝트는 **Multi-stage 빌드**를 사용하여 최적화된 이미지를 생성합니다:

1. **Stage 1: deps** - 프로덕션 의존성만 설치
   ```dockerfile
   RUN npm ci --only=production && npm cache clean --force
   ```

2. **Stage 2: builder** - 모든 의존성 설치 및 빌드
   ```dockerfile
   # devDependencies를 포함한 모든 패키지 설치
   RUN npm ci && npm cache clean --force

   # Next.js 애플리케이션 빌드
   RUN npm run build
   ```

3. **Stage 3: runner** - 최소한의 파일로 실행
   - Non-root 사용자(nextjs)로 실행
   - Standalone 모드로 빌드된 파일만 포함
   - 프로덕션 최적화

**주요 특징**:
- ✅ **devDependencies 포함 빌드**: TypeScript, ESLint 등 빌드에 필요한 패키지 포함
- ✅ **캐시 최적화**: 레이어 캐싱으로 빠른 재빌드
- ✅ **보안**: Non-root 사용자로 실행
- ✅ **작은 이미지 크기**: Standalone 모드 + Alpine Linux

### 기본 빌드 (환경변수 런타임 주입)

Kubernetes ConfigMap으로 환경변수를 주입하는 경우 (권장):

```bash
# 프로젝트 루트에서 실행
docker build -t dailyfeed-frontend:latest .

# 빌드 확인
docker images | grep dailyfeed-frontend

# 로컬에서 테스트 - Local WAS 포트 사용 (환경변수 전달)
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_MEMBER_SERVICE_URL=http://host.docker.internal:8084 \
  -e NEXT_PUBLIC_CONTENT_SERVICE_URL=http://host.docker.internal:8081 \
  -e NEXT_PUBLIC_TIMELINE_SERVICE_URL=http://host.docker.internal:8082 \
  -e NEXT_PUBLIC_ACTIVITY_SERVICE_URL=http://host.docker.internal:8086 \
  -e NEXT_PUBLIC_IMAGE_SERVICE_URL=http://host.docker.internal:8085 \
  -e NEXT_PUBLIC_SEARCH_SERVICE_URL=http://host.docker.internal:8083 \
  dailyfeed-frontend:latest
```

### 빌드 시 환경변수 고정 (선택사항)

특정 환경의 URL을 이미지에 고정하려면:

```bash
# Local K8s 환경용 빌드 (모든 서비스 8080 포트 사용)
docker build \
  --build-arg NEXT_PUBLIC_MEMBER_SERVICE_URL=http://dailyfeed-member:8080 \
  --build-arg NEXT_PUBLIC_CONTENT_SERVICE_URL=http://dailyfeed-content:8080 \
  --build-arg NEXT_PUBLIC_TIMELINE_SERVICE_URL=http://dailyfeed-timeline:8080 \
  --build-arg NEXT_PUBLIC_ACTIVITY_SERVICE_URL=http://dailyfeed-activity:8080 \
  --build-arg NEXT_PUBLIC_IMAGE_SERVICE_URL=http://dailyfeed-image:8080 \
  --build-arg NEXT_PUBLIC_SEARCH_SERVICE_URL=http://dailyfeed-search:8080 \
  -t dailyfeed-frontend:local-k8s .
```

### 이미지 레지스트리에 Push

```bash
# Docker Hub
docker tag dailyfeed-frontend:latest <your-dockerhub-username>/dailyfeed-frontend:latest
docker push <your-dockerhub-username>/dailyfeed-frontend:latest

# 또는 사설 레지스트리
docker tag dailyfeed-frontend:latest your-registry.com/dailyfeed-frontend:latest
docker push your-registry.com/dailyfeed-frontend:latest
```

### deployment.yaml 이미지 경로 수정

Push한 이미지를 사용하도록 수정:

```yaml
spec:
  containers:
  - name: dailyfeed-frontend
    image: <your-registry>/dailyfeed-frontend:latest
    imagePullPolicy: Always  # 또는 IfNotPresent
```

### 로컬 이미지 사용 (레지스트리 없이)

Docker Desktop 또는 OrbStack에서 로컬 이미지를 직접 사용:

```yaml
spec:
  containers:
  - name: dailyfeed-frontend
    image: dailyfeed-frontend:latest
    imagePullPolicy: Never  # 로컬 이미지만 사용
```

### 빌드 최적화 팁

```bash
# 멀티 플랫폼 빌드 (Apple Silicon Mac에서 권장)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t dailyfeed-frontend:latest .

# 빌드 캐시 사용 안 함 (클린 빌드)
docker build --no-cache -t dailyfeed-frontend:latest .

# 빌드 진행 상황 상세 출력
docker build --progress=plain -t dailyfeed-frontend:latest .
```

### Dockerfile 빌드 프로세스 상세

Dockerfile은 다음과 같이 동작합니다:

1. **의존성 설치 최적화**
   - `deps` 스테이지: 프로덕션 의존성만 설치 (`--only=production`)
   - `builder` 스테이지: devDependencies 포함 전체 설치
   - 이유: TypeScript, ESLint 등이 빌드에 필요하기 때문

2. **빌드 타임 환경변수**
   - `--build-arg`로 환경변수를 전달하면 빌드 시 고정됨
   - 전달하지 않으면 런타임에 ConfigMap으로 주입 가능

3. **최종 이미지 최적화**
   - 빌드된 `.next/standalone` 파일만 복사
   - Node.js 런타임 + 빌드 결과물만 포함
   - 소스 코드, node_modules 제외로 크기 최소화

4. **보안 강화**
   - Alpine Linux 기반 (작은 이미지)
   - Non-root 사용자(UID 1001) 실행
   - 불필요한 파일 제외

## 스케일링

```bash
# 레플리카 수 변경
kubectl scale deployment dailyfeed-frontend -n dailyfeed --replicas=3

# 현재 레플리카 수 확인
kubectl get deployment dailyfeed-frontend -n dailyfeed
```

## 업데이트 배포

```bash
# 새 이미지 빌드 및 Push
docker build -t dailyfeed-frontend:v2 .
docker push <your-registry>/dailyfeed-frontend:v2

# Deployment 이미지 업데이트
kubectl set image deployment/dailyfeed-frontend \
  dailyfeed-frontend=<your-registry>/dailyfeed-frontend:v2 \
  -n dailyfeed

# 롤아웃 상태 확인
kubectl rollout status deployment/dailyfeed-frontend -n dailyfeed

# 이전 버전으로 롤백 (필요시)
kubectl rollout undo deployment/dailyfeed-frontend -n dailyfeed
```

## HTTPS/TLS 설정

### 방법 1: cert-manager를 이용한 자동 인증서 관리 (권장)

cert-manager는 Let's Encrypt를 통해 무료 SSL/TLS 인증서를 자동으로 발급하고 갱신합니다.

#### 1. cert-manager 설치

```bash
# cert-manager 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 설치 확인
kubectl get pods -n cert-manager

# 모든 Pod가 Running 상태인지 확인
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
```

#### 2. ClusterIssuer 생성

Let's Encrypt를 위한 ClusterIssuer를 생성합니다:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt 프로덕션 서버
    server: https://acme-v02.api.letsencrypt.org/directory
    # 알림을 받을 이메일 주소
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

**Staging 환경 테스트용** (Rate Limit 없음):
```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

#### 3. Ingress에 TLS 설정 추가

`k8s/ingress.yaml` 파일을 수정:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dailyfeed-frontend
  namespace: dailyfeed
  labels:
    app: dailyfeed-frontend
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    # cert-manager 어노테이션 추가
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # HTTP를 HTTPS로 리다이렉트
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - dailyfeed.yourdomain.com  # 실제 도메인으로 변경
    secretName: dailyfeed-frontend-tls  # 인증서가 저장될 Secret 이름
  rules:
  - host: dailyfeed.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dailyfeed-frontend
            port:
              number: 3000
```

#### 4. Ingress 배포 및 확인

```bash
# Ingress 배포
kubectl apply -f k8s/ingress.yaml

# Certificate 생성 확인
kubectl get certificate -n dailyfeed
kubectl describe certificate dailyfeed-frontend-tls -n dailyfeed

# CertificateRequest 확인
kubectl get certificaterequest -n dailyfeed

# Secret 생성 확인 (인증서가 저장됨)
kubectl get secret dailyfeed-frontend-tls -n dailyfeed
```

**상태 확인**:
```bash
# Certificate 상태가 "True"가 되어야 함
kubectl get certificate -n dailyfeed -o wide

# 로그 확인 (문제 발생 시)
kubectl logs -n cert-manager deploy/cert-manager -f
```

#### 5. 접속 테스트

```bash
# HTTPS로 접속
https://dailyfeed.yourdomain.com

# 인증서 확인
curl -v https://dailyfeed.yourdomain.com 2>&1 | grep "SSL certificate"
```

### 방법 2: 수동으로 인증서 생성 및 적용

기존 인증서가 있거나 자체 서명 인증서를 사용하는 경우:

#### 1. 인증서 준비

```bash
# 자체 서명 인증서 생성 (테스트용)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=dailyfeed.local/O=dailyfeed"

# Kubernetes Secret 생성
kubectl create secret tls dailyfeed-frontend-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n dailyfeed
```

#### 2. 기존 인증서 사용

```bash
# 기존 인증서 파일로 Secret 생성
kubectl create secret tls dailyfeed-frontend-tls \
  --cert=/path/to/your/certificate.crt \
  --key=/path/to/your/private.key \
  -n dailyfeed
```

#### 3. Ingress 수정

```yaml
spec:
  tls:
  - hosts:
    - dailyfeed.yourdomain.com
    secretName: dailyfeed-frontend-tls
  rules:
  - host: dailyfeed.yourdomain.com
    # ... 나머지 설정
```

### 트러블슈팅

#### Certificate가 Ready 상태가 안 됨

```bash
# Certificate 상세 확인
kubectl describe certificate dailyfeed-frontend-tls -n dailyfeed

# Challenge 확인 (Let's Encrypt 검증 과정)
kubectl get challenge -n dailyfeed
kubectl describe challenge <challenge-name> -n dailyfeed

# cert-manager 로그 확인
kubectl logs -n cert-manager deploy/cert-manager --tail=100
```

**일반적인 문제**:
- 도메인이 Ingress IP를 제대로 가리키지 않음
- 방화벽이 80/443 포트를 차단
- Ingress Controller가 제대로 동작하지 않음

#### HTTP-01 Challenge 실패

```bash
# Ingress가 제대로 동작하는지 확인
kubectl get ingress -n dailyfeed
curl http://dailyfeed.yourdomain.com/.well-known/acme-challenge/test

# 도메인 DNS 확인
nslookup dailyfeed.yourdomain.com
dig dailyfeed.yourdomain.com
```

#### Rate Limit 오류

Let's Encrypt는 시간당 발급 제한이 있습니다:
- 먼저 `letsencrypt-staging`으로 테스트
- 정상 동작 확인 후 `letsencrypt-prod`로 변경

### 보안 강화

#### 1. HSTS (HTTP Strict Transport Security) 활성화

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains; preload";
```

#### 2. TLS 버전 제한

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
```

#### 3. 자동 HTTP → HTTPS 리다이렉트

이미 위에서 설정했지만, 확인:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

## Spring Cloud Gateway 도입 준비

현재는 Frontend가 각 백엔드 서비스에 직접 연결하고 있습니다. Spring Cloud Gateway 도입 시:

1. Gateway Service 배포 (예: `dailyfeed-gateway:8080`)
2. ConfigMap 수정:
   ```yaml
   data:
     NEXT_PUBLIC_API_GATEWAY_URL: "http://dailyfeed-gateway:8080"
   ```
3. Frontend 코드 수정: 모든 API 호출을 Gateway로 라우팅

## 리소스 관리

현재 설정:
- CPU Request: 250m (0.25 코어)
- CPU Limit: 500m (0.5 코어)
- Memory Request: 256Mi
- Memory Limit: 512Mi

필요에 따라 `deployment.yaml`의 `resources` 섹션을 조정하세요.

## 보안 고려사항

1. **환경변수 보안**: 민감한 정보는 ConfigMap 대신 Secret 사용
2. **이미지 보안**: 정기적인 보안 스캔 및 업데이트
3. **네트워크 정책**: 필요한 트래픽만 허용하도록 NetworkPolicy 설정
4. **RBAC**: 최소 권한 원칙에 따라 ServiceAccount 구성

## 추가 정보

프로젝트 구조:
- `/k8s/` - Kubernetes 매니페스트 파일
- `/src/config/env.ts` - 환경 설정 중앙화
- `/src/lib/auth.ts` - 백엔드 API 호출 로직
- `/.env` - 로컬 개발 환경변수

  1. ✅ Jib로 Docker 이미지 빌드 (alpha300uk/dailyfeed-member-svc:0.0.2)
  2. ✅ values-local-member.yaml - appName을 dailyfeed-member로 수정
  3. ✅ values-local-member.yaml - SERVER_PORT=8080 환경변수 추가
  4. ✅ SecurityConfig.java:89 - /healthcheck/** 경로를 permitAll()에 추가
  5. ✅ 이미지 태그를 0.0.2로 변경하여 캐시 문제 해결
  6. ✅ kind load docker-image로 이미지를 클러스터에 로드
  7. ✅ startup probe failureThreshold를 60으로 증가
#!/bin/bash

# HPA (Horizontal Pod Autoscaler) 설정을 적용하는 스크립트
# 사용법: ./apply-hpa-configs.sh [service-name]
# 예시: ./apply-hpa-configs.sh activity
#       ./apply-hpa-configs.sh (모든 서비스 적용)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES=("activity" "content" "image" "member" "search" "timeline" "frontend")

apply_service_hpa() {
    local service=$1
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📈 Applying HPA for: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # HPA 적용
    if [ -f "$SCRIPT_DIR/hpa-${service}.yaml" ]; then
        echo "  ⚙️  Applying HPA for $service..."
        kubectl apply -f "$SCRIPT_DIR/hpa-${service}.yaml"
        if [ $? -eq 0 ]; then
            echo "  ✅ HPA applied successfully"
        else
            echo "  ❌ Failed to apply HPA"
            return 1
        fi
    else
        echo "  ⚠️  HPA file not found: hpa-${service}.yaml"
        return 1
    fi

    echo ""
}

verify_hpa() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Verifying HPA Configurations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "📋 HorizontalPodAutoscalers in namespace 'dailyfeed':"
    kubectl get hpa -n dailyfeed

    echo ""
    echo "📊 Detailed HPA status (with metrics):"
    kubectl get hpa -n dailyfeed -o wide

    echo ""
}

check_metrics_server() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Checking Metrics Server"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # metrics-server deployment 확인
    METRICS_SERVER_STATUS=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)

    if [ "$METRICS_SERVER_STATUS" = "True" ]; then
        echo "  ✅ metrics-server is running"
    else
        echo "  ❌ metrics-server is not running or not ready"
        echo ""
        echo "  HPA requires metrics-server to be installed and running."
        echo "  Please run the metrics-server installation script first:"
        echo "  cd ../../dailyfeed-infrastructure/helm"
        echo "  source install-metrics-server.sh"
        echo ""
        return 1
    fi

    # Pod metrics 사용 가능 여부 확인
    echo ""
    if kubectl top pods -n dailyfeed &>/dev/null; then
        echo "  ✅ Pod metrics are available"
    else
        echo "  ⚠️  Pod metrics not yet available"
        echo "  Wait ~1 minute for metrics collection to start"
    fi

    echo ""
}

show_usage() {
    echo "Usage: $0 [service-name]"
    echo ""
    echo "Available services:"
    for svc in "${SERVICES[@]}"; do
        echo "  - $svc"
    done
    echo ""
    echo "Examples:"
    echo "  $0              # Apply all services"
    echo "  $0 activity     # Apply only activity service"
    echo ""
}

main() {
    echo ""
    echo "🚀 HPA Configuration Deployment Script"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # metrics-server 확인
    check_metrics_server
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 특정 서비스만 적용
    if [ -n "$1" ]; then
        if [[ " ${SERVICES[@]} " =~ " $1 " ]]; then
            apply_service_hpa "$1"
        else
            echo "❌ Unknown service: $1"
            echo ""
            show_usage
            exit 1
        fi
    # 모든 서비스 적용
    else
        echo "📦 Applying HPA configs for all services..."
        echo ""

        for service in "${SERVICES[@]}"; do
            apply_service_hpa "$service"
        done
    fi

    # 설정 확인
    verify_hpa

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ HPA configuration deployment completed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Useful commands:"
    echo "  # Watch HPA status in real-time"
    echo "  watch kubectl get hpa -n dailyfeed"
    echo ""
    echo "  # Describe specific HPA"
    echo "  kubectl describe hpa <hpa-name> -n dailyfeed"
    echo ""
    echo "  # Check current metrics"
    echo "  kubectl top pods -n dailyfeed"
    echo ""
    echo "  # View HPA events"
    echo "  kubectl get events -n dailyfeed --sort-by='.lastTimestamp' | grep HPA"
    echo ""
    echo "⚠️  Note: It may take 1-2 minutes for HPA to start showing metrics"
    echo ""
}

# 인자로 'help' 또는 '--help'가 전달되면 사용법 표시
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

main "$@"

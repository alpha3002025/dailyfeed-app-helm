#!/bin/bash

# Istio DestinationRule 및 VirtualService 설정을 적용하는 스크립트
# 사용법: ./apply-istio-configs.sh [service-name]
# 예시: ./apply-istio-configs.sh activity
#       ./apply-istio-configs.sh (모든 서비스 적용)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES=("activity" "content" "image" "member" "search" "timeline")

apply_service_config() {
    local service=$1
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📡 Applying Istio configs for: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # DestinationRule 적용
    if [ -f "$SCRIPT_DIR/destinationrule-${service}.yaml" ]; then
        echo "  ⚙️  Applying DestinationRule for $service..."
        kubectl apply -f "$SCRIPT_DIR/destinationrule-${service}.yaml"
        if [ $? -eq 0 ]; then
            echo "  ✅ DestinationRule applied successfully"
        else
            echo "  ❌ Failed to apply DestinationRule"
            return 1
        fi
    else
        echo "  ⚠️  DestinationRule file not found: destinationrule-${service}.yaml"
    fi

    echo ""

    # VirtualService 적용
    if [ -f "$SCRIPT_DIR/virtualservice-${service}.yaml" ]; then
        echo "  🌐 Applying VirtualService for $service..."
        kubectl apply -f "$SCRIPT_DIR/virtualservice-${service}.yaml"
        if [ $? -eq 0 ]; then
            echo "  ✅ VirtualService applied successfully"
        else
            echo "  ❌ Failed to apply VirtualService"
            return 1
        fi
    else
        echo "  ⚠️  VirtualService file not found: virtualservice-${service}.yaml"
    fi

    echo ""
}

verify_configs() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Verifying Istio Configurations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "📋 DestinationRules in namespace 'dailyfeed':"
    kubectl get destinationrules -n dailyfeed

    echo ""
    echo "📋 VirtualServices in namespace 'dailyfeed':"
    kubectl get virtualservices -n dailyfeed

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
    echo "🚀 Istio Configuration Deployment Script"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 특정 서비스만 적용
    if [ -n "$1" ]; then
        if [[ " ${SERVICES[@]} " =~ " $1 " ]]; then
            apply_service_config "$1"
        else
            echo "❌ Unknown service: $1"
            echo ""
            show_usage
            exit 1
        fi
    # 모든 서비스 적용
    else
        echo "📦 Applying Istio configs for all services..."
        echo ""

        for service in "${SERVICES[@]}"; do
            apply_service_config "$service"
        done
    fi

    # 설정 확인
    verify_configs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Istio configuration deployment completed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Useful commands:"
    echo "  # Describe DestinationRule"
    echo "  kubectl describe destinationrule <name> -n dailyfeed"
    echo ""
    echo "  # Describe VirtualService"
    echo "  kubectl describe virtualservice <name> -n dailyfeed"
    echo ""
    echo "  # Check Istio proxy configuration"
    echo "  istioctl proxy-config routes <pod-name> -n dailyfeed"
    echo ""
}

# 인자로 'help' 또는 '--help'가 전달되면 사용법 표시
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

main "$@"

#!/bin/bash

# Helm Cleanup Script for Resilience4j Stack
# Usage: ./cleanup.sh [release-name] [namespace] [--all]
# Examples:
#   ./cleanup.sh                                    # Clean default release in default namespace
#   ./cleanup.sh resilience4j-stack default        # Clean specific release and namespace
#   ./cleanup.sh --all                              # Clean all resilience4j releases

RELEASE_NAME=${1:-resilience4j-stack}
NAMESPACE=${2:-default}
CLEAN_ALL=false

if [ "$1" = "--all" ] || [ "$3" = "--all" ]; then
    CLEAN_ALL=true
fi

echo "🧹 Helm Cleanup for Resilience4j Stack"

# Stop port forwarding processes
echo "🔌 Stopping port forwarding processes..."
if command -v pkill >/dev/null 2>&1; then
    pkill -f "kubectl port-forward" || true
else
    taskkill /F /IM kubectl.exe >nul 2>&1 || true
fi

if [ "$CLEAN_ALL" = true ]; then
    echo "🗑️ Cleaning ALL resilience4j Helm releases..."
    
    # Find all resilience4j releases across all namespaces
    RELEASES=$(helm list --all-namespaces | grep resilience4j | awk '{print $1 ":" $2}')
    
    if [ -z "$RELEASES" ]; then
        echo "No resilience4j releases found"
    else
        echo "Found releases:"
        echo "$RELEASES"
        echo
        
        for release_info in $RELEASES; do
            rel_name=$(echo $release_info | cut -d':' -f1)
            rel_namespace=$(echo $release_info | cut -d':' -f2)
            echo "Uninstalling release: $rel_name in namespace: $rel_namespace"
            helm uninstall $rel_name -n $rel_namespace || true
        done
    fi
    
    # Clean up namespaces
    echo "🗑️ Cleaning resilience4j namespaces..."
    for ns in resilience4j-local resilience4j-aws-single resilience4j-aws-multi; do
        if kubectl get namespace $ns >/dev/null 2>&1; then
            echo "Deleting namespace: $ns"
            kubectl delete namespace $ns --timeout=60s || true
        fi
    done
    
else
    echo "🗑️ Cleaning Helm release: $RELEASE_NAME in namespace: $NAMESPACE"
    
    # Check if release exists
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        echo "Uninstalling Helm release: $RELEASE_NAME"
        helm uninstall $RELEASE_NAME -n $NAMESPACE || true
    else
        echo "Release $RELEASE_NAME not found in namespace $NAMESPACE"
    fi
    
    # Clean up namespace if it's a resilience4j namespace and empty
    if [[ $NAMESPACE == resilience4j-* ]]; then
        echo "Checking if namespace $NAMESPACE can be cleaned up..."
        REMAINING_RESOURCES=$(kubectl get all -n $NAMESPACE 2>/dev/null | wc -l)
        if [ $REMAINING_RESOURCES -le 1 ]; then
            echo "Deleting empty namespace: $NAMESPACE"
            kubectl delete namespace $NAMESPACE --timeout=60s || true
        else
            echo "Namespace $NAMESPACE still has resources, keeping it"
        fi
    fi
fi

# Wait for cleanup
echo "⏳ Waiting for cleanup to complete..."
sleep 10

# Force cleanup any stuck resources
echo "🔨 Force cleaning any stuck resources..."
for ns in resilience4j-local resilience4j-aws-single resilience4j-aws-multi; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo "Force cleaning namespace: $ns"
        kubectl delete all --all -n $ns --force --grace-period=0 || true
        kubectl delete pvc --all -n $ns --force --grace-period=0 || true
        kubectl delete configmaps --all -n $ns --force --grace-period=0 || true
        kubectl delete secrets --all -n $ns --force --grace-period=0 || true
        kubectl delete hpa --all -n $ns --force --grace-period=0 || true
        kubectl delete vpa --all -n $ns --force --grace-period=0 || true
    fi
done

# Clean up persistent volumes
echo "💾 Cleaning up persistent volumes..."
PVS=$(kubectl get pv | grep resilience4j | awk '{print $1}')
if [ -n "$PVS" ]; then
    echo "Found persistent volumes: $PVS"
    for pv in $PVS; do
        echo "Deleting PV: $pv"
        kubectl delete pv $pv || true
    done
fi

echo "✅ Helm cleanup completed!"
echo "📊 Remaining Helm releases:"
helm list --all-namespaces | grep resilience4j || echo "No resilience4j releases found"
echo "📊 Remaining namespaces:"
kubectl get namespaces | grep resilience4j || echo "No resilience4j namespaces found"
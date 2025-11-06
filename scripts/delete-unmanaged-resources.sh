#!/bin/bash
# Delete resources that are NOT managed by FluxCD
# This removes resources created before FluxCD was installed

set -e

# System namespaces to exclude
EXCLUDE_NS="kube-system|flux-system|kube-public|kube-node-lease"

echo "=== WARNING: This will delete resources NOT managed by FluxCD ==="
echo "These are resources that were created before FluxCD installation."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "=== Deleting Unmanaged Resources ==="

# Function to delete resources
delete_resources() {
    local kind=$1
    local namespace_arg=$2
    
    echo -e "\n--- Deleting $kind ---"
    kubectl get $kind $namespace_arg -o json 2>/dev/null | \
      jq -r --arg exclude "$EXCLUDE_NS" --arg kind "$kind" '.items[] | 
        select(.metadata.namespace | test($exclude) | not) |
        select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
        "\(.metadata.namespace)/\(.metadata.name)"' | \
      while read -r resource; do
        if [ -n "$resource" ]; then
          namespace=$(echo "$resource" | cut -d'/' -f1)
          name=$(echo "$resource" | cut -d'/' -f2)
          echo "  Deleting $kind $namespace/$name..."
          kubectl delete $kind "$name" -n "$namespace" --ignore-not-found=true
        fi
      done
}

# Delete by namespace for better control
echo "Scanning for unmanaged resources..."

# Get list of namespaces (excluding system ones)
NAMESPACES=$(kubectl get namespaces -o json | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.name | test($exclude) | not) | 
    .metadata.name')

for ns in $NAMESPACES; do
    echo -e "\n=== Processing namespace: $ns ==="
    
    # Deployments
    for dep in $(kubectl get deployments -n "$ns" -o json 2>/dev/null | \
      jq -r '.items[] | 
        select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) | 
        .metadata.name'); do
      if [ -n "$dep" ]; then
        echo "  Deleting Deployment $ns/$dep..."
        kubectl delete deployment "$dep" -n "$ns" --ignore-not-found=true
      fi
    done
    
    # StatefulSets
    for sts in $(kubectl get statefulsets -n "$ns" -o json 2>/dev/null | \
      jq -r '.items[] | 
        select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) | 
        .metadata.name'); do
      if [ -n "$sts" ]; then
        echo "  Deleting StatefulSet $ns/$sts..."
        kubectl delete statefulset "$sts" -n "$ns" --ignore-not-found=true
      fi
    done
    
    # DaemonSets
    for ds in $(kubectl get daemonsets -n "$ns" -o json 2>/dev/null | \
      jq -r '.items[] | 
        select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) | 
        .metadata.name'); do
      if [ -n "$ds" ]; then
        echo "  Deleting DaemonSet $ns/$ds..."
        kubectl delete daemonset "$ds" -n "$ns" --ignore-not-found=true
      fi
    done
    
    # Services (but keep headless and ClusterIP that might be needed)
    for svc in $(kubectl get services -n "$ns" -o json 2>/dev/null | \
      jq -r '.items[] | 
        select(.metadata.name != "kubernetes") |
        select(.spec.type != "ClusterIP" or .spec.clusterIP == "None" | not) |
        select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) | 
        .metadata.name'); do
      if [ -n "$svc" ]; then
        echo "  Deleting Service $ns/$svc..."
        kubectl delete service "$svc" -n "$ns" --ignore-not-found=true
      fi
    done
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Remaining resources are either:"
echo "  - Managed by FluxCD (will be in Git repo)"
echo "  - System components (kube-system, flux-system)"
echo ""
echo "Check what's left with: kubectl get all --all-namespaces"


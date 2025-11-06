#!/bin/bash
# List resources that are NOT managed by FluxCD
# These are resources created before FluxCD was installed

echo "=== Resources NOT Managed by FluxCD ==="
echo "These are resources that were created before FluxCD and won't be pruned automatically."
echo ""

# System namespaces to exclude
EXCLUDE_NS="kube-system|flux-system|kube-public|kube-node-lease"

echo "=== Deployments ==="
kubectl get deployments --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    "\(.metadata.namespace)/\(.metadata.name) (created: \(.metadata.creationTimestamp))"'

echo ""
echo "=== StatefulSets ==="
kubectl get statefulsets --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    "\(.metadata.namespace)/\(.metadata.name) (created: \(.metadata.creationTimestamp))"'

echo ""
echo "=== DaemonSets ==="
kubectl get daemonsets --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    "\(.metadata.namespace)/\(.metadata.name) (created: \(.metadata.creationTimestamp))"'

echo ""
echo "=== Services ==="
kubectl get services --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.spec.type != "ClusterIP" or .spec.clusterIP != "None") |  # Skip headless services
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    select(.metadata.name != "kubernetes") |  # Skip default kubernetes service
    "\(.metadata.namespace)/\(.metadata.name) (type: \(.spec.type))"'

echo ""
echo "=== ConfigMaps ==="
kubectl get configmaps --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    "\(.metadata.namespace)/\(.metadata.name)"'

echo ""
echo "=== Secrets ==="
kubectl get secrets --all-namespaces -o json 2>/dev/null | \
  jq -r --arg exclude "$EXCLUDE_NS" '.items[] | 
    select(.metadata.namespace | test($exclude) | not) |
    select(.type != "kubernetes.io/service-account-token") |  # Skip service account tokens
    select(.metadata.labels."kustomize.toolkit.fluxcd.io/name" // .metadata.labels."helm.toolkit.fluxcd.io/name" | not) |
    "\(.metadata.namespace)/\(.metadata.name) (type: \(.type))"'

echo ""
echo "=== To delete these resources, use: ==="
echo "./scripts/delete-unmanaged-resources.sh"


#!/bin/bash
# List resources managed by FluxCD

echo "=== Resources Managed by FluxCD (Kustomization) ==="
echo "These resources will be pruned if removed from Git:"
echo ""

# Get all resources with FluxCD labels
echo "Resources with FluxCD labels:"
kubectl get all --all-namespaces -l 'kustomize.toolkit.fluxcd.io/name' 2>/dev/null || echo "None found"

echo ""
echo "=== Helm Releases Managed by FluxCD ==="
kubectl get helmreleases --all-namespaces

echo ""
echo "=== To see all FluxCD-managed resources ==="
echo "kubectl get all --all-namespaces -l 'kustomize.toolkit.fluxcd.io/name'"
echo "kubectl get all --all-namespaces -l 'helm.toolkit.fluxcd.io/name'"


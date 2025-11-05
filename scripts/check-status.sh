#!/bin/bash
# Quick FluxCD status check script

echo "=== FluxCD Pods Status ==="
kubectl get pods -n flux-system

echo -e "\n=== FluxCD Resources Status ==="
kubectl get gitrepositories,kustomizations -n flux-system

echo -e "\n=== GitRepository Details ==="
kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq -r '"Status: \(.status) | Reason: \(.reason) | Message: \(.message)"' 2>/dev/null || kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'

echo -e "\n=== Kustomization Details ==="
kubectl get kustomization flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq -r '"Status: \(.status) | Reason: \(.reason) | Message: \(.message)"' 2>/dev/null || kubectl get kustomization flux-system -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'

echo -e "\n=== Last Sync Info ==="
echo "GitRepository last sync:"
kubectl get gitrepository flux-system -n flux-system -o jsonpath='{.status.artifact.revision}' 2>/dev/null || echo "N/A"
echo ""
echo "Kustomization last sync:"
kubectl get kustomization flux-system -n flux-system -o jsonpath='{.status.lastAppliedRevision}' 2>/dev/null || echo "N/A"


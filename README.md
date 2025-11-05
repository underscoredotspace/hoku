# Hoku - FluxCD GitOps Repository

This repository contains the FluxCD configuration for managing Kubernetes clusters.

## Structure

```
clusters/
  default/
    flux-system/
      - gotk-sync.yaml      # FluxCD sync configuration
      - kustomization.yaml   # Kustomization for flux-system
```

## Setup

1. Install FluxCD CLI:
   ```bash
   curl -s https://fluxcd.io/install.sh | sudo bash
   ```

2. Bootstrap FluxCD on your cluster:
   ```bash
   flux bootstrap github \
     --owner=your-org \
     --repository=hoku \
     --branch=main \
     --path=./clusters/default
   ```

3. Update the GitRepository URL in `clusters/default/flux-system/gotk-sync.yaml` with your actual repository URL.

## Adding Resources

Add Kubernetes manifests to `clusters/default/` and they will be automatically synced by FluxCD.

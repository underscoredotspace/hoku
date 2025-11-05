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

2. Create a GitHub Personal Access Token (PAT):
   - Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
   - Click "Generate new token" (classic)
   - Set permissions:
     - ✅ `repo` - Full control of private repositories
     - ✅ `admin:repo_hook` - Full control of repository hooks
   - Copy the token (you won't see it again!)
   - Export it: `export GITHUB_TOKEN=<your-token>`

3. Bootstrap FluxCD on your cluster:
   ```bash
   flux bootstrap github \
     --owner=underscoredotspace \
     --repository=hoku \
     --branch=main \
     --path=./clusters/default
   ```

3. Update the GitRepository URL in `clusters/default/flux-system/gotk-sync.yaml` with your actual repository URL.

## Adding Resources

Add Kubernetes manifests to `clusters/default/` and they will be automatically synced by FluxCD.

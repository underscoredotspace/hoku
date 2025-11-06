# Hoku - FluxCD GitOps Repository

This repository contains the FluxCD configuration for managing Kubernetes clusters.

## Structure

```
clusters/
  default/
    flux-system/           # FluxCD's own configuration
      - gotk-sync.yaml
      - kustomization.yaml
    infrastructure/        # Infrastructure components (Traefik, etc.)
      - traefik/
        - helm-repository.yaml
        - helm-release.yaml
    apps/                  # Your applications
      - README.md
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

## Checking Status

Quick health check:
```bash
kubectl get gitrepositories,kustomizations -n flux-system
```

Full status check:
```bash
kubectl get pods,gitrepositories,kustomizations -n flux-system
```

Detailed status (if Flux CLI is installed):
```bash
flux get all
```

Or use the status script:
```bash
./scripts/check-status.sh
```

## Apps vs Infrastructure

This repository separates **infrastructure** components from **applications** for better organization and management.

### Infrastructure (`infrastructure/`)

**Infrastructure** components are cluster-wide services that support your applications. They are:
- **Shared across applications** - Used by multiple apps or the entire cluster
- **Platform-level** - Provide foundational services (networking, monitoring, storage, etc.)
- **Long-lived** - Typically deployed once and updated infrequently
- **Managed by platform teams** - Usually configured by DevOps/SRE teams

**Examples:**
- **Ingress Controllers** (Traefik, NGINX, etc.) - Routes traffic to applications
- **Service Mesh** (Istio, Linkerd) - Manages inter-service communication
- **Monitoring** (Prometheus, Grafana) - Observability stack
- **Logging** (Loki, ELK) - Centralized logging
- **Storage** (CSI drivers, storage classes) - Persistent storage providers
- **Security** (cert-manager, OPA) - Security and policy enforcement
- **GitOps Tools** (FluxCD itself, ArgoCD) - Deployment automation

**Structure:**
```
infrastructure/
  traefik/              # Ingress controller
    - helm-repository.yaml
    - helm-release.yaml
  cert-manager/         # Certificate management
    - helm-release.yaml
  monitoring/           # Observability stack
    - prometheus/
    - grafana/
```

### Applications (`apps/`)

**Applications** are your business logic and services. They are:
- **Application-specific** - Each app has its own purpose and lifecycle
- **Business-focused** - Deliver value to end users or other services
- **Frequently updated** - Code changes deployed regularly
- **Managed by development teams** - Owned by application developers

**Examples:**
- **Web Applications** - Frontend/backend services
- **APIs** - REST or GraphQL APIs
- **Microservices** - Individual service components
- **Databases** - Application-specific databases (if not shared infrastructure)
- **Workers** - Background job processors
- **Scheduled Jobs** - Cron jobs or scheduled tasks

**Structure:**
```
apps/
  frontend/             # Your web frontend
    - helm-release.yaml
    - values.yaml
  api/                  # Your API service
    - kustomization.yaml
    - deployment.yaml
    - service.yaml
  worker/               # Background worker
    - helm-release.yaml
```

### Key Differences

| Aspect | Infrastructure | Applications |
|--------|----------------|--------------|
| **Purpose** | Platform services | Business logic |
| **Scope** | Cluster-wide | Application-specific |
| **Update Frequency** | Infrequent | Frequent |
| **Ownership** | Platform/DevOps | Development teams |
| **Dependencies** | Independent | May depend on infrastructure |
| **Examples** | Traefik, cert-manager | Web apps, APIs, services |

### When to Use Each

**Put in `infrastructure/` if:**
- ✅ Used by multiple applications
- ✅ Provides a platform-level service
- ✅ Managed by platform/DevOps team
- ✅ Changes affect the entire cluster

**Put in `apps/` if:**
- ✅ Delivers business value directly
- ✅ Owned by a specific development team
- ✅ Has its own release cycle
- ✅ Can be deployed/updated independently

## Adding Resources

### Infrastructure Components

Add infrastructure components to `clusters/default/infrastructure/`. Each component should have its own folder:

```
infrastructure/
  traefik/
    - helm-repository.yaml
    - helm-release.yaml
  cert-manager/
    - helm-release.yaml
```

### Applications

Add your applications to `clusters/default/apps/`. Each app should have its own folder:

```
apps/
  my-app/
    - helm-release.yaml
    - values.yaml
  another-app/
    - kustomization.yaml
    - deployment.yaml
    - service.yaml
```

All resources in `clusters/default/` will be automatically synced by FluxCD.

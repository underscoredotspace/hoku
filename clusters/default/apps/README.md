# Applications

This directory contains your business applications and services.

## What Goes Here

**Applications** are your business logic and services that deliver value to end users or other services. Examples include:
- Web applications (frontend/backend)
- APIs (REST, GraphQL)
- Microservices
- Background workers
- Scheduled jobs
- Application-specific databases

## Structure

Each application should have its own folder with its deployment configuration:

```
apps/
  my-web-app/
    - helm-release.yaml      # If using Helm
    - values.yaml            # Helm values (optional)
  
  my-api/
    - kustomization.yaml     # If using Kustomize
    - deployment.yaml
    - service.yaml
    - configmap.yaml
```

## Adding a New Application

### Using Helm (Recommended)

1. Create a folder for your app:
   ```bash
   mkdir -p apps/my-app
   ```

2. Create a HelmRelease:
   ```yaml
   apiVersion: helm.toolkit.fluxcd.io/v2
   kind: HelmRelease
   metadata:
     name: my-app
     namespace: my-app
   spec:
     interval: 5m0s
     chart:
       spec:
         chart: my-app
         sourceRef:
           kind: HelmRepository
           name: my-chart-repo
           namespace: flux-system
         version: "*"
     install:
       createNamespace: true
     values:
       # Your app-specific values
   ```

### Using Kustomize

1. Create a folder for your app:
   ```bash
   mkdir -p apps/my-app
   ```

2. Create your Kubernetes manifests and a kustomization.yaml:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - deployment.yaml
     - service.yaml
     - configmap.yaml
   ```

## Best Practices

- ✅ Each app gets its own folder
- ✅ Use descriptive names for folders
- ✅ Keep app-specific configs in the app folder
- ✅ Use Helm for complex apps, Kustomize for simple ones
- ✅ Create namespaces for your apps (or let HelmRelease do it)

## What NOT to Put Here

Don't put infrastructure components here. Those go in `../infrastructure/`:
- ❌ Ingress controllers (Traefik, NGINX)
- ❌ Monitoring (Prometheus, Grafana)
- ❌ Service mesh
- ❌ Certificate managers
- ❌ Storage providers

See `../infrastructure/` for platform-level services.


# Infrastructure

This directory contains cluster-wide infrastructure components that support your applications.

## What Goes Here

**Infrastructure** components are platform-level services that provide foundational capabilities for your cluster and applications. Examples include:
- **Ingress Controllers** (Traefik, NGINX, etc.) - Routes external traffic to applications
- **Service Mesh** (Istio, Linkerd) - Manages inter-service communication and traffic
- **Monitoring** (Prometheus, Grafana) - Observability and metrics collection
- **Logging** (Loki, ELK stack) - Centralized log aggregation
- **Certificate Management** (cert-manager) - Automated SSL/TLS certificates
- **Storage** (CSI drivers) - Persistent volume providers
- **Security** (OPA, Falco) - Policy enforcement and security scanning
- **DNS** (ExternalDNS) - Automatic DNS record management

## Structure

Each infrastructure component should have its own folder:

```
infrastructure/
  traefik/              # Ingress controller
    - helm-repository.yaml
    - helm-release.yaml
  cert-manager/         # Certificate management
    - helm-release.yaml
  monitoring/           # Observability stack
    - prometheus/
      - helm-release.yaml
    - grafana/
      - helm-release.yaml
```

## Adding a New Infrastructure Component

### Using Helm (Recommended)

1. Create a folder for the component:
   ```bash
   mkdir -p infrastructure/my-component
   ```

2. Create a HelmRepository (if not already exists):
   ```yaml
   apiVersion: source.toolkit.fluxcd.io/v1
   kind: HelmRepository
   metadata:
     name: my-component
     namespace: flux-system
   spec:
     interval: 1h0m0s
     url: https://charts.example.com
   ```

3. Create a HelmRelease:
   ```yaml
   apiVersion: helm.toolkit.fluxcd.io/v2
   kind: HelmRelease
   metadata:
     name: my-component
     namespace: my-component
   spec:
     interval: 5m0s
     chart:
       spec:
         chart: my-component
         sourceRef:
           kind: HelmRepository
           name: my-component
           namespace: flux-system
         version: "*"
     install:
       createNamespace: true
     values:
       # Component-specific values
   ```

## Best Practices

- ✅ Each component gets its own folder
- ✅ Use descriptive, standard names (traefik, cert-manager, etc.)
- ✅ Keep component-specific configs in the component folder
- ✅ Document why each component is needed
- ✅ Infrastructure should be stable - changes affect the entire cluster

## What NOT to Put Here

Don't put applications here. Those go in `../apps/`:
- ❌ Web applications
- ❌ APIs
- ❌ Microservices
- ❌ Business logic services
- ❌ Application-specific databases

See `../apps/` for business applications.


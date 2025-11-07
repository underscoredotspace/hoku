# Docker Compose to Kubernetes Conversion Guide

This document explains how the qbittorrent Docker Compose configuration was converted to Kubernetes using native manifests, Flux, and Traefik.

## Overview

The original Docker Compose setup has been converted to a Kubernetes-native deployment using:
- **Native Kubernetes manifests** (Deployment, Service) - Direct Docker image deployment
- **ConfigMaps/PVCs** for configuration and storage (idiomatic K8s approach)
- **Traefik IngressRoute** for external access
- **Flux GitOps** for automatic deployment

## Conversion Mapping

### Docker Compose → Kubernetes

| Docker Compose | Kubernetes Equivalent | Location |
|---------------|----------------------|----------|
| `image: lscr.io/linuxserver/qbittorrent:latest` | Deployment `spec.template.spec.containers[0].image` | `deployment.yaml` |
| `environment:` variables | Deployment `env:` | `deployment.yaml` |
| `/opt/docker/qbittorrent/appdata:/config` | PVC `qbittorrent-config` | `config-pvc.yaml` |
| `torrents:/downloads` (NFS volume) | PV/PVC `qbittorrent-downloads` | `nfs-pv.yaml` |
| `ports: 8080:8080` | Service + IngressRoute | `service.yaml` + `ingressroute.yaml` |
| `ports: 6881:6881` | Container ports only (not exposed via Service) | `deployment.yaml` |
| `restart: unless-stopped` | Deployment (default restart policy) | `deployment.yaml` |

## File Structure

```
apps/qbittorrent/
├── namespace.yaml                # Namespace definition
├── deployment.yaml               # Deployment with container spec
├── service.yaml                  # Service for internal access
├── config-pvc.yaml               # PersistentVolumeClaim for config data
├── nfs-pv.yaml                   # PersistentVolume + PVC for NFS downloads
├── ingressroute.yaml             # Traefik IngressRoute for web access
└── CONVERSION.md                 # This file
```

## Key Changes

### 1. Configuration Management

**Before (Docker Compose):**
- Environment variables defined inline in docker-compose.yaml
- Config stored in host path `/opt/docker/qbittorrent/appdata`

**After (Kubernetes):**
- Environment variables in Deployment `spec.template.spec.containers[0].env:`
- Config stored in PersistentVolumeClaim (PVC) for portability
- Can optionally use ConfigMaps for additional settings

### 2. Storage

**Before (Docker Compose):**
- Config: Host path mount
- Downloads: NFS volume defined in docker-compose

**After (Kubernetes):**
- Config: PVC (`qbittorrent-config`) - can use any storage class
- Downloads: PersistentVolume + PVC pointing to NFS server
- More flexible: can change storage backends without changing app config

### 3. Networking

**Before (Docker Compose):**
- Ports exposed directly on host: `8080:8080`, `6881:6881`

**After (Kubernetes):**
- Web UI (8080): Exposed via Traefik IngressRoute at `downloads.hoku.messy.cloud`
- Torrenting (6881): Container ports only (not exposed via Service)
- More secure: Only web UI exposed externally via Traefik; torrent ports are container-only
- Service is required for Traefik to route to the application (IngressRoute routes to Services, not Pods)

### 4. Deployment Management

**Before (Docker Compose):**
- Manual `docker-compose up/down` commands
- No automatic updates

**After (Kubernetes + Flux):**
- GitOps: Changes in Git automatically deployed
- Direct Docker image: No Helm chart abstraction
- Automatic reconciliation via Flux

## Step-by-Step Conversion Process

### Step 1: Create Namespace

Created `namespace.yaml` to define the `qbittorrent` namespace for resource isolation.

### Step 2: Create Deployment

Created `deployment.yaml` with:
- Image: Same as Docker Compose (`lscr.io/linuxserver/qbittorrent:latest`)
- Environment variables: Migrated from docker-compose
- Volume mounts: References PVCs for config and downloads
- Resource limits: Memory and CPU constraints
- Ports: Container ports for HTTP (8080) and torrenting (6881 TCP/UDP)

### Step 3: Create Service

Created `service.yaml` with:
- Type: ClusterIP (required for Traefik IngressRoute)
- Ports: HTTP (8080) only - this is what Traefik routes to
- Selector: Matches Deployment labels
- Note: Torrent ports (6881) are not exposed via Service - they're only container ports in the Deployment

### Step 4: Create Storage Resources

**Config Storage (`config-pvc.yaml`):**
- PVC for application configuration
- 10Gi storage (adjust as needed)
- ReadWriteOnce access mode

**Downloads Storage (`nfs-pv.yaml`):**
- PersistentVolume pointing to NFS server `10.102.1.186:/volume1/Torrents`
- PersistentVolumeClaim bound to the PV
- ReadWriteMany access mode (supports multiple pods if needed)

### Step 5: Create IngressRoute

Created `ingressroute.yaml` for Traefik:
- Domain: `downloads.hoku.messy.cloud`
- Entry points: `web` (HTTP) and `websecure` (HTTPS)
- Routes to qbittorrent service on port 8080

## Configuration Details

### Environment Variables

All environment variables from docker-compose are preserved in the Deployment:
- `PUID=1000` - User ID
- `PGID=1000` - Group ID
- `TZ=Etc/UTC` - Timezone
- `WEBUI_PORT=8080` - Web UI port
- `TORRENTING_PORT=6881` - Torrent port

### Ports

- **8080 (HTTP)**: Web UI, exposed via Traefik IngressRoute
  - Service exposes this port for Traefik to route to
  - Accessible at `downloads.hoku.messy.cloud`
- **6881 (TCP/UDP)**: Torrenting ports, container ports only
  - Defined in Deployment but not exposed via Service
  - Container listens on these ports for torrent peer connections
  - UPnP will attempt to configure port forwarding but won't work in Kubernetes
  - qBittorrent will still function but may show as "not connectable" (yellow icon)

### Storage

- **Config PVC**: Stores application configuration and state
  - Location: `/config` in container
  - Size: 10Gi (adjustable)
  
- **Downloads PV/PVC**: NFS mount for torrent downloads
  - NFS Server: `10.102.1.186`
  - NFS Path: `/volume1/Torrents`
  - Location: `/downloads` in container
  - Size: 1Ti (adjustable)

### Resources

The Deployment includes resource requests and limits:
- Requests: 256Mi memory, 100m CPU
- Limits: 2Gi memory, 2000m CPU

Adjust these based on your cluster's capacity and requirements.

## Deployment

1. **Commit files to Git repository**
2. **Flux will automatically:**
   - Create the `qbittorrent` namespace
   - Create the PersistentVolume and PVCs
   - Deploy the Deployment and Service
   - Create the IngressRoute

3. **Verify deployment:**
   ```bash
   # Check namespace
   kubectl get namespace qbittorrent
   
   # Check deployment
   kubectl get deployment -n qbittorrent
   
   # Check pods
   kubectl get pods -n qbittorrent
   
   # Check services
   kubectl get svc -n qbittorrent
   
   # Check IngressRoute
   kubectl get ingressroute -n qbittorrent
   
   # Check PVCs
   kubectl get pvc -n qbittorrent
   ```

## DNS Configuration

Ensure `downloads.hoku.messy.cloud` points to your Traefik ingress controller's IP address.

## TLS/HTTPS (Optional)

To enable HTTPS:
1. Install cert-manager (if not already installed)
2. Uncomment the `tls:` section in `ingressroute.yaml`
3. Configure your cert resolver (e.g., Let's Encrypt)

## Troubleshooting

### PVC not binding
- Check if storage class exists: `kubectl get storageclass`
- Verify NFS server is accessible from cluster nodes
- Check PV status: `kubectl get pv qbittorrent-downloads-pv`
- Check PVC status: `kubectl describe pvc qbittorrent-config -n qbittorrent`

### IngressRoute not working
- Verify Traefik is running: `kubectl get pods -n traefik`
- Check IngressRoute status: `kubectl describe ingressroute qbittorrent -n qbittorrent`
- Verify DNS points to Traefik LoadBalancer IP
- Check service exists: `kubectl get svc qbittorrent -n qbittorrent`

### Application not starting
- Check pod logs: `kubectl logs -n qbittorrent -l app=qbittorrent`
- Check pod status: `kubectl describe pod -n qbittorrent -l app=qbittorrent`
- Verify PVCs are bound: `kubectl get pvc -n qbittorrent`
- Check deployment status: `kubectl describe deployment qbittorrent -n qbittorrent`

### Image pull issues
- Verify image exists: `docker pull lscr.io/linuxserver/qbittorrent:latest`
- Check image pull secrets if using private registry
- Verify network connectivity from cluster nodes

## Next Steps

1. **Configure TLS** if you want HTTPS
2. **Adjust resource limits** in deployment.yaml if needed
3. **Set up monitoring** if desired (Prometheus, Grafana)
4. **Configure backups** for the config PVC
5. **Consider using ConfigMaps** for environment variables if you want to manage them separately

## Differences from Helm Chart Approach

This deployment uses **native Kubernetes manifests** instead of a Helm chart:
- ✅ Direct control over all resources
- ✅ No Helm chart dependencies
- ✅ Simpler for single-app deployments
- ✅ Easier to understand and modify
- ❌ More verbose than Helm values
- ❌ No templating/reusability features

For this use case (single Docker image deployment), native manifests are more appropriate than a Helm chart.

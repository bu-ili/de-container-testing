# Dagster k3d Testing Environment

Local Kubernetes testing environment for Dagster deployments using k3d.

## Prerequisites

- Docker Desktop
- k3d
- kubectl
- helm
- A Dagster user code project (e.g., `de-datalake-bulletin-dataload`)

## Setup

### 1. Create k3d Cluster

```bash
./setup-cluster.sh
```

This creates a k3d cluster with:
- Local registry on port 5000
- Ingress support (Traefik)
- Cluster name: `dagster-testing`

### 2. Build and Push User Code Image

```bash
./build-and-push.sh
```

Builds your Dagster user code Docker image and pushes to the local registry.

### 3. Deploy Dagster

```bash
./deploy-dagster.sh
```

Deploys Dagster using Helm with:
- PostgreSQL for storage
- K8sRunLauncher for job execution
- User code deployment (gRPC server)
- Ingress at `dagster.local`

## Configuration

### values.yaml

Main Helm values configuration for Dagster deployment. Customize:
- User deployment image repository
- Resource limits
- Storage configuration
- Ingress settings

### k3d-cluster-config.yaml

k3d cluster configuration including:
- Registry settings
- Port mappings
- Node configuration

## Accessing Dagster UI

The `deploy-dagster.sh` script automatically adds `dagster.local` to your `/etc/hosts` file.

Access the Dagster UI at: **http://dagster.local**

## Environment Secrets

Create `.env` file in your user code project with required environment variables:
```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_S3_BUCKET_NAME=...
# ... etc
```

The deploy script creates a Kubernetes secret from this file.

## Scripts

### Cluster Management
- `setup-cluster.sh` - Create k3d cluster with registry
- `deploy-dagster.sh` - Deploy Dagster with Helm (idempotent)

### Configuration
- `bulletin.conf` - Configuration for bulletin dataload project (image tags, deployment)

### Development Scripts
- `build-and-push.sh` - Build from source and push to k3d registry (fast local iteration)
- `sync-from-ghcr.sh` - Pull bulletin image from GHCR and sync to k3d (production-like testing)

## Workflows

### Local Build (Fast Iteration)
Use when you need instant feedback:
```bash
# Make code changes
vim ~/Dev/de-datalake-bulletin-dataload/src/...

# Build and push locally (30s - 2min)
cd ~/Dev/de-container-testing
./build-and-push.sh
```

### GitHub Build (Production-like)
Use for validation with production build process:
```bash
# Push to GitHub
cd ~/Dev/de-datalake-bulletin-dataload
git push origin dev

# Monitor build at: https://github.com/bu-ili/de-datalake-bulletin-dataload/actions
# When complete, sync to k3d
cd ~/Dev/de-container-testing
./sync-from-ghcr.sh
```

## Setup for GHCR Sync

### One-time setup:
```bash
# Login to GitHub Container Registry
docker login ghcr.io -u YOUR_USERNAME -p YOUR_GITHUB_TOKEN
```

Get a GitHub Personal Access Token with `read:packages` scope at https://github.com/settings/tokens

## Clean Slate Deployment

The `deploy-dagster.sh` script is idempotent and performs:
1. Uninstall existing Helm release (if exists)
2. Delete namespace
3. Recreate namespace and secrets
4. Install fresh Dagster deployment

## Architecture

```
┌─────────────────────────────────────┐
│         k3d Cluster                 │
│  ┌──────────────────────────────┐   │
│  │  dagster namespace           │   │
│  │                              │   │
│  │  ├─ Webserver (UI)           │   │
│  │  ├─ Daemon (scheduler)       │   │
│  │  ├─ PostgreSQL (storage)     │   │
│  │  └─ User Code (gRPC)         │   │
│  │                              │   │
│  └──────────────────────────────┘   │
│                                     │
│  Local Registry: localhost:5000    │
└─────────────────────────────────────┘
```

## Production Considerations

This setup mimics production patterns:
- Separate user code deployment (gRPC)
- K8sRunLauncher for dynamic pod creation
- PostgreSQL storage backend
- Ingress for external access

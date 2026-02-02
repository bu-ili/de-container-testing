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

- `setup-cluster.sh` - Create k3d cluster with registry
- `build-and-push.sh` - Build and push Docker image
- `deploy-dagster.sh` - Deploy Dagster with Helm (idempotent)

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

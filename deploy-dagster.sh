# Install Dagster using Helm chart in the 'dagster' cluster
# Set kubectl context to use the 'dagster' cluster, deploy Dagster Helm chart, and create a Kubernetes secret from a .env file.
#!/bin/bash
set -e

echo "Adding Dagster Helm repository..."
helm repo add dagster https://dagster-io.github.io/helm 
helm repo update
echo "Dagster Helm repository added."
echo ""
echo "Deploying Dagster to k3d cluster..."
kubectl config use-context k3d-dagster-testing

echo "Cleaning up existing Dagster deployment..."
if helm list -n dagster | grep -q dagster; then
  helm uninstall dagster -n dagster
  echo "Helm release uninstalled."
else
  echo "No existing Helm release found, skipping uninstall."
fi
kubectl delete namespace dagster --ignore-not-found=true --wait=false
kubectl wait --for=delete namespace/dagster --timeout=30s
echo "Cleanup complete."
echo ""

echo "Creating fresh namespace and secrets..."
kubectl create namespace dagster

# Create GHCR image pull secret if credentials are available
if [ -n "$GHCR_USERNAME" ] && [ -n "$GHCR_TOKEN" ]; then
  echo "Creating GHCR image pull secret..."
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username="$GHCR_USERNAME" \
    --docker-password="$GHCR_TOKEN" \
    --namespace=dagster
  echo "GHCR secret created."
else
  echo "Warning: GHCR_USERNAME or GHCR_TOKEN not set in environment."
  echo "Skipping GHCR secret creation. If needed, create manually or set:"
  echo "  export GHCR_USERNAME='your-username'"
  echo "  export GHCR_TOKEN='ghp_xxxxx'"
fi

# Create bulletin environment secret
kubectl create secret generic bulletin-env --from-env-file=$HOME/Dev/de-datalake-bulletin-dataload/.env -n dagster
echo "Configured namespace and secrets."
echo ""

echo "Installing Dagster Helm chart..."
helm install dagster dagster/dagster --namespace dagster --values values.yaml
echo "Dagster Helm chart installed."
echo ""

# Update /etc/hosts only if dagster.local not already present
if ! grep -q "dagster.local" /etc/hosts; 
then
  echo "Adding dagster.local to /etc/hosts..."
  sudo sh -c 'echo "127.0.0.1 dagster.local" >> /etc/hosts'
  echo "Updated /etc/hosts file to expose dagster.local/"
else
  echo "dagster.local already in /etc/hosts, skipping."
fi
echo ""
echo "Deployment complete."



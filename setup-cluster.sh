#!/bin/bash
set -e

echo "Deleting existing cluster if present..."
k3d cluster delete dagster-testing

echo "Creating k3d cluster..."
k3d cluster create --config k3d-cluster-config.yaml

echo "Cluster ready."
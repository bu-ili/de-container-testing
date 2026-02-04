#!/bin/bash
set -e

echo "Building and pushing de-bulletin image..."

PROJECT_PATH="$HOME/Dev/de-datalake-bulletin-dataload"
IMAGE_NAME="localhost:5000/de-bulletin:latest"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Project not found at $PROJECT_PATH"
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build --no-cache -t $IMAGE_NAME $PROJECT_PATH

# Push to k3d registry
echo "Pushing image to k3d registry..."
docker push $IMAGE_NAME

echo "Image built and pushed successfully."
echo "Image: $IMAGE_NAME"

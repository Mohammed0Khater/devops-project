#!/bin/bash

# A script to download the latest Docker image artifact
# and load it into Minikube, then run Terraform.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# Get the run ID from the first argument, or find the latest one
if [ -z "$1" ]; then
  echo "No run ID provided. Finding the latest successful workflow run..."
  RUN_ID=$(gh run list --repo $(git config --get remote.origin.url) --branch main --status success --limit 1 --json databaseId | jq -r '.[0].databaseId')
else
  RUN_ID=$1
fi

if [ -z "$RUN_ID" ]; then
  echo "Could not find a recent successful workflow run."
  exit 1
fi

echo "Using artifacts from run ID: $RUN_ID"

# --- Logic ---
# 1. Download the artifact
echo "Downloading image artifact..."
gh run download $RUN_ID --repo $(git config --get remote.origin.url) -n devops-app-image

# 2. Load the image into Minikube's Docker daemon
echo "Loading image into Minikube..."
minikube image load image-artifact/devops-app.tar

# 3. Get the image tag from the run ID
# The tag is the short commit SHA of the run
TAG=$(gh run view $RUN_ID --repo $(git config --get remote.origin.url) --json headSha | jq -r '.headSha[0:7]')

# 4. Run Terraform
echo "Running Terraform to deploy the application..."
cd terraform
terraform apply -auto-approve -var="image_tag=$TAG" -var="minikube_registry_url=localhost:5000" # The registry URL is now irrelevant

echo "Deployment complete!"

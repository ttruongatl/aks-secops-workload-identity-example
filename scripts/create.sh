#!/bin/bash

set -ex  # Exit on error

# Default values
DEFAULT_ACR_NAME="aksworkloadidentityexample"
DEFAULT_RG_NAME="aks-secops-workload-identity-example"
DEFAULT_LOCATION="eastus2"
DEFAULT_SUBSCRIPTION="feb5b150-60fe-4441-be73-8c02a524f55a"

# Function to print usage
usage() {
    echo "Usage: $0 [-n <acr-name>] [-g <resource-group>] [-l <location>] [-s <subscription-id>]"
    echo "  -n : Name of Azure Container Registry (default: $DEFAULT_ACR_NAME)"
    echo "  -g : Resource group name (default: $DEFAULT_RG_NAME)"
    echo "  -l : Location (default: $DEFAULT_LOCATION)"
    echo "  -s : Subscription ID (default: $DEFAULT_SUBSCRIPTION)"
    echo "  -h : Show this help message"
    exit 1
}

# Parse command line arguments
while getopts "n:g:l:s:h" opt; do
    case $opt in
        n) ACR_NAME="$OPTARG";;
        g) RG_NAME="$OPTARG";;
        l) LOCATION="$OPTARG";;
        s) SUBSCRIPTION="$OPTARG";;
        h) usage;;
        ?) usage;;
    esac
done

# Use default values if not provided
ACR_NAME=${ACR_NAME:-$DEFAULT_ACR_NAME}
RG_NAME=${RG_NAME:-$DEFAULT_RG_NAME}
LOCATION=${LOCATION:-$DEFAULT_LOCATION}
SUBSCRIPTION=${SUBSCRIPTION:-$DEFAULT_SUBSCRIPTION}

echo "Using values:"
echo "Subscription ID: $SUBSCRIPTION"
echo "ACR Name: $ACR_NAME"
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo ""

# Set the subscription
echo "Setting subscription context..."
az account set --subscription $SUBSCRIPTION

# Generate timestamp for Docker tag
export IMAGE_TAG=$(date '+%Y%m%d.%H%M%S')

echo "Creating Resource Group..."
az group create --name $RG_NAME --location $LOCATION

echo "Deploying Bicep template..."
az deployment group create \
  --resource-group $RG_NAME \
  --template-file azure-templates/main.bicep \
  --parameters azure-templates/parameters.json

# Get AKS and workload identity details
export AKS_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name main \
  --query properties.outputs.aksClusterName.value \
  -o tsv)

export WORKLOAD_IDENTITY_CLIENT_ID=$(az deployment group show \
  --resource-group $RG_NAME \
  --name main \
  --query properties.outputs.aksWorkloadIdentityClientId.value \
  -o tsv)

export KEY_VAULT_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name main \
  --query properties.outputs.keyVaultName.value \
  -o tsv)

export AZURE_CLIENT_ID=$WORKLOAD_IDENTITY_CLIENT_ID

# Create ACR and assign pull role to AKS
echo "Creating Azure Container Registry..."
az acr create \
  --resource-group $RG_NAME \
  --name $ACR_NAME \
  --sku Standard

# Get the AKS kubelet identity
AKS_KUBELET_ID=$(az aks show \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --query identityProfile.kubeletidentity.objectId \
  -o tsv)

# Assign ACR pull role to AKS
echo "Assigning ACR pull role to AKS..."
az role assignment create \
  --assignee $AKS_KUBELET_ID \
  --role AcrPull \
  --scope $(az acr show --name $ACR_NAME --resource-group $RG_NAME --query id -o tsv)

# Build and push Docker image
echo "Building and pushing Docker image..."
az acr build \
  --registry $ACR_NAME \
  --image aks-secops-workload-identity-example:$IMAGE_TAG \
  --file Dockerfile \
  .

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --overwrite-existing

# Deploy to Kubernetes using envsubst and direct piping
echo "Deploying to Kubernetes..."
kubectl apply -f deployment/namespace.yaml
envsubst < deployment/serviceaccount.yaml | kubectl apply -f -
envsubst < deployment/configmap.yaml | kubectl apply -f -
envsubst < deployment/deployment.yaml | kubectl apply -f -

echo "Deployment completed successfully!"
echo "Image tag: $IMAGE_TAG"
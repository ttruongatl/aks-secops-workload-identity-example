#!/bin/bash
# scripts/delete.sh

set -e  # Exit on error

# Default values
DEFAULT_ACR_NAME="aksworkloadidentityexample"
DEFAULT_RG_NAME="aks-secops-workload-identity-example"
SUBSCRIPTION_ID="c1089427-83d3-4286-9f35-5af546a6eb67"

# Function to print usage
usage() {
    echo "Usage: $0 [-n <acr-name>] [-g <resource-group>]"
    echo "  -n : Name of Azure Container Registry (default: $DEFAULT_ACR_NAME)"
    echo "  -g : Resource group name (default: $DEFAULT_RG_NAME)"
    exit 1
}

# Set the subscription
echo "Setting subscription to: $SUBSCRIPTION_ID"
az account set --subscription $SUBSCRIPTION_ID

# Parse command line arguments
while getopts "n:g:h" opt; do
    case $opt in
        n) ACR_NAME="$OPTARG";;
        g) RG_NAME="$OPTARG";;
        h) usage;;
        ?) usage;;
    esac
done

# Use default values if not provided
ACR_NAME=${ACR_NAME:-$DEFAULT_ACR_NAME}
RG_NAME=${RG_NAME:-$DEFAULT_RG_NAME}

echo "Using values:"
echo "ACR Name: $ACR_NAME"
echo "Resource Group: $RG_NAME"
echo ""

# Get AKS name
AKS_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name main \
  --query properties.outputs.aksClusterName.value \
  -o tsv 2>/dev/null || echo "")

if [ ! -z "$AKS_NAME" ]; then
    # Get AKS credentials
    echo "Getting AKS credentials..."
    az aks get-credentials \
      --resource-group $RG_NAME \
      --name $AKS_NAME \
      --overwrite-existing

    # Delete Kubernetes resources
    echo "Deleting Kubernetes resources..."
    kubectl delete namespace aks-secops-workload-identity-example --ignore-not-found
fi

# Delete resource group
echo "Deleting resource group..."
az group delete --name $RG_NAME --yes --no-wait

# Purge ACR if it exists
echo "Checking if ACR exists..."
if az acr show --name $ACR_NAME --resource-group $RG_NAME &>/dev/null; then
    echo "Deleting ACR..."
    az acr delete --name $ACR_NAME --resource-group $RG_NAME --yes
fi

echo "Cleanup initiated. Resource group deletion will continue in the background."
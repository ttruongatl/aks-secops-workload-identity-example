# Azure AKS Workload Identity Demo

This repository demonstrates how to set up and use Azure AD Workload Identity with Azure Kubernetes Service (AKS). The demo showcases a secure way for Kubernetes applications to access Azure resources (like Key Vault) without managing credentials directly in the application code or Kubernetes manifests.

## Prerequisites

- Azure CLI (latest version)
- kubectl command-line tool
- bash shell environment
- Azure subscription with required permissions
- Docker (if building images locally)
- gettext-base package (for envsubst)

## Quick Start

1. Clone the repository:
```bash
git clone git@github.com:ttruongatl/aks-secops-workload-identity-example.git
cd aks-secops-workload-identity-example
```

2. Run the deployment script:
```bash
./scripts/create.sh
```

The script accepts the following optional parameters:
```bash
Usage: ./scripts/create.sh [-n <acr-name>] [-g <resource-group>] [-l <location>] [-s <subscription-id>]
 -n : Name of Azure Container Registry (default: aksworkloadidentityexample)
 -g : Resource group name (default: aks-secops-workload-identity-example)
 -l : Location (default: eastus2)
 -s : Subscription ID (default: your-subscription-id)
 -h : Show this help message
```

## What Gets Deployed

The script creates:

1. A resource group
2. An AKS cluster with:
   - OIDC issuer enabled
   - Workload Identity enabled
   - Azure CNI networking
   - Azure KeyVault Secrets Provider
3. An Azure Container Registry
4. A Key Vault with:
   - RBAC authorization
   - A sample secret
5. A Managed Identity with:
   - Federated credentials for Kubernetes service account
   - Key Vault Secrets User role assignment
6. Kubernetes resources:
   - Namespace
   - Service Account with workload identity
   - ConfigMap with Key Vault configuration
   - Sample application deployment

## Infrastructure as Code

The infrastructure is defined using Bicep templates:
- `azure-templates/main.bicep`: Main template orchestrating the deployment
- `azure-templates/modules/`:
  - `aks.bicep`: AKS cluster configuration
  - `keyvault.bicep`: Key Vault setup
  - `networking.bicep`: Virtual network configuration

## Kubernetes Manifests

The Kubernetes resources are defined in the `deployment/` directory:
- `namespace.yaml`: Creates the application namespace
- `serviceaccount.yaml`: Sets up the service account with workload identity
- `configmap.yaml`: Configures the application
- `deployment.yaml`: Deploys the sample application

Environment variables are substituted at deployment time using `envsubst`.
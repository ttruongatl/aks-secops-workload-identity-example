@description('The name of the AKS cluster')
param clusterName string
param location string
param subnetId string
param kubernetesVersion string
param defaultNodePoolVmSize string
param defaultNodePoolCount int
param serviceCidr string = '172.16.0.0/16'
param dnsServiceIP string = '172.16.0.10'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-01-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${clusterName}-dns'
    enableRBAC: true
    
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: defaultNodePoolCount
        vmSize: defaultNodePoolVmSize
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        vnetSubnetID: subnetId
      }
    ]
    
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      loadBalancerSku: 'standard'
    }
    
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

// Create User Assigned Identity for Workload Identity
resource aksWorkloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${clusterName}-workload-identity'
  location: location
}

// Create federated identity credential
resource federatedIdentityCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'aks-federated-identity'
  parent: aksWorkloadIdentity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: aksCluster.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:aks-secops-workload-identity-example:aks-secops-workload-identity-example'
  }
}

output clusterId string = aksCluster.id
output clusterName string = aksCluster.name
output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL
output workloadIdentityClientId string = aksWorkloadIdentity.properties.clientId
output workloadIdentityPrincipalId string = aksWorkloadIdentity.properties.principalId

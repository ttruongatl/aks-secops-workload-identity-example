// azure-templates/main.bicep
@description('Location for all resources.')
param location string

@description('AKS cluster name')
param aksClusterName string

@description('Keyvault name')
param keyVaultName string

@description('Node count for AKS default node pool')
param aksNodePoolCount int = 1

@description('VM size for AKS default node pool')
param aksNodePoolVmSize string = 'Standard_D2s_v3'

@description('Kubernetes version')
param kubernetesVersion string = '1.27.7'

// Virtual Network Parameters
@description('Virtual Network name')
param vnetName string
param vnetAddressPrefix string = '10.0.0.0/16'
param aksSubnetName string = 'snet-aks'
param aksSubnetPrefix string = '10.0.0.0/24'

module networking './modules/networking.bicep' = {
  name: 'networkingDeployment'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    aksSubnetName: aksSubnetName
    aksSubnetPrefix: aksSubnetPrefix
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    location: location
    clusterName: aksClusterName
    kubernetesVersion: kubernetesVersion
    defaultNodePoolVmSize: aksNodePoolVmSize
    defaultNodePoolCount: aksNodePoolCount
    subnetId: networking.outputs.aksSubnetId
  }
}

module keyVault './modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    workloadIdentityPrincipalId: aks.outputs.workloadIdentityPrincipalId
  }
}

output aksClusterName string = aks.outputs.clusterName
output aksOidcIssuerUrl string = aks.outputs.oidcIssuerUrl
output aksWorkloadIdentityClientId string = aks.outputs.workloadIdentityClientId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri

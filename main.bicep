targetScope = 'subscription'


@description('Username for the DNS Virtual Machine.')
param adminUsername string

@description('Password for the DNS Virtual Machine.')
@minLength(12)
// This line below is to enter the password string in a secure way.
@secure()
param adminPassword string


param location string = 'canadacentral'
param userName string = 'lab1'
param resourceName string = 'api-connection'

var aksResourceGroupName = 'aks-${resourceName}-${userName}-rg'
var vnetResourceGroupName = 'vnet-${resourceName}-${userName}-rg'
var dnsserverResourceGroupName = 'dnsserver-${resourceName}-${userName}-rg'

// WHAT IS THIS FOR????     <<<<<<<<<<<<<<<<<<<<<<============================
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource clusterrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: aksResourceGroupName
  location: location
}

resource vnetrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vnetResourceGroupName
  location: location
}

resource dnsserverrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: dnsserverResourceGroupName
  location: location
}

module aksvnet './modules/aks-vnet.bicep' = {
  name: 'aks-vnet'
  scope: vnetrg
  params: {
    location: location
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      } 
    ]
    vnetName: 'aks-vnet'
    vvnetPreffix:  [
      '10.2.0.0/16'
    ]
  }
}

module akscluster './modules/aks-cluster.bicep' = {
  name: resourceName
  scope: clusterrg
  dependsOn: [ aksvnet, vnetpeeringdns, vnetpeeringaks ]
  params: {
    location: location
    clusterName: 'aks-${resourceName}'
    aksSubnetId: aksvnet.outputs.akssubnet
  }
}

module roleAuthorization './modules/aks-auth.bicep' = {
  name: 'roleAuthorization'
  scope: vnetrg
  dependsOn: [
    akscluster
  ]
  params: {
      principalId: akscluster.outputs.aks_principal_id
      roleDefinition: contributorRoleId
  }
}

module dnsserver './modules/dns-server-config.bicep' = {
  name: 'dnsserver'
  scope: dnsserverrg
  params: {
    location: location
  }
}


module vnetpeeringdns './modules/vnetpeering.bicep' = {
  scope: vnetrg
  name: 'vnetpeering'
  dependsOn: [
    aksvnet, dnsserver
  ]
  params: {
    peeringName: 'aks-to-dns'
    vnetName: aksvnet.outputs.aksVnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
         id: dnsserver.outputs.remoteDNSVNetId
      }
    }    
  }
}

module vnetpeeringaks './modules/vnetpeering.bicep' = {
  scope: dnsserverrg
  name: 'vnetpeering2'
  dependsOn: [
    aksvnet, dnsserver
  ]
  params: {
    peeringName: 'dns-to-aks'
    vnetName: dnsserver.outputs.DNSVNetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
         id: aksvnet.outputs.aksVnetId
      }
    }    
  }
}
 
output adminUsername string = adminUsername
output adminPassword string = adminPassword

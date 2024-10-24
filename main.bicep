targetScope = 'subscription'

//Private Endpoint params
param privateEndpointName string
param subnetId string
param privateLinkServiceId string


param location string = 'canadacentral'
param userName string = 'lab1'
param resourceName string = 'api-connection'
//param dnsvm string = 'custom-dns-vm'
//param zoneName string = 'postgresdb1-workbench-lab1.private.postgres.database.azure.com'
//param recordName string = 'db1'

//var postgresqlName = 'postgresql-${userName}-${uniqueString(subscription().id)}'
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

//HERE IS THE VNET PART
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

/* 
module dbvnet './modules/db-vnet.bicep' = {
  name: 'db-vnet'
  scope: dbrg
  params: {
    location: location
    subnets: [
      {
        name: 'db-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
                name: 'db-subnet-delegation'
                properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
                }
            }]
        }
      } 
    ]
    vnetName: 'db-vnet'
    vvnetPreffix:  [
      '10.0.0.0/16'
    ]
  }
}
*/

/*module privatednszone './modules/private-dns-zone.bicep' = {
  name: 'private-dns-zone'
  scope: dbrg
  dependsOn: [
    dbvnet, aksvnet
  ]
  params: {
    privateDnsZoneName: zoneName
    recordName: recordName
    privateDnsZoneLinkName: 'db-vnet-link'
    aksVnetId: aksvnet.outputs.aksVnetId
    dbVnetId: dbvnet.outputs.dbVnetId
  }
}
*/



/*
module postgresqlModule './modules/postgresql-flexible-server.bicep' = {
  scope: dbrg
  name: 'postgresqlModule'
  dependsOn: [
    dbvnet, privatednszone
  ]
  params: {
    serverName: postgresqlName
    location: location
    adminUsername: 'admindb'
    adminPass: 'T3mp0r4l'
    subnetId: dbvnet.outputs.dbsubnet
    privateDnsZoneId: privatednszone.outputs.privateDnsZoneId
  }
}
*/

module akscluster './modules/aks-cluster.bicep' = {
  name: resourceName
  scope: clusterrg
  dependsOn: [ aksvnet ] //, privatednszone ]
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

module kubernetes './modules/workloads.bicep' = {
  name: 'luis-test-deployment'
  scope: clusterrg
  dependsOn: [
    akscluster
  ]
  params: {
    kubeConfig: akscluster.outputs.kubeConfig
  }
}

module dnsserver './modules/dns-server-config.bicep' = {
  name: 'dnsserver'
  scope: dnsserverrg
  params: {
    location: location
  }
}



//VNET PEERING CONFIGURATION
module vnetpeeringdns './modules/vnetpeering.bicep' = {
  scope: vnetrg
  name: 'vnetpeering'
  dependsOn: [
    akscluster, dnsserver
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
    akscluster, dnsserver
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

/*
resource aksPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'aksPrivateEndpoint'
  scope: vnetrg
  dependsOn: [
    aksvnet, vnetrg
  ]
  location: location
  properties: {
    subnet: {
      id: aksvnet.outputs.akssubnet
    }
    privateLinkServiceConnections: [
      {
        name: 'aksConnection'
        properties: {
          privateLinkServiceId: akscluster.outputs.aksClusterURI
          groupIds: [
            'management'
          ]
        }
      }
    ]
  }
}
*/


module privateEndpointModule './modules/privateEndpoint.bicep' = {
  name: 'privateEndpointDeployment'
  params: {
    privateEndpointName: privateEndpointName
    location: location
    subnetId: subnetId
    privateLinkServiceId: privateLinkServiceId
  }
}




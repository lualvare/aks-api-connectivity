param privateEndpointName string
param location string = resourceGroup().location
param subnetId string
param privateLinkServiceId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'myPrivateLinkServiceConnection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            'groupId'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}

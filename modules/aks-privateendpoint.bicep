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

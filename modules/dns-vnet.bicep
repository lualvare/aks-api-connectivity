param location string
param vnetName string
param vvnetPreffix array
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vvnetPreffix
    }
    subnets: subnets
  }
}

var dnsSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'dns-subnet')

output dnsVnetId string = vnet.id
output dnssubnet string = dnsSubnetId
output vnetName string = vnet.name

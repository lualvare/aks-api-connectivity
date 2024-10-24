param location string
param vnetName string
param vvnetPreffix array
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {dhcpOptions: {
    dnsServers: [
      '10.1.0.10'  //custom DNS server IP address
      ]
    }

    addressSpace: {
      addressPrefixes: vvnetPreffix
    }
    subnets: subnets
  }
}

var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'aks-subnet')

output aksVnetId string = vnet.id
output akssubnet string = aksSubnetId
output aksVnetName string = vnet.name

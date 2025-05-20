@description('Name of the virtual network')
param vnetName string

@description('Location of the resources')
param location string

@description('Address space of the virtual network')
param addressSpace string

@description('Array of subnets to create')
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

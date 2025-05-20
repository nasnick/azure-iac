param location string = 'australiaeast'
param resourceGroupName string = 'az104-rg5'

module coreServicesVnet '../modules/vnet.bicep' = {
  name: 'coreServicesVnetDeployment'
  params: {
    vnetName: 'CoreServicesVnet'
    location: location
    addressSpace: '10.20.0.0/16'
    subnets: [
      {
        name: 'SharedServicesSubnet'
        addressPrefix: '10.20.10.0/24'
      }
      {
        name: 'DatabaseSubnet'
        addressPrefix: '10.20.20.0/24'
      }
    ]
  }
}

module manufacturingVnet '../modules/vnet.bicep' = {
  name: 'manufacturingVnetDeployment'
  params: {
    vnetName: 'ManufacturingVnet'
    location: location
    addressSpace: '10.30.0.0/16'
    subnets: [
      {
        name: 'SensorSubnet1'
        addressPrefix: '10.30.20.0/24'
      }
      {
        name: 'SensorSubnet2'
        addressPrefix: '10.30.21.0/24'
      }
    ]
  }
}

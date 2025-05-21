@description('The name of the resource group to deploy resources into.')
param resourceGroupName string = resourceGroup().name

@description('The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('The name of the Virtual Network.')
param vnetName string = 'bePortalVnet'

@description('The name of the Subnet within the Virtual Network.')
param subnetName string = 'bePortalSubnet'

@description('The name of the Network Security Group.')
param nsgName string = 'bePortalNSG'

@description('The administrator username for the Virtual Machines.')
param adminUsername string = 'azureuser'

@description('The SSH public key content for the Virtual Machines.')
param sshPublicKey string // Provide your SSH public key here, e.g., 'ssh-rsa AAAAB3NzaC...'

@description('The VM image SKU (e.g., Ubuntu2204).')
param vmImageSku string = '22_04-lts-gen2'

@description('The content of the cloud-init script for VM customization (base64 encoded automatically).')
param customDataContent string = ''

@description('The name of the Availability Set for the VMs.')
param availabilitySetName string = 'portalAvailabilitySet'

@description('The number of virtual machines to create (and associated NICs).')
param numberOfVMs int = 2

@description('The name of the Public IP address for the Load Balancer.')
param lbPublicIpName string = 'myPublicIP'

@description('The name of the Load Balancer.')
param loadBalancerName string = 'myLoadBalancer'

@description('The name of the Load Balancer Frontend IP configuration.')
param lbFrontendIpName string = 'myFrontEndPool'

@description('The name of the Load Balancer Backend Address Pool.')
param lbBackendPoolName string = 'myBackEndPool'

@description('The name of the Load Balancer Health Probe.')
param lbProbeName string = 'myHealthProbe'

@description('The name of the Load Balancer Rule for HTTP traffic.')
param lbRuleName string = 'myHTTPRule'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll80'
        properties: {
          priority: 101
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          description: 'Allow all port 80 traffic'
        }
      }
    ]
  }
}

// Availability Set
resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: availabilitySetName
  location: location
  sku: {
    name: 'Aligned' // Recommended for Managed Disks VMs
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

// Public IP for Load Balancer
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: lbPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Load Balancer
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFrontendIpName
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBackendPoolName
      }
    ]
  }
}

// Load Balancer Health Probe
resource lbProbe 'Microsoft.Network/loadBalancers/probes@2023-09-01' = {
  parent: loadBalancer
  name: lbProbeName
  properties: {
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 5
    numberOfProbes: 2
  }
}

// Load Balancer Rule
resource lbRule 'Microsoft.Network/loadBalancers/loadBalancingRules@2023-09-01' = {
  parent: loadBalancer
  name: lbRuleName
  properties: {
    frontendIPConfiguration: {
      id: loadBalancer.properties.frontendIPConfigurations[0].id
    }
    backendAddressPool: {
      id: loadBalancer.properties.backendAddressPools[0].id
    }
    probe: {
      id: lbProbe.id
    }
    protocol: 'Tcp'
    frontendPort: 80
    backendPort: 80
    enableFloatingIP: false
    idleTimeoutInMinutes: 4
  }
}

// Network Interfaces (NICs)
resource webNic 'Microsoft.Network/networkInterfaces@2023-09-01' = [for i in range(1, numberOfVMs + 1): {
  name: 'webNic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          // Associate with Load Balancer Backend Pool
          loadBalancerBackendAddressPools: [
            {
              id: loadBalancer.properties.backendAddressPools[0].id
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]

// Virtual Machines
resource webVm 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(1, numberOfVMs + 1): {
  name: 'webVM${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2' // You can change this VM size as needed
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: vmImageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS' // You can change this storage type
        }
      }
    }
    osProfile: {
      computerName: 'webVM${i}'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true // SSH key-based authentication
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
      customData: !empty(customDataContent) ? base64(customDataContent) : null // base64 encode customData
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: webNic[i - 1].id
        }
      ]
    }
    availabilitySet: {
      id: availabilitySet.id
    }
  }
}]

@description('The public IP address of the Load Balancer.')
output publicIpAddress string = publicIp.properties.ipAddress
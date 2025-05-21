# Labs
[AZ-104 Labs index](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/)

## Lab 4
[link](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_04-Implement_Virtual_Networking.html)

[Template](./az-104/lab4.bicep)

# MS Learn
## Configure and manage virtual networks for Azure administrators
### Create alias records for Azure DNS
[link](https://learn.microsoft.com/en-us/training/modules/host-domain-azure-dns/6-exercise-create-alias-records)

[Bash script](https://github.com/MicrosoftDocs/mslearn-host-domain-azure-dns/blob/master/setup.sh)

[Template](./az-104/virtual-network-load-balancer-vms.bicep)

The template sets up all the infrastructure:

- Creates a network security group.
- Creates two network interface controllers (NICs) and two VMs.
- Creates a virtual network and assigns the VMs.
- Creates a public IP address and updates the configuration of the VMs.
- Creates a load balancer that references the VMs, including rules for the load balancer.
- Links the NICs to the load balancer.

And the final exercise is to create an Alias record linked to the Load Balancer which can be queried with:

```
nslookup <domain_created_in_exercise_linked_to_load_balancer> <name_server_address>
```

# Applying the Bicep Template

```
az deployment group create --resource-group az104-rg5 --template-file ./<template_file_name>.bicep --parameters location=australiaeast
```


output "azure_network_id" {
  description = "ID of Azure VNet"
  value = {
    for k, v in azurerm_virtual_network.vnet : k => v.id
  }
}

output "azure_subnet_id" {
  description = "ID of Azure subnet"
  value = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}

output "alkira_connector_azure_id" {
  description = "ID of Azure connector"
  value = {
    for k, v in alkira_connector_azure_vnet.connector : k => v.id
  }
}

output "alkira_connector_azure_implicit_group_id" {
  description = "Implicit group ID of Azure connector"
  value = {
    for k, v in alkira_connector_azure_vnet.connector : k => v.implicit_group_id
  }
}

output "azure_vm_private_ip" {
  description = "Private IP of Azure vm"
  value = {
    for k, v in azurerm_linux_virtual_machine.vm : k => v.private_ip_address
  }
}
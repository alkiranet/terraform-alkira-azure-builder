output "azure_network_id" {
  description  = "ID of Azure VNet"
  value        = try(module.azure_vnet.*.azure_network_id, "")
}

output "azure_subnet_id" {
  description  = "ID of Azure subnet"
  value        = try(module.azure_vnet.*.azure_subnet_id, "")
}

output "alkira_connector_azure_id" {
  description  = "ID of Azure connector"
  value        = try(module.azure_vnet.*.alkira_connector_azure_id, "")
}

output "alkira_connector_azure_implicit_group_id" {
  description  = "Implicit group ID of Azure connector"
  value        = try(module.azure_vnet.*.alkira_connector_azure_implicit_group_id, "")
}

output "azure_vm_private_ip" {
  description = "Private IP of Azure virtual machine"
  value = try(module.azure_vnet.*.azure_vm_private_ip, "")
}
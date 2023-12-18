# Azure Builder - Terraform Module
This module creates various resources in _Alkira_ and _Azure_ from **.yaml** files.

## Basic Usage
Define the path to your **.yaml** configuration file in the module.

```hcl
module "azure_vnets" {
  source = "alkiranet/azure-builder/alkira"
  
  # path to config
  config_file = "./config/azure_vnets.yaml"
  
}
```

### Configuration Example
The module will automatically create resources if they are present in the **.yaml** configuration with the proper _resource keys_ defined.

**azure_vnets.yaml**
```yml
---
azure_vnet:
  - name: 'vnet-east'
    description: 'Azure East Workloads'
    resource_group: 'rg-npe'
    region: 'eastus'
    credential: 'azure'
    cxp: 'US-EAST-2'
    group: 'cloud'
    segment: 'business'
    network_cidr: '10.6.0.0/16'
    network_id: '/subscriptions/12345-abcde/resourcegroups/rg-npe/providers/Microsoft.Network/virtualNetworks/vnet-east-npe'
...
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.1 |
| <a name="requirement_alkira"></a> [alkira](#requirement\_alkira) | >= 1.1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.55.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_vnet"></a> [azure\_vnet](#module\_azure\_vnet) | ./modules/azure-vnet | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_file"></a> [config\_file](#input\_config\_file) | Path to .yml files | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alkira_connector_azure_id"></a> [alkira\_connector\_azure\_id](#output\_alkira\_connector\_azure\_id) | ID of Azure connector |
| <a name="output_alkira_connector_azure_implicit_group_id"></a> [alkira\_connector\_azure\_implicit\_group\_id](#output\_alkira\_connector\_azure\_implicit\_group\_id) | Implicit group ID of Azure connector |
| <a name="output_azure_network_id"></a> [azure\_network\_id](#output\_azure\_network\_id) | ID of Azure VNet |
| <a name="output_azure_subnet_id"></a> [azure\_subnet\_id](#output\_azure\_subnet\_id) | ID of Azure subnet |
| <a name="output_azure_vm_private_ip"></a> [azure\_vm\_private\_ip](#output\_azure\_vm\_private\_ip) | Private IP of Azure virtual machine |
<!-- END_TF_DOCS -->
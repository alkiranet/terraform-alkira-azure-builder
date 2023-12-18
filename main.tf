locals {

  # parse .yaml configuration
  config_file_content = fileexists(var.config_file) ? file(var.config_file) : "NoConfigurationFound: true"
  config              = yamldecode(local.config_file_content)

  # does 'azure_vnet' key exist in the configuration?
  azure_vnet_exists   = contains(keys(local.config), "azure_vnet")
}

module "azure_vnet" {
  source = "./modules/azure-vnet"

  # if 'azure_vnet' exists, create resources
  count = local.azure_vnet_exists ? 1 : 0

  # pass configuration
  azure_vnet_data = local.config["azure_vnet"]

}
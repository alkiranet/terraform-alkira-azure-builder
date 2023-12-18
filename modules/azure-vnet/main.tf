/*
virtual_network
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
*/
resource "azurerm_virtual_network" "vnet" {
  for_each = {
    for o in var.azure_vnet_data : o.name => o
    if o.create_network == true
  }

  name                = each.value.name
  address_space       = [each.value.network_cidr]
  resource_group_name = each.value.resource_group
  location            = each.value.region

}

/*
subnet
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
*/
resource "azurerm_subnet" "subnet" {
  for_each = {
    for idx, subnet in flatten([
      for vnet in var.azure_vnet_data : [

        # If vnet.subnets is == null, use coalesce with empty list
        for subnet in coalesce(vnet.subnets, []) : {
          vnet_name        = vnet.name
          subnet_name      = subnet.name
          address_prefixes = subnet.cidr
          create_network   = vnet.create_network
        }
      ]
    ]) : "${subnet.vnet_name}-${subnet.subnet_name}" => {
      address_prefixes = subnet.address_prefixes
      vnet_name        = subnet.vnet_name
      name             = subnet.subnet_name
    } if subnet.create_network
  }

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_name].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_name].name
  address_prefixes     = [each.value.address_prefixes]

}
locals {

  # List comprehension; Filter VNets based on condition (subnet.create_vm)
  filter_vnets = [
    for vnet in var.azure_vnet_data :
      vnet if anytrue([for subnet in coalesce(vnet.subnets, []) : subnet.create_vm])
  ]

  # Conditional expression; Any VNets with subnets that get a vm
  create_vm   = length(local.filter_vnets) > 0 ? local.filter_vnets[0] : null

}

/*
network_interface
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
*/
resource "azurerm_network_interface" "int" {
  for_each = {
    for idx, subnet in flatten([
      for vnet in var.azure_vnet_data : [
        for subnet in coalesce(vnet.subnets, []) : {
          vnet_name     = vnet.name
          subnet_name   = subnet.name
          subnet_id     = azurerm_subnet.subnet["${vnet.name}-${subnet.name}"].id
          create_vm     = subnet.create_vm
          vm_size       = subnet.vm_type
        }
      ]
    ]) : "${subnet.vnet_name}-${subnet.subnet_name}" => subnet if subnet.create_vm
  }

  name                 = "nic-${each.value.vnet_name}-${each.value.subnet_name}"
  location             = azurerm_virtual_network.vnet[each.value.vnet_name].location
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_name].resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "nic-${each.value.vnet_name}-${each.value.subnet_name}"
  }

}

/*
linux_virtual_machine
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
*/
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = {
    for idx, subnet in flatten([
      for vnet in var.azure_vnet_data : [
        for subnet in coalesce(vnet.subnets, []) : {
          create_vm            = subnet.create_vm
          subnet_name          = subnet.name
          subnet_id            = azurerm_subnet.subnet["${vnet.name}-${subnet.name}"].id
          vnet_name            = vnet.name
          vm_size              = subnet.vm_type
        }
      ]
    ]) : "${subnet.vnet_name}-${subnet.subnet_name}" => subnet if subnet.create_vm
  }

  name                  = "vm-${each.value.vnet_name}-${each.value.subnet_name}"
  resource_group_name   = azurerm_virtual_network.vnet[each.value.vnet_name].resource_group_name
  location              = azurerm_virtual_network.vnet[each.value.vnet_name].location
  size                  = each.value.vm_size
  admin_username        = "ubuntu"
  network_interface_ids = [azurerm_network_interface.int[each.key].id]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true

  tags = {
    Name = "vm-${each.value.vnet_name}-${each.value.subnet_name}"
  }

}

/*
azurerm_network_security_group
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
*/
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for vnet in var.azure_vnet_data : vnet.name => vnet
    if anytrue([for subnet in coalesce(vnet.subnets, []) : subnet.create_vm])
  }

  name                 = "nsg-${each.key}"
  location             = azurerm_virtual_network.vnet[each.key].location
  resource_group_name  = azurerm_virtual_network.vnet[each.key].resource_group_name

  dynamic "security_rule" {
    for_each = each.value.ingress_cidrs
    content {
      name                       = "ingress-${security_rule.key}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  security_rule {
    name                       = "allow-all-egress"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "nsg-${each.key}"
  }

}

/*
network_interface_security_group_association
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
*/
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  for_each = {
    for item in flatten([
      for vnet in var.azure_vnet_data : [
        for subnet in coalesce(vnet.subnets, []) : {
          key      = "${vnet.name}-${subnet.name}"
          nic_id   = azurerm_network_interface.int["${vnet.name}-${subnet.name}"].id
          nsg_id   = azurerm_network_security_group.nsg[vnet.name].id
        } if subnet.create_vm
      ]
    ]) : item.key => {
      nic_id   = item.nic_id
      nsg_id   = item.nsg_id
    }
  }

  network_interface_id      = each.value.nic_id
  network_security_group_id = each.value.nsg_id

}

locals {

  # filter 'segment' data
  filter_segments     = var.azure_vnet_data[*].segment

  # filter 'credential' data
  filter_credentials  = var.azure_vnet_data[*].credential

}

data "alkira_segment" "segment" {

  for_each = toset(local.filter_segments)

  name = each.value

}

data "alkira_credential" "credential" {

  for_each = toset(local.filter_credentials)

  name = each.value

}

/*
alkira_connector_azure_vnet
https://registry.terraform.io/providers/alkiranet/alkira/latest/docs/resources/connector_azure_vnet
*/
locals {

  filter_azure_vnets = flatten([
    for c in var.azure_vnet_data : {

        connect_network   = c.connect_network
        create_network    = c.create_network
        credential        = lookup(data.alkira_credential.credential, c.credential, null).id
        cxp               = c.cxp
        group             = c.group
        name              = c.name
        network_cidr      = c.network_cidr
        network_id        = c.create_network ? lookup(azurerm_virtual_network.vnet, c.name, null).id : c.network_id
        segment           = lookup(data.alkira_segment.segment, c.segment, null).id
        size              = c.size

      }
  ])
}

resource "alkira_connector_azure_vnet" "connector" {

  for_each = {
    for o in local.filter_azure_vnets : o.name => o
    if o.connect_network == true
  }

  azure_vnet_id           = each.value.network_id
  credential_id           = each.value.credential
  cxp                     = each.value.cxp
  group                   = each.value.group
  name                    = each.value.name
  segment_id              = each.value.segment
  size                    = each.value.size

  vnet_cidr {
    cidr             = each.value.network_cidr
    routing_options  = "ADVERTISE_DEFAULT_ROUTE"
  }

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet
  ]

}
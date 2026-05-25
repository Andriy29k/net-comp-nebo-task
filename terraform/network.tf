resource "azurerm_resource_group" "net_comp_task_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "net_comp_task_vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  address_space       = [var.vnet_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.vnet_name}-public"
  resource_group_name  = azurerm_resource_group.net_comp_task_rg.name
  virtual_network_name = azurerm_virtual_network.net_comp_task_vnet.name
  address_prefixes     = [var.public_subnet_address_prefix]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "${var.vnet_name}-app"
  resource_group_name  = azurerm_resource_group.net_comp_task_rg.name
  virtual_network_name = azurerm_virtual_network.net_comp_task_vnet.name
  address_prefixes     = [var.app_subnet_address_prefix]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "${var.vnet_name}-db"
  resource_group_name  = azurerm_resource_group.net_comp_task_rg.name
  virtual_network_name = azurerm_virtual_network.net_comp_task_vnet.name
  address_prefixes     = [var.db_subnet_address_prefix]
}

resource "azurerm_public_ip" "nat_pip" {
  name                = "${var.vnet_name}-nat-pip"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "${var.vnet_name}-nat"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  sku_name            = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "app_subnet_nat_association" {
  subnet_id      = azurerm_subnet.app_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

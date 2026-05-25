resource "azurerm_application_security_group" "bastion_asg" {
  name                = "${var.vnet_name}-asg-bastion"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags
}

resource "azurerm_application_security_group" "app_asg" {
  name                = "${var.vnet_name}-asg-app"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags
}

resource "azurerm_application_security_group" "db_asg" {
  name                = "${var.vnet_name}-asg-db"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${var.vnet_name}-nsg-bastion"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSSHFromAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.vnet_name}-nsg-app"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags

  security_rule {
    name                                       = "AllowSSHFromBastion"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "22"
    source_application_security_group_ids      = [azurerm_application_security_group.bastion_asg.id]
    destination_application_security_group_ids = [azurerm_application_security_group.app_asg.id]
  }

  security_rule {
    name                                       = "AllowAppPortFromBastion"
    priority                                   = 110
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "5000"
    source_application_security_group_ids      = [azurerm_application_security_group.bastion_asg.id]
    destination_application_security_group_ids = [azurerm_application_security_group.app_asg.id]
  }

  security_rule {
    name                                       = "AllowPostgresToDb"
    priority                                   = 100
    direction                                  = "Outbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "5432"
    source_application_security_group_ids      = [azurerm_application_security_group.app_asg.id]
    destination_application_security_group_ids = [azurerm_application_security_group.db_asg.id]
  }

  security_rule {
    name                                  = "AllowHttpsForUpdates"
    priority                              = 110
    direction                             = "Outbound"
    access                                = "Allow"
    protocol                              = "Tcp"
    source_port_range                     = "*"
    destination_port_range                = "443"
    source_application_security_group_ids = [azurerm_application_security_group.app_asg.id]
    destination_address_prefix            = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.vnet_name}-nsg-db"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  tags                = local.tags

  security_rule {
    name                                       = "AllowPostgresFromApp"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "5432"
    source_application_security_group_ids      = [azurerm_application_security_group.app_asg.id]
    destination_application_security_group_ids = [azurerm_application_security_group.db_asg.id]
  }

  security_rule {
    name                                       = "AllowSSHFromBastion"
    priority                                   = 110
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "22"
    source_application_security_group_ids      = [azurerm_application_security_group.bastion_asg.id]
    destination_application_security_group_ids = [azurerm_application_security_group.db_asg.id]
  }
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

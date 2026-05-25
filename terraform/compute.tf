resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_vm_name}-pip"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "${var.bastion_vm_name}-nic"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }

  tags = merge(local.tags, { role = "bastion" })
}

resource "azurerm_network_interface_application_security_group_association" "bastion_nic_asg_association" {
  network_interface_id          = azurerm_network_interface.bastion_nic.id
  application_security_group_id = azurerm_application_security_group.bastion_asg.id
}

resource "azurerm_network_interface_security_group_association" "bastion_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

resource "azurerm_network_interface" "app_nic" {
  name                = "${var.app_vm_name}-nic"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = var.app_private_ip != "" ? "Static" : "Dynamic"
    private_ip_address            = var.app_private_ip != "" ? var.app_private_ip : null
  }

  tags = merge(local.tags, { role = "app" })
}

resource "azurerm_network_interface_application_security_group_association" "app_nic_asg_association" {
  network_interface_id          = azurerm_network_interface.app_nic.id
  application_security_group_id = azurerm_application_security_group.app_asg.id
}

resource "azurerm_network_interface" "db_nic" {
  name                = "${var.db_vm_name}-nic"
  location            = azurerm_resource_group.net_comp_task_rg.location
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = var.db_private_ip != "" ? "Static" : "Dynamic"
    private_ip_address            = var.db_private_ip != "" ? var.db_private_ip : null
  }

  tags = merge(local.tags, { role = "db" })
}

resource "azurerm_network_interface_application_security_group_association" "db_nic_asg_association" {
  network_interface_id          = azurerm_network_interface.db_nic.id
  application_security_group_id = azurerm_application_security_group.db_asg.id
}

resource "azurerm_linux_virtual_machine" "bastion_vm" {
  name                = var.bastion_vm_name
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  location            = azurerm_resource_group.net_comp_task_rg.location
  size                = var.bastion_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.bastion_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  os_disk {
    caching              = var.caching_type
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  tags = merge(local.tags, { role = "bastion" })
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = var.app_vm_name
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  location            = azurerm_resource_group.net_comp_task_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.app_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  custom_data = base64encode(templatefile("${path.module}/../scripts/cloud-init-app.tpl", {
    app_env     = var.env
    db_host     = azurerm_network_interface.db_nic.private_ip_address
    db_port     = var.db_port
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    db_sslmode  = var.db_sslmode
    port        = var.app_port
    bg_color    = var.bg_color
  }))

  depends_on = [azurerm_linux_virtual_machine.db_vm]

  os_disk {
    caching              = var.caching_type
    storage_account_type = var.storage_account_type
  }

  dynamic "source_image_reference" {
    for_each = var.custom_image_id == "" ? [1] : []
    content {
      publisher = var.publisher
      offer     = var.offer
      sku       = var.sku
      version   = var.image_version
    }
  }

  source_image_id = var.custom_image_id != "" ? var.custom_image_id : null

  tags = merge(local.tags, { role = "app" })
}

resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = var.db_vm_name
  resource_group_name = azurerm_resource_group.net_comp_task_rg.name
  location            = azurerm_resource_group.net_comp_task_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.db_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  custom_data = base64encode(templatefile("${path.module}/../scripts/install-db.sh", {
    db_user              = var.db_user
    db_name              = var.db_name
    db_password_sql_safe = replace(var.db_password, "'", "''")
    app_subnet_cidr      = var.app_subnet_address_prefix
  }))

  os_disk {
    caching              = var.caching_type
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  tags = merge(local.tags, { role = "db" })
}

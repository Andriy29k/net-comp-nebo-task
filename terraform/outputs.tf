output "resource_group_name" {
  value = azurerm_resource_group.net_comp_task_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.net_comp_task_vnet.name
}

output "public_subnet_name" {
  value = azurerm_subnet.public_subnet.name
}

output "app_subnet_name" {
  value = azurerm_subnet.app_subnet.name
}

output "db_subnet_name" {
  value = azurerm_subnet.db_subnet.name
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat_pip.ip_address
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}

output "app_private_ip" {
  value = azurerm_network_interface.app_nic.private_ip_address
}

output "db_private_ip" {
  value = azurerm_network_interface.db_nic.private_ip_address
}

output "ssh_to_bastion" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address} -i ${replace(var.ssh_key_path, ".pub", "")}"
}

output "ssh_to_app_via_bastion" {
  value = "ssh -J ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address} ${var.admin_username}@${azurerm_network_interface.app_nic.private_ip_address} -i ${replace(var.ssh_key_path, ".pub", "")}"
}

output "app_url_via_tunnel" {
  value = "http://127.0.0.1:5000"
}

output "ssh_port_forward_app" {
  value = "ssh -L 5000:${azurerm_network_interface.app_nic.private_ip_address}:5000 ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address} -i ${replace(var.ssh_key_path, ".pub", "")} -N"
}

output "health_check_via_bastion" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address} -i ${replace(var.ssh_key_path, ".pub", "")} 'curl -s http://${azurerm_network_interface.app_nic.private_ip_address}:5000/health'"
}

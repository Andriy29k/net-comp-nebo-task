variable "subscription" {
  type = string
}

variable "subscription_label" {
  type        = string
  description = "Tag value only (not the Azure subscription GUID)."
  default     = "VSES"
}

variable "owner" {
  type    = string
  default = "akorot"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "public_subnet_address_prefix" {
  type = string
}

variable "app_subnet_address_prefix" {
  type = string
}

variable "db_subnet_address_prefix" {
  type = string
}

variable "app_vm_name" {
  type = string
}

variable "db_vm_name" {
  type = string
}

variable "bastion_vm_name" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "bastion_vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_key_path" {
  type = string
}

variable "admin_source_cidr" {
  type = string
}

variable "publisher" {
  type = string
}

variable "offer" {
  type = string
}

variable "sku" {
  type = string
}

variable "image_version" {
  type = string
}

variable "storage_account_type" {
  type = string
}

variable "caching_type" {
  type = string
}

variable "env" {
  type = string
}

variable "db_user" {
  type        = string
  default     = "todos"
}

variable "db_name" {
  type        = string
  default     = "todos"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "custom_image_id" {
  type    = string
  default = ""
}

variable "db_private_ip" {
  type    = string
  default = ""
}

variable "app_private_ip" {
  type    = string
  default = ""
}

variable "db_port" {
  type    = string
  default = "5432"
}

variable "db_sslmode" {
  type    = string
  default = "prefer"
}

variable "app_port" {
  type    = string
  default = "5000"
}

variable "bg_color" {
  type    = string
  default = "lightblue"
}

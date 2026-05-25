locals {
  tags = {
    env          = var.env
    project      = "network-compute-task"
    owner        = var.owner
    subscription = var.subscription_label
  }
}

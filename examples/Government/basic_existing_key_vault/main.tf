# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Terraform module for deploying a basic App Configuration with User Assigned Identity and Existing Key Vault in Azure. 

module "mod_app_configuration" {
  #source  = "github.com/POps-Rox/terraform-az-overlays-appconfiguration"
  #version = "x.x.x"
  source = "../../.."

  depends_on = [
    azurerm_resource_group.app-config-rg,
  ]

  # Resource Group, location, VNet and Subnet details
  existing_resource_group_name = azurerm_resource_group.app-config-rg.name
  location                     = var.location
  deploy_environment           = var.deploy_environment
  org_name                     = var.org_name
  workload_name                = var.workload_name
  environment                  = var.environment

  # User Assigned Identity Configuration
  identity_type          = "UserAssigned"
  existing_principal_ids = ["${azurerm_user_assigned_identity.app-config-id.principal_id}"]

  # Key Vault Configuration
  existing_key_vault_id                  = azurerm_key_vault.app-config-kv.id
  existing_key_vault_principal_object_id = azurerm_user_assigned_identity.app-config-id.principal_id

  # Adding additional TAG's to your Azure resources
  add_tags = {
    Example = "basic_existing_key_vault"
  }
}

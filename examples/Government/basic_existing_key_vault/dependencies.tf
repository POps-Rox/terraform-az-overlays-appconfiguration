# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "azurerm_resource_group" "app-config-rg" {
  name     = "app-config-rg"
  location = var.location
  tags = {
    environment = "test"
  }
}

resource "azurerm_user_assigned_identity" "app-config-id" {
  name                = "app-config-identity"
  location            = azurerm_resource_group.app-config-rg.location
  resource_group_name = azurerm_resource_group.app-config-rg.name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "app-config-kv" {
  name                       = "app-configKVt123"
  location                   = azurerm_resource_group.app-config-rg.location
  resource_group_name        = azurerm_resource_group.app-config-rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  rbac_authorization_enabled = false
}

resource "azurerm_key_vault_access_policy" "server" {
  key_vault_id = azurerm_key_vault.app-config-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app-config-id.principal_id

  key_permissions    = ["Get", "UnwrapKey", "WrapKey"]
  secret_permissions = ["Get"]
}

resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.app-config-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions    = ["Get", "Create", "Delete", "List", "Restore", "Recover", "UnwrapKey", "WrapKey", "Purge", "Encrypt", "Decrypt", "Sign", "Verify", "GetRotationPolicy"]
  secret_permissions = ["Get"]
}

resource "azurerm_key_vault_key" "app-config" {
  name         = "app-configKVkey"
  key_vault_id = azurerm_key_vault.app-config-kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  depends_on = [
    azurerm_key_vault_access_policy.client,
    azurerm_key_vault_access_policy.server,
  ]
}



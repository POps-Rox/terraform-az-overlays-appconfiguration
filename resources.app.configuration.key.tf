# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------------
# Azure App Configuration Key
#---------------------------------------------------------------
resource "azurerm_app_configuration_key" "test" {
  for_each               = var.app_configuration_keys == null ? {} : var.app_configuration_keys
  configuration_store_id = azurerm_app_configuration.app_configuration.id
  key                    = each.key
  label                  = each.value.label
  value                  = each.value.value

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

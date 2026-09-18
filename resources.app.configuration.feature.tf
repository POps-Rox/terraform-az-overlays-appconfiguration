# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------------
# Azure App Configuration Key
#---------------------------------------------------------------
resource "azurerm_app_configuration_feature" "feature" {
  for_each               = var.app_configuration_features == null ? {} : var.app_configuration_features
  configuration_store_id = azurerm_app_configuration.app_configuration.id
  description            = each.value.description
  name                   = each.value.name
  label                  = each.value.label
  enabled                = each.value.enabled

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

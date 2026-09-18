# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  # Naming locals/constants
  name_prefix = lower(var.name_prefix)
  name_suffix = lower(var.name_suffix)

  resource_group_name    = element(coalescelist(data.azurerm_resource_group.rg.*.name, module.mod_scaffold_rg.*.resource_group_name, [""]), 0)
  location               = element(coalescelist(data.azurerm_resource_group.rg.*.location, module.mod_scaffold_rg.*.resource_group_location, [""]), 0)
  app_configuration_name = var.custom_app_configuration_name != null && var.custom_app_configuration_name != "" ? var.custom_app_configuration_name : data.popsrox_resource_name.example_custom_name.result
}

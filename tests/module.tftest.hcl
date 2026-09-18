# Functional tests for the app configuration overlay.
# These use mock_provider and module overrides, so they execute without Azure credentials.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
      name     = "rg-existing"
      location = "westus2"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      object_id       = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
    }
  }

  mock_resource "azurerm_app_configuration" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.AppConfiguration/configurationStores/generated-appcs"
      endpoint = "https://generated-appcs.azconfig.io"
    }
  }
}

mock_provider "azapi" {}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generated-appcs"
    }
  }
}

override_module {
  target = module.mod_azregions
  outputs = {
    location_cli   = "eastus"
    location_short = "eus"
  }
}

override_module {
  target = module.mod_scaffold_rg
  outputs = {
    resource_group_name     = "created-rg"
    resource_group_location = "centralus"
  }
}

variables {
  location                     = "eastus"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "appconf"
  org_name                     = "anoa"
  existing_resource_group_name = "rg-existing"
}

run "generated_name_is_used_when_no_custom_name_given" {
  command = plan

  assert {
    condition     = local.app_configuration_name == "generated-appcs" && azurerm_app_configuration.app_configuration.name == "generated-appcs"
    error_message = "Expected generated popsrox App Configuration name when custom_app_configuration_name is unset."
  }
}

run "custom_name_overrides_generated_name" {
  command = plan

  variables {
    custom_app_configuration_name = "explicit-appcs"
  }

  assert {
    condition     = local.app_configuration_name == "explicit-appcs" && azurerm_app_configuration.app_configuration.name == "explicit-appcs"
    error_message = "custom_app_configuration_name must take precedence over the generated name."
  }
}

run "empty_custom_name_falls_through_to_generated_name" {
  command = plan

  variables {
    custom_app_configuration_name = ""
  }

  assert {
    condition     = local.app_configuration_name == "generated-appcs" && azurerm_app_configuration.app_configuration.name == "generated-appcs"
    error_message = "An empty custom_app_configuration_name must fall through to the generated name."
  }
}

run "existing_resource_group_path_is_used_by_default" {
  command = plan

  variables {
    create_app_config_resource_group = false
  }

  assert {
    condition     = length(data.azurerm_resource_group.rg) == 1
    error_message = "create_app_config_resource_group=false must look up one existing resource group."
  }

  assert {
    condition     = length(module.mod_scaffold_rg) == 0
    error_message = "create_app_config_resource_group=false must not create the resource group module."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.resource_group_name == "rg-existing"
    error_message = "Existing resource group name must pass through to the App Configuration resource."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.location == "westus2"
    error_message = "Existing resource group location must pass through to the App Configuration resource."
  }
}

run "created_resource_group_path_is_used_when_enabled" {
  command = plan

  variables {
    create_app_config_resource_group = true
    custom_resource_group_name       = ""
  }

  assert {
    condition     = length(data.azurerm_resource_group.rg) == 0
    error_message = "create_app_config_resource_group=true must skip existing resource group lookup."
  }

  assert {
    condition     = length(module.mod_scaffold_rg) == 1
    error_message = "create_app_config_resource_group=true must create one resource group module instance."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.resource_group_name == "created-rg"
    error_message = "Created resource group module output must drive resource_group_name."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.location == "centralus"
    error_message = "Created resource group module output must drive location."
  }
}

run "data_owner_role_absent_without_keys_or_features" {
  command = plan

  assert {
    condition     = length(azurerm_role_assignment.appconf_dataowner) == 0
    error_message = "The data owner role assignment should not be created when keys and features are null."
  }

  assert {
    condition     = length(azurerm_app_configuration_key.test) == 0
    error_message = "Null app_configuration_keys must behave as an empty map."
  }

  assert {
    condition     = length(azurerm_app_configuration_feature.feature) == 0
    error_message = "Null app_configuration_features must behave as an empty map."
  }
}

run "data_owner_role_and_children_present_with_keys_and_features" {
  command = plan

  variables {
    app_configuration_keys = {
      "settings:message" = {
        label = "prod"
        value = "hello"
      }
    }
    app_configuration_features = {
      beta = {
        description = "Beta experience"
        name        = "BetaFeature"
        label       = "prod"
        enabled     = true
      }
    }
  }

  assert {
    condition     = length(azurerm_role_assignment.appconf_dataowner) == 1
    error_message = "Supplying keys or features must create exactly one App Configuration Data Owner role assignment."
  }

  assert {
    condition     = azurerm_app_configuration_key.test["settings:message"].value == "hello"
    error_message = "App Configuration key values must pass through from app_configuration_keys."
  }

  assert {
    condition     = azurerm_app_configuration_feature.feature["beta"].enabled == true
    error_message = "App Configuration feature enabled flag must pass through from app_configuration_features."
  }
}

run "caller_tags_are_merged_with_defaults" {
  command = plan

  variables {
    add_tags = {
      costCenter = "cc-1234"
      workload   = "caller-workload"
    }
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.tags["costCenter"] == "cc-1234"
    error_message = "Tags passed via add_tags must appear on the App Configuration resource."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.tags["env"] == "public"
    error_message = "Default tags must include the environment value."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.tags["workload"] == "caller-workload"
    error_message = "Caller tags should override default tags with the same key."
  }
}

run "input_properties_pass_through" {
  command = plan

  variables {
    sku                           = "premium"
    public_network_access_enabled = false
    enable_purge_protection       = true
    soft_delete_retention_days    = 3
    local_auth_enabled            = true
    replica_name                  = "dr"
    replica_location              = "westus"
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.sku == "premium"
    error_message = "sku input must pass through to the App Configuration resource."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.public_network_access == "Disabled"
    error_message = "public_network_access_enabled=false must map internally to public_network_access=Disabled."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.purge_protection_enabled == true
    error_message = "enable_purge_protection input must map internally to purge_protection_enabled."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.soft_delete_retention_days == 3
    error_message = "soft_delete_retention_days must pass through."
  }

  assert {
    condition     = azurerm_app_configuration.app_configuration.local_auth_enabled == true
    error_message = "local_auth_enabled must pass through."
  }

  assert {
    condition     = one(azurerm_app_configuration.app_configuration.replica).name == "dr" && one(azurerm_app_configuration.app_configuration.replica).location == "westus"
    error_message = "Replica name and location must pass through."
  }
}

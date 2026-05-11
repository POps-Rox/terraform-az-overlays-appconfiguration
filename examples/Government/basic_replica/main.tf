# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Terraform module for deploying a basic App Configuration with Replica Configuration in Azure. 

module "mod_app_configuration" {
  #source  = "github.com/POps-Rox/terraform-az-overlays-appconfiguration"
  #version = "x.x.x"
  source = "../../.."

  # Resource Group, location, VNet and Subnet details
  create_app_config_resource_group = true
  location                         = var.location
  deploy_environment               = var.deploy_environment
  org_name                         = var.org_name
  workload_name                    = var.workload_name
  environment                      = var.environment

  # Replica Configuration
  replica_name     = "app-config-replica"
  replica_location = "West US"

  # Adding additional TAG's to your Azure resources
  add_tags = {
    Example = "basic_user_assigned_identity"
  }
}

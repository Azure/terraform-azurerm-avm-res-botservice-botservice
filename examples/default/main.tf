terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "East US 2"
  name     = "avm-res-bostservices-botservice-${module.naming.resource_group.name_unique}"
}

resource "random_pet" "pet" {}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-zjee-bot"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                = "global"
  name                    = "AzureBot-${random_pet.pet.id}"
  resource_group_name     = azurerm_resource_group.this.name
  sku                     = "F0"
  microsoft_app_id        = azurerm_user_assigned_identity.this.client_id
  microsoft_app_msi_id    = azurerm_user_assigned_identity.this.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.this.tenant_id
  enable_telemetry        = var.enable_telemetry
  microsoft_app_type      = "UserAssignedMSI"
}

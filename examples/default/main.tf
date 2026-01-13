terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

resource "random_pet" "pet" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${random_pet.pet.id}"
  location = "eastus2"
}

resource "azurerm_user_assigned_identity" "uai" {
  name                = "uai-${random_pet.pet.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "bot" {
  source = "../../"

  location                = "global"
  resource_group_name     = azurerm_resource_group.rg.name
  name                    = "bot-${random_pet.pet.id}"
  microsoft_app_id        = azurerm_user_assigned_identity.uai.client_id
  microsoft_app_msi_id    = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  endpoint                = "https://example.com/api/messages"
  sku                     = "F0"

  schema_validation_enabled = false
}

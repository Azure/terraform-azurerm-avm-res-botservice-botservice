terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.8"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57"
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
  location = "eastus2"
  name     = "rg-${random_pet.pet.id}"
}

resource "azurerm_user_assigned_identity" "uai" {
  location            = azurerm_resource_group.rg.location
  name                = "uai-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

module "bot" {
  source = "../../"

  location                  = "global"
  microsoft_app_id          = azurerm_user_assigned_identity.uai.client_id
  name                      = "bot-${random_pet.pet.id}"
  resource_group_name       = azurerm_resource_group.rg.name
  endpoint                  = "https://example.com/api/messages"
  microsoft_app_msi_id      = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id   = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type        = "UserAssignedMSI"
  schema_validation_enabled = false
  sku                       = "F0"
  enable_telemetry          = var.enable_telemetry
}

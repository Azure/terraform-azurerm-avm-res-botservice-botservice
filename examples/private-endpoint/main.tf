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

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_pet.pet.id}"
  address_space       = ["10.52.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "botservice"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.52.0.0/24"]
}

resource "azurerm_private_dns_zone" "zone" {
  name                = "privatelink.botservice.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "botservice-link"
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
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

  private_endpoints = {
    pe = {
      subnet_resource_id              = azurerm_subnet.subnet.id
      private_dns_zone_resource_ids   = [azurerm_private_dns_zone.zone.id]
      private_service_connection_name = "pesc-${random_pet.pet.id}"
      name                            = "pe-${random_pet.pet.id}"
      location                        = azurerm_resource_group.rg.location
    }
  }

  schema_validation_enabled = false
}

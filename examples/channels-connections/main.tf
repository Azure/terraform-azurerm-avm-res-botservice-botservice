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

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "vnet-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "subnet-${random_pet.pet.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_private_endpoint" "pe" {
  location            = azurerm_resource_group.rg.location
  name                = "pe-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "pec1"
    private_connection_resource_id = module.bot.resource_id
    request_message                = null
    subresource_names              = ["Bot"]
  }
}

resource "random_password" "conn_secret" {
  length  = 32
  special = true
}

module "bot" {
  source = "../../"

  location            = "global"
  microsoft_app_id    = azurerm_user_assigned_identity.uai.client_id
  name                = "bot-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
  channels = {
    msteams = {
      channel_name = "MsTeamsChannel"
      properties = {
        isEnabled = true
      }
    }
  }
  connections = {
    sample-conn = {
      properties = {
        clientId                   = azurerm_user_assigned_identity.uai.client_id
        clientSecret               = random_password.conn_secret.result
        name                       = "conn-${random_pet.pet.id}"
        serviceProviderDisplayName = "GitHub"
        serviceProviderId          = "d05eaacf-1593-4603-9c6c-d4d8fffa46cb"
        scopes                     = ""
        parameters = [
          {
            key   = "clientId"
            value = azurerm_user_assigned_identity.uai.client_id
          },
          {
            key   = "clientSecret"
            value = random_password.conn_secret.result
          },
          {
            key   = "scopes"
            value = ""
          }
        ]
      }
    }
  }
  endpoint                  = "https://example.com/api/messages"
  microsoft_app_msi_id      = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id   = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type        = "UserAssignedMSI"
  schema_validation_enabled = false
  sku                       = "S1"
}

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

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_pet.pet.id}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${random_pet.pet.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_endpoint" "pe" {
  name                = "pe-${random_pet.pet.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "pec1"
    private_connection_resource_id = module.bot.resource_id
    is_manual_connection           = false
    subresource_names              = ["Bot"]
    request_message                = null
  }
}

resource "random_password" "conn_secret" {
  length  = 32
  special = true
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
  sku                     = "S1"

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

  schema_validation_enabled = false
}

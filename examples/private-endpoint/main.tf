terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
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


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "EAST US 2"
  name     = "avm-res-bostservices-botservice-${module.naming.resource_group.name_unique}"
}

module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    botservice = {
      address_prefixes = ["10.52.0.0/24"]
    }
  }
  virtual_network_address_space = ["10.52.0.0/16"]
  virtual_network_location      = azurerm_resource_group.this.location
  virtual_network_name          = "vnet"
}

resource "azurerm_private_dns_zone" "zone" {
  name                = "privatelink.botservice.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "botservice-private-dns-zone"
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = module.vnet.vnet_id
}

resource "random_pet" "pet" {}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-zjee-bot"
  resource_group_name = azurerm_resource_group.this.name
}

module "test" {
  source = "../../"

  location                = "global"
  microsoft_app_id        = azurerm_user_assigned_identity.this.client_id
  name                    = "AzureBot-${random_pet.pet.id}"
  resource_group_name     = azurerm_resource_group.this.name
  enable_telemetry        = var.enable_telemetry
  microsoft_app_msi_id    = azurerm_user_assigned_identity.this.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.this.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  private_endpoints = {
    pe_endpoint = {
      name                            = "pe_endpoint"
      private_dns_zone_resource_ids   = toset([azurerm_private_dns_zone.zone.id])
      private_service_connection_name = "pe_endpoint_connection"
      subnet_resource_id              = module.vnet.vnet_subnets_name_id["botservice"]
      location                        = azurerm_resource_group.this.location
    }

  }
  sku = "F0"
}

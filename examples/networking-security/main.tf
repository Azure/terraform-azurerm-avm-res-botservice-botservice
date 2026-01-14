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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

resource "random_pet" "pet" {}

resource "azurerm_resource_group" "rg" {
  location = "eastus2"
  name     = "rg-${random_pet.pet.id}"
}

resource "azurerm_user_assigned_identity" "uai_module_pe" {
  location            = azurerm_resource_group.rg.location
  name                = "uai-module-pe-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "uai_manual_pe" {
  location            = azurerm_resource_group.rg.location
  name                = "uai-manual-pe-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "uai_approval" {
  location            = azurerm_resource_group.rg.location
  name                = "uai-approval-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "uai_nsp" {
  location            = azurerm_resource_group.rg.location
  name                = "uai-nsp-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
}

# Virtual Network and Subnet for Private Endpoints
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

# Private DNS Zone for Private Endpoint
resource "azurerm_private_dns_zone" "bot" {
  name                = "privatelink.directline.botframework.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "bot" {
  name                  = "vnet-link-${random_pet.pet.id}"
  private_dns_zone_name = azurerm_private_dns_zone.bot.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Bot Service with Module-Managed Private Endpoint
module "bot_with_module_pe" {
  source = "../../"

  location                = "global"
  microsoft_app_id        = azurerm_user_assigned_identity.uai_module_pe.client_id
  name                    = "bot-module-pe-${random_pet.pet.id}"
  resource_group_name     = azurerm_resource_group.rg.name
  endpoint                = "https://example.com/api/messages"
  microsoft_app_msi_id    = azurerm_user_assigned_identity.uai_module_pe.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.uai_module_pe.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  # Option 1: Module-managed private endpoint (uses azurerm_private_endpoint)
  private_endpoints = {
    primary = {
      location                      = azurerm_resource_group.rg.location
      subnet_resource_id            = azurerm_subnet.subnet.id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.bot.id]
      private_dns_zone_group_name   = "bot-dns-zone-group"
      tags = {
        managed_by = "module"
      }
    }
  }
  # Disable public network access when using private endpoints
  public_network_access_enabled = false
  schema_validation_enabled     = false
  sku                           = "S1"
  timeouts = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# Bot Service for demonstrating manual private endpoint (created outside module)
module "bot_with_manual_pe" {
  source = "../../"

  location                      = "global"
  microsoft_app_id              = azurerm_user_assigned_identity.uai_manual_pe.client_id
  name                          = "bot-manual-pe-${random_pet.pet.id}"
  resource_group_name           = azurerm_resource_group.rg.name
  endpoint                      = "https://example.com/api/messages"
  microsoft_app_msi_id          = azurerm_user_assigned_identity.uai_manual_pe.id
  microsoft_app_tenant_id       = azurerm_user_assigned_identity.uai_manual_pe.tenant_id
  microsoft_app_type            = "UserAssignedMSI"
  public_network_access_enabled = false
  schema_validation_enabled     = false
  sku                           = "S1"
  timeouts = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# Option 2: Manually created private endpoint (outside module)
resource "azurerm_private_endpoint" "manual" {
  location            = azurerm_resource_group.rg.location
  name                = "pe-manual-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-manual-${random_pet.pet.id}"
    private_connection_resource_id = module.bot_with_manual_pe.resource_id
    subresource_names              = ["Bot"]
  }
  private_dns_zone_group {
    name                 = "manual-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.bot.id]
  }
}

# Bot Service for demonstrating private endpoint connection approval
module "bot_with_approval" {
  source = "../../"

  location                      = "global"
  microsoft_app_id              = azurerm_user_assigned_identity.uai_approval.client_id
  name                          = "bot-approval-${random_pet.pet.id}"
  resource_group_name           = azurerm_resource_group.rg.name
  endpoint                      = "https://example.com/api/messages"
  microsoft_app_msi_id          = azurerm_user_assigned_identity.uai_approval.id
  microsoft_app_tenant_id       = azurerm_user_assigned_identity.uai_approval.tenant_id
  microsoft_app_type            = "UserAssignedMSI"
  public_network_access_enabled = true
  schema_validation_enabled     = false
  sku                           = "S1"
  timeouts = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# External private endpoint requesting manual approval
resource "azurerm_private_endpoint" "external" {
  location            = azurerm_resource_group.rg.location
  name                = "pe-external-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection           = true # Requires approval
    name                           = "psc-external-${random_pet.pet.id}"
    private_connection_resource_id = module.bot_with_approval.resource_id
    request_message                = "Please approve this connection"
    subresource_names              = ["Bot"]
  }
}

# Option 3: Manage private endpoint connection approvals (uses azapi - preview API)
# Note: In production, you would get the connection name/ID from the external PE request
# This demonstrates the capability - actual approval would happen after PE is created
# and you retrieve the connection details from the bot service

# Bot Service with Network Security Perimeter
module "bot_with_nsp" {
  source = "../../"

  location                = "global"
  microsoft_app_id        = azurerm_user_assigned_identity.uai_nsp.client_id
  name                    = "bot-nsp-${random_pet.pet.id}"
  resource_group_name     = azurerm_resource_group.rg.name
  endpoint                = "https://example.com/api/messages"
  microsoft_app_msi_id    = azurerm_user_assigned_identity.uai_nsp.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.uai_nsp.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  # Use SecuredByPerimeter for NSP scenarios
  public_network_access     = "SecuredByPerimeter"
  schema_validation_enabled = false
  sku                       = "S1"
  timeouts = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}





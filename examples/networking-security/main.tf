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

# Virtual Network and Subnet for Private Endpoints
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

# Private DNS Zone for Private Endpoint
resource "azurerm_private_dns_zone" "bot" {
  name                = "privatelink.directline.botframework.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "bot" {
  name                  = "vnet-link-${random_pet.pet.id}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.bot.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Bot Service with Module-Managed Private Endpoint
module "bot_with_module_pe" {
  source = "../../"

  location                = "global"
  resource_group_name     = azurerm_resource_group.rg.name
  name                    = "bot-module-pe-${random_pet.pet.id}"
  microsoft_app_id        = azurerm_user_assigned_identity.uai.client_id
  microsoft_app_msi_id    = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  endpoint                = "https://example.com/api/messages"
  sku                     = "S1"

  # Disable public network access when using private endpoints
  public_network_access_enabled = false

  # Option 1: Module-managed private endpoint (uses azurerm_private_endpoint)
  private_endpoints = {
    primary = {
      subnet_resource_id            = azurerm_subnet.subnet.id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.bot.id]
      private_dns_zone_group_name   = "bot-dns-zone-group"
      tags = {
        managed_by = "module"
      }
    }
  }

  schema_validation_enabled = false
}

# Bot Service for demonstrating manual private endpoint (created outside module)
module "bot_with_manual_pe" {
  source = "../../"

  location                      = "global"
  resource_group_name           = azurerm_resource_group.rg.name
  name                          = "bot-manual-pe-${random_pet.pet.id}"
  microsoft_app_id              = azurerm_user_assigned_identity.uai.client_id
  microsoft_app_msi_id          = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id       = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type            = "UserAssignedMSI"
  endpoint                      = "https://example.com/api/messages"
  sku                           = "S1"
  public_network_access_enabled = false
  schema_validation_enabled     = false
}

# Option 2: Manually created private endpoint (outside module)
resource "azurerm_private_endpoint" "manual" {
  name                = "pe-manual-${random_pet.pet.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "psc-manual-${random_pet.pet.id}"
    private_connection_resource_id = module.bot_with_manual_pe.resource_id
    is_manual_connection           = false
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
  resource_group_name           = azurerm_resource_group.rg.name
  name                          = "bot-approval-${random_pet.pet.id}"
  microsoft_app_id              = azurerm_user_assigned_identity.uai.client_id
  microsoft_app_msi_id          = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id       = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type            = "UserAssignedMSI"
  endpoint                      = "https://example.com/api/messages"
  sku                           = "S1"
  public_network_access_enabled = true
  schema_validation_enabled     = false
}

# External private endpoint requesting manual approval
resource "azurerm_private_endpoint" "external" {
  name                = "pe-external-${random_pet.pet.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "psc-external-${random_pet.pet.id}"
    private_connection_resource_id = module.bot_with_approval.resource_id
    is_manual_connection           = true # Requires approval
    subresource_names              = ["Bot"]
    request_message                = "Please approve this connection"
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
  resource_group_name     = azurerm_resource_group.rg.name
  name                    = "bot-nsp-${random_pet.pet.id}"
  microsoft_app_id        = azurerm_user_assigned_identity.uai.client_id
  microsoft_app_msi_id    = azurerm_user_assigned_identity.uai.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.uai.tenant_id
  microsoft_app_type      = "UserAssignedMSI"
  endpoint                = "https://example.com/api/messages"
  sku                     = "S1"

  # Use SecuredByPerimeter for NSP scenarios
  public_network_access = "SecuredByPerimeter"

  # Option 4: Network Security Perimeter configuration (uses azapi - preview API)
  # Note: This requires an actual NSP to be created first
  # Commented out because NSP creation requires additional setup
  # network_security_perimeter_configurations = {
  #   primary = {
  #     name = "nsp-config-${random_pet.pet.id}"
  #   }
  # }

  schema_validation_enabled = false
}

output "module_managed_pe_bot_id" {
  value       = module.bot_with_module_pe.resource_id
  description = "Bot with module-managed private endpoint"
}

output "manual_pe_bot_id" {
  value       = module.bot_with_manual_pe.resource_id
  description = "Bot with manually created private endpoint"
}

output "approval_bot_id" {
  value       = module.bot_with_approval.resource_id
  description = "Bot for demonstrating connection approval"
}

output "nsp_bot_id" {
  value       = module.bot_with_nsp.resource_id
  description = "Bot with Network Security Perimeter configuration"
}

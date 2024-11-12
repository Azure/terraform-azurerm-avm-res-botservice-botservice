
resource "azurerm_bot_service_azure_bot" "this" {
  location                              = var.location
  microsoft_app_id                      = var.microsoft_app_id
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  sku                                   = var.sku
  developer_app_insights_api_key        = var.developer_app_insights_api_key
  developer_app_insights_application_id = var.developer_app_insights_application_id
  developer_app_insights_key            = var.developer_app_insights_key
  display_name                          = var.display_name
  endpoint                              = var.endpoint
  icon_url                              = var.icon_url
  local_authentication_enabled          = var.local_authentication_enabled
  microsoft_app_msi_id                  = var.microsoft_app_msi_id
  microsoft_app_tenant_id               = var.microsoft_app_tenant_id
  microsoft_app_type                    = var.microsoft_app_type
  public_network_access_enabled         = var.public_network_access_enabled
  streaming_endpoint_enabled            = var.streaming_endpoint_enabled
  tags                                  = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

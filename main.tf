data "azapi_client_config" "this" {}


resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.BotService/botServices@2023-09-15-preview"
  body = merge({
    kind = var.kind
    properties = merge(
      {
        displayName = coalesce(var.display_name, var.name)
        msaAppId    = var.microsoft_app_id
      },
      var.endpoint != null ? { endpoint = var.endpoint } : {},
      var.icon_url != null ? { iconUrl = var.icon_url } : {},
      var.developer_app_insights_key != null ? { developerAppInsightKey = var.developer_app_insights_key } : {},
      var.developer_app_insights_api_key != null ? { developerAppInsightsApiKey = var.developer_app_insights_api_key } : {},
      var.developer_app_insights_application_id != null ? { developerAppInsightsApplicationId = var.developer_app_insights_application_id } : {},
      var.microsoft_app_msi_id != null ? { msaAppMSIResourceId = var.microsoft_app_msi_id } : {},
      var.microsoft_app_tenant_id != null ? { msaAppTenantId = var.microsoft_app_tenant_id } : {},
      var.microsoft_app_type != null ? { msaAppType = var.microsoft_app_type } : {},
      var.public_network_access != null ? { publicNetworkAccess = var.public_network_access } : (
        var.public_network_access_enabled == null ? {} : { publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled" }
      ),
      var.streaming_endpoint_enabled != null ? { isStreamingSupported = var.streaming_endpoint_enabled } : {},
      var.local_authentication_enabled == null ? {} : { disableLocalAuth = !var.local_authentication_enabled }
    )
    sku = {
      name = var.sku
    }
  })
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  ignore_missing_property   = true
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  response_export_values    = ["id", "name", "type", "properties", "sku"]
  schema_validation_enabled = var.schema_validation_enabled
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null

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

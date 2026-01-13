resource "azapi_resource" "channels" {
  for_each = var.channels

  location  = coalesce(each.value.location, var.location)
  name      = coalesce(each.value.name, each.value.channel_name)
  parent_id = azapi_resource.this.id
  type      = "Microsoft.BotService/botServices/channels@2023-09-15-preview"
  body = merge({
    kind = coalesce(each.value.kind, var.kind)
    properties = merge(
      {
        channelName = each.value.channel_name
      },
      each.value.properties != null ? each.value.properties : {}
    )
  }, each.value.sku != null ? { sku = { name = each.value.sku } } : {})
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  response_export_values    = ["id", "name", "type", "properties", "sku"]
  schema_validation_enabled = var.schema_validation_enabled
  tags                      = each.value.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
}

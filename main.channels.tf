locals {
  channel_bodies = {
    for k, v in var.channels : k => merge({
      kind = coalesce(v.kind, var.kind)
      properties = merge(
        {
          channelName = v.channel_name
        },
        v.properties != null ? v.properties : {}
      )
      },
      v.sku != null ? { sku = { name = v.sku } } : {},
      v.etag != null ? { etag = v.etag } : {}
    )
  }
}

resource "azapi_resource" "channels" {
  for_each = var.channels

  location                  = coalesce(each.value.location, var.location)
  name                      = coalesce(each.value.name, each.value.channel_name)
  parent_id                 = azapi_resource.this.id
  type                      = "Microsoft.BotService/botServices/channels@2023-09-15-preview"
  body                      = local.channel_bodies[each.key]
  response_export_values    = ["id", "name", "type", "properties", "sku"]
  schema_validation_enabled = var.schema_validation_enabled
  tags                      = var.tags
}

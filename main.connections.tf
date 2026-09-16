resource "azapi_resource" "connections" {
  for_each = var.connections

  location  = coalesce(each.value.location, var.location)
  name      = coalesce(each.value.name, each.key)
  parent_id = azapi_resource.this.id
  type      = "Microsoft.BotService/botServices/connections@2023-09-15-preview"
  body = merge({
    kind       = coalesce(each.value.kind, var.kind)
    properties = each.value.properties
    },
    each.value.sku != null ? { sku = { name = each.value.sku } } : {},
    each.value.etag != null ? { etag = each.value.etag } : {}
  )
  response_export_values    = ["id", "name", "type", "properties", "sku"]
  schema_validation_enabled = var.schema_validation_enabled
  # A GET on Microsoft.BotService/botServices/connections always returns the parent
  # bot's tags, discarding any tags written to the connection itself. Tracking
  # var.tags is therefore the only value that can converge against the read-back.
  tags = var.tags
}

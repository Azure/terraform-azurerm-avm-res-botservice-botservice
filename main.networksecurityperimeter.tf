resource "azapi_resource" "network_security_perimeter_configurations" {
  for_each = var.network_security_perimeter_configurations

  name                      = coalesce(each.value.name, each.key)
  parent_id                 = azapi_resource.this.id
  type                      = "Microsoft.BotService/botServices/networkSecurityPerimeterConfigurations@2023-09-15-preview"
  response_export_values    = ["id", "name", "type"]
  schema_validation_enabled = var.schema_validation_enabled
}

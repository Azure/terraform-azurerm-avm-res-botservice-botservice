resource "azapi_resource" "network_security_perimeter_configurations" {
  for_each = var.network_security_perimeter_configurations

  name                      = coalesce(each.value.name, each.key)
  parent_id                 = azapi_resource.this.id
  type                      = "Microsoft.BotService/botServices/networkSecurityPerimeterConfigurations@2023-09-15-preview"
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  response_export_values    = ["id", "name", "type"]
  schema_validation_enabled = var.schema_validation_enabled
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
}

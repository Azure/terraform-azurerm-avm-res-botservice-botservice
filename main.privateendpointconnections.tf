# Note: IDE may show schema validation warnings for expressions inside jsonencode() blocks.
# These are false positives and can be safely ignored. The schema_validation_enabled parameter
# is set to false by default for preview API versions to avoid runtime validation issues.
resource "azapi_resource" "private_endpoint_connections" {
  for_each = var.private_endpoint_connections

  name      = coalesce(each.value.name, each.key)
  parent_id = azapi_resource.this.id
  type      = "Microsoft.BotService/botServices/privateEndpointConnections@2023-09-15-preview"
  body = {
    properties = merge(
      {
        privateLinkServiceConnectionState = merge(
          {
            status = each.value.private_link_service_connection_state.status
          },
          each.value.private_link_service_connection_state.description != null ? { description = each.value.private_link_service_connection_state.description } : {},
          each.value.private_link_service_connection_state.actions_required != null ? { actionsRequired = each.value.private_link_service_connection_state.actions_required } : {}
        )
      },
      length(each.value.group_ids) > 0 ? { groupIds = each.value.group_ids } : {},
      each.value.private_endpoint != null ? { privateEndpoint = each.value.private_endpoint } : {}
    )
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
  response_export_values    = ["id", "name", "type", "properties"]
  schema_validation_enabled = var.schema_validation_enabled
  update_headers            = var.enable_telemetry ? { "User-Agent" = local.avm_azapi_header } : null
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = merge(
      each.value.event_hub_authorization_rule_resource_id != null ? { eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id } : {},
      each.value.event_hub_name != null ? { eventHubName = each.value.event_hub_name } : {},
      each.value.log_analytics_destination_type != null ? { logAnalyticsDestinationType = each.value.log_analytics_destination_type } : {},
      each.value.workspace_resource_id != null ? { workspaceId = each.value.workspace_resource_id } : {},
      each.value.marketplace_partner_resource_id != null ? { marketplacePartnerId = each.value.marketplace_partner_resource_id } : {},
      each.value.storage_account_resource_id != null ? { storageAccountId = each.value.storage_account_resource_id } : {},
      length(each.value.log_categories) > 0 ? {
        logs = [for category in each.value.log_categories : {
          category = category
          enabled  = true
        }]
      } : {},
      length(each.value.log_groups) > 0 ? {
        logs = [for group in each.value.log_groups : {
          categoryGroup = group
          enabled       = true
        }]
      } : {},
      length(each.value.metric_categories) > 0 ? {
        metrics = [for category in each.value.metric_categories : {
          category = category
          enabled  = true
        }]
      } : {}
    )
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property   = true
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = azapi_resource.this.id
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
  schema_validation_enabled = false
  ignore_missing_property   = true
}

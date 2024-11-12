output "name" {
  description = "The name of Azure Bot Service created."
  value       = azurerm_bot_service_azure_bot.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_id" {
  description = "The resource ID of Azure Bot Service created."
  value       = azurerm_bot_service_azure_bot.this.id
}

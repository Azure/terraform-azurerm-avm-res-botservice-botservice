output "name" {
  description = "The name of Azure Bot Service created."
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoint_managed_dns : azapi_resource.private_endpoint_unmanaged_dns
}

output "resource_id" {
  description = "The resource ID of Azure Bot Service created."
  value       = azapi_resource.this.id
}

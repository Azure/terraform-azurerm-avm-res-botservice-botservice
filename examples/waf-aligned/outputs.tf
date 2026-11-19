output "approval_bot_id" {
  description = "Bot for demonstrating connection approval"
  value       = module.bot_with_approval.resource_id
}

output "manual_pe_bot_id" {
  description = "Bot with manually created private endpoint"
  value       = module.bot_with_manual_pe.resource_id
}

output "module_managed_pe_bot_id" {
  description = "Bot with module-managed private endpoint"
  value       = module.bot_with_module_pe.resource_id
}

output "nsp_bot_id" {
  description = "Bot with Network Security Perimeter configuration"
  value       = module.bot_with_nsp.resource_id
}

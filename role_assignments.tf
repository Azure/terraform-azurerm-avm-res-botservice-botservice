locals {
  role_definition_resource_substring = "Bot Services"
  # Generate role assignment IDs
  role_assignment_ids = {
    for k, v in var.role_assignments : k => uuidv5("url", "${azapi_resource.this.id}/${v.principal_id}/${v.role_definition_id_or_name}")
  }
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = local.role_assignment_ids[each.key]
  parent_id = azapi_resource.this.id
  body = {
    properties = merge(
      {
        principalId = each.value.principal_id
      },
      strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? {
        roleDefinitionId = each.value.role_definition_id_or_name
        } : {
        roleDefinitionId = "/subscriptions/${data.azapi_client_config.this.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${each.value.role_definition_id_or_name}"
      },
      each.value.condition != null ? { condition = each.value.condition } : {},
      each.value.condition_version != null ? { conditionVersion = each.value.condition_version } : {},
      each.value.delegated_managed_identity_resource_id != null ? { delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id } : {},
      each.value.principal_type != null ? { principalType = each.value.principal_type } : {}
    )
  }
  schema_validation_enabled = false
  ignore_missing_property   = true
}

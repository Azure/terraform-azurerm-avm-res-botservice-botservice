locals {
  bot_disable_local_auth = var.local_authentication_enabled == null ? null : !var.local_authentication_enabled
  // intentionally empty; avoid locals unless necessary
  bot_public_network_access = var.public_network_access != null ? var.public_network_access : (
    var.public_network_access_enabled == null ? null : (var.public_network_access_enabled ? "Enabled" : "Disabled")
  )
  resource_group_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${var.resource_group_name}"
}


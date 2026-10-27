locals {
  bot_service_location = contains(["centralindia", "westeurope", "westus"], lower(var.location)) ? lower(var.location) : "global"
}

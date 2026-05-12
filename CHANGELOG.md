# Changelog

# v2.0.0 - Phase 1 azurerm 4.x upgrade

Changed (BREAKING)
- Raised `required_version` from `>= 1.9` to `>= 1.10`
- Raised `azurerm` provider constraint from `~> 3.116` to `~> 4.20`
- Added `azapi ~> 2.0` to `required_providers` for fleet alignment
- All 8 `examples/{Commerical,Government}/*/versions.tf` updated with
  matching constraints

Audited (no code change required)
- No `enable_https_traffic_only` / `allow_blob_public_access` /
  `enable_rbac_authorization` usage in this module.
- No `private_endpoint_network_policies_enabled` subnet attribute usage.
- No `azurerm_monitor_diagnostic_setting` resources, so no `retention_policy`
  block removals required.
- `azurerm_app_configuration` already uses `public_network_access` (string
  enum: `Enabled`/`Disabled`) — no 4.x change.
- `azurerm_role_assignment` blocks in `resources.app.configuration.role.tf`
  do NOT set `principal_type`. 4.x performs an eventual-consistency lookup
  against Microsoft Graph when this is omitted, which can intermittently fail
  for fresh principals. Deferred to a follow-up: the module's
  `existing_principal_ids` variable is `list(string)` and accepts heterogeneous
  identity types; adding a typed `principal_type` argument is a non-breaking
  enhancement and tracked separately to keep this PR scoped to the
  version bump.

Consumer-facing notes
- `azurerm` 4.x requires an explicit subscription (`ARM_SUBSCRIPTION_ID` env
  var or `subscription_id` in `provider "azurerm"`).

# v1.0.0 - <date>

Added
- Add Something you added

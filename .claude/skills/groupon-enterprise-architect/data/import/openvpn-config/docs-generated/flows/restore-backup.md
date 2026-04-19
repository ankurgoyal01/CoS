---
service: "openvpn-config"
title: "Restore Backup"
generated: "2026-03-03"
type: flow
flow_name: "restore-backup"
flow_type: batch
trigger: "Manual operator invocation of restore_backup.py after a disaster or tenant migration"
participants:
  - "openvpnRestoreBackupJob"
  - "openvpnApiClientComponent"
  - "openvpnBackupStorageAdapter"
  - "openvpnBackupData"
architecture_ref: "dynamic-openvpnBackupRestoreFlow"
---

# Restore Backup

## Summary

The restore backup flow reads the JSON snapshot files produced by [Export Backup](export-backup.md) and recreates any missing Cloud Connexa configuration entities in the target tenant. It processes entity types in dependency order: networks and routes first, then IP services, then applications, then access groups. The flow is idempotent for networks and IP services (existing entities are skipped); access groups receive appended destinations rather than full recreation if they already exist.

## Trigger

- **Type**: manual
- **Source**: InfoSec or NetOps operator running `python3 restore_backup.py`
- **Frequency**: On-demand — used after a disaster recovery event, tenant migration, or bulk configuration restore

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Restore Backup Job | Orchestrates ordered restore of all entity types | `openvpnRestoreBackupJob` |
| OpenVPN API Client | Provides rate-limit-safe HTTP wrappers and paginated reads | `openvpnApiClientComponent` |
| Backup Storage Adapter | Reads JSON backup files from `backup/` | `openvpnBackupStorageAdapter` |
| OpenVPN Backup Data | Source of JSON snapshot files | `openvpnBackupData` |
| OpenVPN Cloud Connexa API | Target for all create/update API calls | `unknown_openvpncloudconnexa_10bbc2fe` |

## Steps

1. **Acquire OAuth token**: Calls `get_oauth_token(*get_credentials(base_domain))` to obtain a Bearer token. See [OAuth Token Acquisition](oauth-token-acquisition.md).
   - From: `openvpnRestoreBackupJob`
   - To: `openvpnApiClientComponent`
   - Protocol: Python function call

2. **Read networks backup**: Opens `backup/networks.json` and calls `restore_networks(base_domain, headers, bkp_networks)`.
   - From: `openvpnBackupStorageAdapter`
   - To: `openvpnBackupData` (`backup/networks.json`)
   - Protocol: Filesystem read

3. **Restore networks**: Fetches existing networks from Cloud Connexa via `list_entities`. For each backup network not present in the live tenant, calls `POST /api/beta/networks` with connectors and up to 50 initial routes. Additional routes (if more than 50) are added via `POST /api/beta/networks/{id}/routes`. For existing networks, missing routes are appended.
   - From: `openvpnRestoreBackupJob`
   - To: Cloud Connexa `POST /api/beta/networks` and `POST /api/beta/networks/{id}/routes`
   - Protocol: HTTPS/POST JSON

4. **Build route-to-network index**: Iterates restored networks and maps each route subnet to its parent network ID. This index is used to assign parent networks to IP services during restore.
   - From: `openvpnRestoreBackupJob`
   - To: in-process dict (`route_to_network`)
   - Protocol: direct

5. **Read and restore IP services**: Opens `backup/ip_services.json`. For each missing IP service, determines its parent network using the route-to-network index (`network_for_ip_service`) and bulk-creates IP services via `POST /api/beta/ip-services/bulk?networkItemId={id}&networkItemType=NETWORK`.
   - From: `openvpnRestoreBackupJob`
   - To: Cloud Connexa `POST /api/beta/ip-services/bulk`
   - Protocol: HTTPS/POST JSON

6. **Read and restore applications**: Opens `backup/apps.json`. Currently, application restore logs a skip message to stderr for any application not already present in the live tenant (network ID remapping is pending implementation). Existing applications are returned as-is.
   - From: `openvpnBackupStorageAdapter`
   - To: `openvpnBackupData` (`backup/apps.json`)
   - Protocol: Filesystem read

7. **Restore access groups**: Opens `backup/access_groups.json`. For each access group, resolves destination resource IDs using the current networks, apps, and IP services. If the group is missing, creates it via `POST /api/beta/access-groups`. If it exists, appends destinations via `POST /api/beta/access-groups/{id}/destination` in chunks of 100 children.
   - From: `openvpnRestoreBackupJob`
   - To: Cloud Connexa `POST /api/beta/access-groups` and `POST /api/beta/access-groups/{id}/destination`
   - Protocol: HTTPS/POST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP 429 rate limit | `make_api_call` sleeps for `x-ratelimit-replenish-time` seconds and retries | Restore continues after backoff |
| HTTP 4xx/5xx on any create call | `raise_for_status()` prints diagnostic context to stderr | Script terminates; partial restore in effect |
| IP service subnet not covered by any network route | `ValueError` raised with service and subnet name | Script terminates; operator must resolve missing network routes |
| IP service spans multiple parent networks | `ValueError` raised | Script terminates; policy cannot be automatically assigned |
| Application in backup not present in live tenant | Logged to stderr as `Skipping app '<name>'` | Application is not restored; must be created manually |
| Access group destination resource not in current state | Resource silently skipped (`if child['name'] not in resources: continue`) | Access group created with reduced destination set |

## Sequence Diagram

```
Operator         -> restore_backup.py:                    python3 restore_backup.py
restore_backup   -> openvpn_api.get_oauth_token:          Obtain Bearer token
restore_backup   -> backup/networks.json:                 Read backup
restore_backup   -> CloudConnexa /api/beta/networks/page: GET existing networks
restore_backup   -> CloudConnexa /api/beta/networks:      POST missing networks (with connectors + routes)
restore_backup   -> CloudConnexa /api/beta/networks/{id}/routes: POST additional routes if >50
restore_backup   -> backup/ip_services.json:              Read backup
restore_backup   -> CloudConnexa /api/beta/ip-services/page: GET existing IP services
restore_backup   -> CloudConnexa /api/beta/ip-services/bulk: POST missing IP services
restore_backup   -> backup/apps.json:                     Read backup
restore_backup   -> CloudConnexa /api/beta/applications/page: GET existing apps
restore_backup   -> backup/access_groups.json:            Read backup
restore_backup   -> CloudConnexa /api/beta/access-groups/page: GET existing access groups
restore_backup   -> CloudConnexa /api/beta/access-groups: POST missing access groups
restore_backup   -> CloudConnexa /api/beta/access-groups/{id}/destination: POST appended destinations
```

## Related

- Architecture dynamic view: `dynamic-openvpnBackupRestoreFlow`
- Related flows: [Export Backup](export-backup.md), [OAuth Token Acquisition](oauth-token-acquisition.md)

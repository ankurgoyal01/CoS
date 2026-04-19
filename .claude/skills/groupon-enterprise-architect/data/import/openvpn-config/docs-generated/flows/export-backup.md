---
service: "openvpn-config"
title: "Export Backup"
generated: "2026-03-03"
type: flow
flow_name: "export-backup"
flow_type: batch
trigger: "Manual or scheduled operator invocation of export_backup.py"
participants:
  - "openvpnExportBackupJob"
  - "openvpnApiClientComponent"
  - "openvpnBackupStorageAdapter"
  - "openvpnBackupData"
architecture_ref: "components-openvpnConfigAutomation"
---

# Export Backup

## Summary

The export backup flow captures a complete point-in-time snapshot of all Cloud Connexa tenant configuration entities — user groups, users, applications, IP services, networks, and access groups — and serialises them as JSON files in the local `backup/` directory. It is the disaster recovery preparation step that enables the [Restore Backup](restore-backup.md) flow and the local query scripts.

## Trigger

- **Type**: manual (operator-invoked CLI)
- **Source**: InfoSec or NetOps operator running `python3 export_backup.py`
- **Frequency**: On-demand; intended to be run before significant configuration changes or on a regular schedule

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Export Backup Job | Orchestrates the export of all entity types | `openvpnExportBackupJob` |
| OpenVPN API Client | Provides paginated entity listing and rate-limit-safe HTTP requests | `openvpnApiClientComponent` |
| Backup Storage Adapter | Writes serialised JSON to `backup/*.json` files | `openvpnBackupStorageAdapter` |
| OpenVPN Backup Data | Local filesystem storage for JSON snapshot files | `openvpnBackupData` |
| OpenVPN Cloud Connexa API | Source of live entity data | `unknown_openvpncloudconnexa_10bbc2fe` |

## Steps

1. **Acquire OAuth token**: Calls `get_oauth_token(*get_credentials(base_domain))` to obtain a Bearer token. See [OAuth Token Acquisition](oauth-token-acquisition.md).
   - From: `openvpnExportBackupJob`
   - To: `openvpnApiClientComponent`
   - Protocol: Python function call

2. **Export user groups**: Calls `list_entities(base_domain, headers, 'user-groups', 'name', parameters='networkItemType=NETWORK')` to fetch all user groups scoped to NETWORK type, paginated in pages of 1000.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/user-groups/page?networkItemType=NETWORK&page={n}&size=1000`
   - Protocol: HTTPS/GET

3. **Write user groups to backup**: Calls `save_backup(user_groups, 'backup/user_groups.json')` to serialise and write the entity dictionary.
   - From: `openvpnBackupStorageAdapter`
   - To: `openvpnBackupData` (`backup/user_groups.json`)
   - Protocol: Filesystem write

4. **Export users**: Calls `list_entities` for `'users'` keyed by `'email'`, scoped to `networkItemType=NETWORK`. Writes to `backup/users.json`.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/users/page?networkItemType=NETWORK&page={n}&size=1000`
   - Protocol: HTTPS/GET

5. **Export applications**: Calls `list_entities` for `'applications'` keyed by `'name'`, scoped to `networkItemType=NETWORK`. Writes to `backup/apps.json`.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/applications/page?networkItemType=NETWORK&page={n}&size=1000`
   - Protocol: HTTPS/GET

6. **Export IP services**: Calls `list_entities` for `'ip-services'` keyed by `'name'`, scoped to `networkItemType=NETWORK`. Writes to `backup/ip_services.json`.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/ip-services/page?networkItemType=NETWORK&page={n}&size=1000`
   - Protocol: HTTPS/GET

7. **Export networks**: Calls `list_entities` for `'networks'` keyed by `'name'` (no scope filter). Writes to `backup/networks.json`.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/networks/page?page={n}&size=1000`
   - Protocol: HTTPS/GET

8. **Export access groups**: Calls `list_entities` for `'access-groups'` keyed by `'name'` (no scope filter). Writes to `backup/access_groups.json`.
   - From: `openvpnExportBackupJob`
   - To: Cloud Connexa `GET /api/beta/access-groups/page?page={n}&size=1000`
   - Protocol: HTTPS/GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP 429 rate limit on any entity list request | `make_api_call` sleeps for `x-ratelimit-replenish-time` seconds and retries | Export continues after backoff |
| HTTP 4xx/5xx on any API call | `raise_for_status()` prints diagnostic context to stderr | Script terminates; partial backup files may exist |
| `backup/` directory missing | `os.makedirs(..., exist_ok=True)` creates the directory | Directory created transparently |
| File write error | Python I/O exception propagates | Script terminates with stack trace |

## Sequence Diagram

```
Operator        -> export_backup.py:              python3 export_backup.py
export_backup   -> openvpn_api.get_oauth_token:   Obtain Bearer token
export_backup   -> openvpn_api.list_entities:     list user-groups (paginated, networkItemType=NETWORK)
list_entities   -> CloudConnexa /api/beta/user-groups/page: GET page 0..N
CloudConnexa    --> list_entities:                Entity pages
list_entities   --> export_backup:                Dict keyed by name
export_backup   -> backup/user_groups.json:       Write JSON
export_backup   -> openvpn_api.list_entities:     list users (paginated)
export_backup   -> backup/users.json:             Write JSON
export_backup   -> openvpn_api.list_entities:     list applications (paginated)
export_backup   -> backup/apps.json:              Write JSON
export_backup   -> openvpn_api.list_entities:     list ip-services (paginated)
export_backup   -> backup/ip_services.json:       Write JSON
export_backup   -> openvpn_api.list_entities:     list networks (paginated)
export_backup   -> backup/networks.json:          Write JSON
export_backup   -> openvpn_api.list_entities:     list access-groups (paginated)
export_backup   -> backup/access_groups.json:     Write JSON
```

## Related

- Architecture dynamic view: `dynamic-openvpnBackupRestoreFlow`
- Related flows: [OAuth Token Acquisition](oauth-token-acquisition.md), [Restore Backup](restore-backup.md)

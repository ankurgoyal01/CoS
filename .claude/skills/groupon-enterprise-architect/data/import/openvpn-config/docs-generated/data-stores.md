---
service: "openvpn-config"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "openvpnBackupData"
    type: "json-filesystem"
    purpose: "Point-in-time snapshots of all Cloud Connexa configuration entities for backup and disaster recovery restore"
---

# Data Stores

## Overview

OpenVPN Config Automation uses a single data store: a local filesystem directory (`backup/`) containing JSON snapshot files. These files are written by `export_backup.py` and read by `restore_backup.py` and the query scripts. There is no database, cache, or remote object store. The JSON files constitute the authoritative backup of the Cloud Connexa tenant configuration.

## Stores

### OpenVPN Backup Data (`openvpnBackupData`)

| Property | Value |
|----------|-------|
| Type | JSON Filesystem |
| Architecture ref | `openvpnBackupData` |
| Purpose | Point-in-time snapshot of all Cloud Connexa tenant configuration for backup and disaster recovery |
| Ownership | owned |
| Migrations path | N/A — schema is determined by the Cloud Connexa API response shape |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `backup/networks.json` | Snapshot of all VPN networks, connectors, and IP routes | `name`, `id`, `routes[].subnet`, `connectors[].name`, `connectors[].vpnRegionId`, `egress`, `internetAccess` |
| `backup/users.json` | Snapshot of all Cloud Connexa user accounts | `email`, `id`, user profile fields |
| `backup/user_groups.json` | Snapshot of all user groups scoped to NETWORK type | `name`, `id`, group membership |
| `backup/apps.json` | Snapshot of all Cloud Connexa applications | `name`, `id`, `routes[].domain`, `routes[].type`, `config` |
| `backup/ip_services.json` | Snapshot of all IP services with subnet routes | `name`, `id`, `routes[].subnet`, `config`, `type` |
| `backup/access_groups.json` | Snapshot of all access group policies linking sources (user groups) to destinations (apps, IP services) | `name`, `id`, `source[]`, `destination[]`, `defaultGroup` |

#### Access Patterns

- **Read**: `restore_backup.py` opens each JSON file, deserialises it, and iterates entities to compare with the live Cloud Connexa state before calling restore APIs. Query scripts (`scripts/`) read backup files locally using `jq` or `json.load`.
- **Write**: `export_backup.py` calls `save_backup()`, which creates the `backup/` directory if absent and overwrites each file with the full serialised entity dictionary returned by the Cloud Connexa API.
- **Indexes**: Not applicable — files are loaded fully into memory and iterated. Query scripts use `jq` selectors for filtering.

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

Export (`export_backup.py`) reads live state from Cloud Connexa API and writes to `backup/*.json`. Restore (`restore_backup.py`) reads `backup/*.json`, computes the diff against live Cloud Connexa state, and issues create/update API calls for missing entities. The `backup/` directory is committed to version control (`.gitignore` only excludes `__pycache__/`), meaning backup snapshots are stored in the Git repository alongside automation code.

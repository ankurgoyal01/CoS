---
service: "openvpn-config"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for OpenVPN Config (Cloud Connexa) automation.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [OAuth Token Acquisition](oauth-token-acquisition.md) | synchronous | Manual script invocation | Obtains a short-lived Bearer token from the Cloud Connexa OAuth endpoint using client credentials |
| [Export Backup](export-backup.md) | batch | Manual / scheduled operator invocation | Exports all Cloud Connexa tenant entities to local JSON backup files |
| [Restore Backup](restore-backup.md) | batch | Manual operator invocation | Restores missing Cloud Connexa entities from local JSON backup files |
| [Delete User](delete-user.md) | synchronous | Manual operator invocation | Locates a user by email and permanently deletes them from Cloud Connexa |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

All flows in this service interact exclusively with the external OpenVPN Cloud Connexa SaaS API (`unknown_openvpncloudconnexa_10bbc2fe`) over HTTPS. There are no cross-service flows involving internal Groupon services. The backup/restore flow is documented in the Structurizr dynamic view `dynamic-openvpnBackupRestoreFlow`.

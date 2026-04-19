---
service: "tronicon-ui"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Tronicon UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Campaign Card Creation](campaign-card-creation.md) | synchronous | User action — operator creates campaign group, campaign, deck, and cards | End-to-end creation of a campaign card set from campaign group through card preview |
| [Card Template Management](card-template-management.md) | synchronous | User action — operator defines or updates a card template | Define, configure, and apply reusable card templates across campaigns |
| [Geo Polygon Campaign Targeting](geo-polygon-campaign-targeting.md) | synchronous | User action — operator creates or assigns a geographic boundary | Define geographic boundaries (geo-polygons) and associate them with campaign targeting |
| [CMS Content Versioning](cms-content-versioning.md) | synchronous | User action — operator creates, edits, versions, or archives CMS content | Full lifecycle of CMS content including creation, editing, versioning, archiving, and audit trail |
| [Theme Configuration](theme-configuration.md) | synchronous | User action — operator creates or applies a UI theme | Create and configure UI themes with CSV upload support and scheduling for future activation |
| [Bootstrap Config Sync](bootstrap-config-sync.md) | synchronous | Application startup event | Load and synchronize initial application configuration from `.env`, `gconfig/cardatron.json`, and remote config services |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Campaign Card Creation** spans `troniconUiWeb`, `continuumTroniconUiDatabase`, `campaignService`, and `cardUiPreview`. See [Campaign Card Creation](campaign-card-creation.md) and `containers-troniconUi` in the central architecture model.
- **CMS Content Versioning** spans `troniconUiWeb`, `continuumTroniconUiDatabase`, and `troniconCms`. See [CMS Content Versioning](cms-content-versioning.md).
- **Bootstrap Config Sync** involves `troniconUiWeb`, `gconfigService`, and local config files. See [Bootstrap Config Sync](bootstrap-config-sync.md).

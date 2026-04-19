---
service: "authoring2"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Authoring2.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Category Edit](category-edit.md) | synchronous | User submits create or update via UI | A content author creates or modifies a category node in the taxonomy tree |
| [Bulk Taxonomy Import](bulk-taxonomy-import.md) | asynchronous | User uploads CSV/XLS data via UI | Large-scale category, attribute, or translation changes are ingested from uploaded files via the ActiveMQ queue |
| [Snapshot Creation](snapshot-creation.md) | asynchronous | User triggers snapshot creation via UI | A full taxonomy snapshot is generated asynchronously and stored as XML in PostgreSQL |
| [Snapshot Deploy to Live](snapshot-deploy-live.md) | synchronous | User certifies and activates snapshot via UI | A staged and certified snapshot is activated in the live TaxonomyV2 serving tier |
| [Partial Snapshot Creation](partial-snapshot-creation.md) | synchronous | User selects taxonomy GUIDs and triggers partial snapshot | A subset of taxonomies is packaged into a partial snapshot for targeted deployment |
| [Category Export](category-export.md) | synchronous | User requests CSV or XLS export via UI | Category data with locale translations is exported as a downloadable file |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- [Snapshot Deploy to Live](snapshot-deploy-live.md) spans `continuumAuthoring2Service` and `continuumTaxonomyService`. The activation PUT call is the integration boundary between the authoring environment and the serving tier.
- [Partial Snapshot Creation](partial-snapshot-creation.md) also calls `continuumTaxonomyService` via `pt_deploy.live.activation_ep` for partial snapshot activation.

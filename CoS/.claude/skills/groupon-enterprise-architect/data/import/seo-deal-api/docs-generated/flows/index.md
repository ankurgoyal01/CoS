---
service: "seo-deal-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for SEO Deal API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal SEO Attribute Read](deal-seo-attribute-read.md) | synchronous | API call from `seo-admin-ui` | Retrieves and returns SEO attributes for a single deal by UUID |
| [Deal SEO Attribute Update](deal-seo-attribute-update.md) | synchronous | API call from `seo-admin-ui` | Updates SEO attributes (canonical, redirect URL, noindex, brand) for a deal |
| [Automated Redirect Upload](automated-redirect-upload.md) | batch | `seo-deal-redirect` Airflow DAG (scheduled monthly, 15th) | Bulk-uploads expired-to-live deal redirect mappings via mTLS PUT requests |
| [Deal Noindex Disable](deal-noindex-disable.md) | synchronous | API call from `ingestion-jtier` during deal loading | Disables SEO indexing for a deal during the ingestion pipeline run |
| [URL Removal Workflow](url-removal-workflow.md) | synchronous | API calls from `seo-admin-ui` | Manages the lifecycle of URL removal requests: creation, approval/rejection, and status update |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Automated Redirect Upload](automated-redirect-upload.md) flow spans `seo-deal-redirect` (Airflow/Dataproc), `continuumSeoDealApiService`, and `continuumSeoDealPostgres`.
- The [Deal SEO Attribute Read](deal-seo-attribute-read.md) flow spans `seo-admin-ui`, `continuumSeoDealApiService`, `continuumDealCatalogService`, `continuumTaxonomyService`, `continuumInventoryService`, `continuumM3PlacesService`, and `continuumSeoDealPostgres`.
- The [Deal Noindex Disable](deal-noindex-disable.md) flow spans `ingestion-jtier` and `continuumSeoDealApiService`.

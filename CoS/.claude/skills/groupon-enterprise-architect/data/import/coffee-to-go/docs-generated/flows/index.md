---
service: "coffee-to-go"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Coffee To Go.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Search](deal-search.md) | synchronous | User interaction (map pan/zoom or filter change) | Sales rep searches for deals by location, filters, and text |
| [User Authentication](user-authentication.md) | synchronous | User action (sign-in button) | Groupon employee authenticates via Google OAuth |
| [Usage Event Tracking](usage-event-tracking.md) | synchronous | User interaction (automatic) | Frontend batches and submits user interaction events to the API |
| [Data Ingestion from CRM](data-ingestion-crm.md) | batch | Scheduled (n8n) | n8n workflows pull accounts and opportunities from Salesforce and competitor data from DeepScout S3 |
| [Materialized View Refresh](materialized-view-refresh.md) | batch | Triggered after data ingestion | Materialized view is refreshed to reflect newly ingested data |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Data Ingestion**: Spans n8n Workflows, Salesforce, EDW, DeepScout S3, and Coffee DB. The central architecture model tracks these relationships at the container level.
- **Authentication**: Spans Coffee Web, Coffee API, and Google OAuth. The auth flow crosses container boundaries.

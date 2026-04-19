---
service: "Deal-Estate"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Deal-Estate.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Creation and Import](deal-creation-and-import.md) | synchronous | API call — POST /deals or POST /deals/:id/import | Creates a new deal record or imports deal data from an external source, persisting to MySQL and publishing an option create event |
| [Deal Scheduling and Publication](deal-scheduling-and-publication.md) | synchronous | API call — POST /deals/:id/schedule or POST /api/v1/deals/:id/schedule | Schedules a deal for publication, validates schedulability, coordinates with Deal Catalog, and transitions deal state |
| [Deal State Sync from Catalog](deal-state-sync-from-catalog.md) | event-driven | dealCatalog.deals.v1.* events consumed from message bus | Consumes Deal Catalog events to keep local deal state aligned with catalog-side state changes (pause, unpause, publish, unpublish, distribution) |
| [Merchant Data Sync from Salesforce](merchant-data-sync-from-salesforce.md) | event-driven | salesforce.opportunity.*, account.*, planning_object.*, price.*, option.* events | Consumes Salesforce events to sync merchant account, opportunity, pricing, and option data onto deal records |
| [Deal Search and List](deal-search-and-list.md) | synchronous | API call — GET /deals or GET /deals/search | Accepts search filters, queries MySQL, optionally enriches results from cache, and returns a paginated deal list |
| [Custom Field Sync](custom-field-sync.md) | synchronous / batch | API call or background worker trigger | Reads and writes custom field values for deals via the Custom Fields Service, keeping deal metadata current |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Deal State Sync from Catalog** spans `continuumDealEstateWorker` and `continuumDealCatalogService` — see `[Deal State Sync from Catalog](deal-state-sync-from-catalog.md)`.
- **Merchant Data Sync from Salesforce** spans `continuumDealEstateWorker` and `salesForce` — see `[Merchant Data Sync from Salesforce](merchant-data-sync-from-salesforce.md)`.
- **Deal Scheduling and Publication** spans `continuumDealEstateWeb` and `continuumDealCatalogService` / `continuumDealManagementApi` — see `[Deal Scheduling and Publication](deal-scheduling-and-publication.md)`.

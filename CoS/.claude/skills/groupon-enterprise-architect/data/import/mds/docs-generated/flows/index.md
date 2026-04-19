---
service: "mds"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Marketing Deal Service (MDS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Enrichment Pipeline](deal-enrichment-pipeline.md) | asynchronous | Deal Processing Worker dequeues deal identifier from Redis | Multi-step enrichment of a deal record with taxonomy, catalog, margin, performance, and location data |
| [Deal Event Consumption](deal-event-consumption.md) | event-driven | Deal lifecycle event arrives on the message bus | Consumes deal events from MBus, enqueues for enrichment processing |
| [Feed Generation](feed-generation.md) | batch | Scheduled or API-triggered | Generates partner feeds from enriched deal data for distribution channels |
| [Inventory Status Aggregation](inventory-status-aggregation.md) | synchronous | Deal API query with inventory enrichment | Fans out to domain inventory services and merges availability into deal responses |
| [CRM Salesforce Sync](crm-salesforce-sync.md) | asynchronous | Deal enrichment pipeline triggers CRM attribute fetch | Fetches merchant/deal CRM attributes from Salesforce for deal enrichment |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The following flows involve multiple Continuum services and can be traced in the central architecture dynamic views:

- [Deal Enrichment Pipeline](deal-enrichment-pipeline.md) -- spans `continuumMarketingDealService`, `continuumDealCatalogService`, `continuumDealManagementApi`, `continuumM3PlacesService`, `continuumM3MerchantService`, `continuumBhuvanService`, `continuumPricingService`, `continuumSmaMetrics`, `salesForce`, `messageBus`
- [Deal Event Consumption](deal-event-consumption.md) -- spans `messageBus`, `continuumMarketingDealService`, `continuumDealCatalogService`
- [Inventory Status Aggregation](inventory-status-aggregation.md) -- spans `continuumMarketingDealService`, `continuumVoucherInventoryApi`, `continuumGoodsInventoryService`, `continuumThirdPartyInventoryService`, `continuumTravelInventoryService`, `continuumGLiveInventoryService`, `continuumInventoryService`
- [CRM Salesforce Sync](crm-salesforce-sync.md) -- spans `continuumMarketingDealService`, `salesForce`

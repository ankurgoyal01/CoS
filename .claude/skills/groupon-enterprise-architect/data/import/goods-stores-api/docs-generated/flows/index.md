---
service: "goods-stores-api"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Goods Stores API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Product Create/Update & Sync](product-create-update-sync.md) | synchronous + asynchronous | API request (POST/PUT /v2/products) | Creates or updates a product record and triggers post-processing, deal catalog sync, and Elasticsearch indexing |
| [Contract Lifecycle](contract-lifecycle.md) | asynchronous + scheduled | API request or scheduled job | Manages contract state transitions (create, start, end) including regional scheduling |
| [Market Data Event Processing](market-data-event-processing.md) | event-driven | JMS marketData topic message | Consumes market data change events and triggers product post-processing |
| [Elasticsearch Indexing](elasticsearch-indexing.md) | asynchronous | Worker job enqueue | Indexes or re-indexes goods records in Elasticsearch after domain changes |
| [Attachment Upload](attachment-upload.md) | synchronous | API request (POST /v2/attachments) | Uploads product images and files to S3 and persists metadata |
| [Search Query Execution](search-query-execution.md) | synchronous | API request (GET /v2/search/products or /v2/search/agreements) | Executes Elasticsearch-backed search queries for products and agreements |
| [Batch Import/Sync](batch-import-sync.md) | batch | Scheduled Resque job or manual trigger | Runs batch import/export and backfill jobs for goods data |
| [Authorization Token Validation](authorization-token-validation.md) | synchronous | Every authenticated API request | Validates GPAPI tokens and enforces role/feature-flag authorization on all requests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Product Create/Update & Sync** spans `continuumGoodsStoresApi`, `continuumGoodsStoresWorkers`, `continuumDealCatalogService`, `continuumGoodsInventoryService`, and `continuumGoodsStoresElasticsearch`. See [Product Create/Update & Sync](product-create-update-sync.md).
- **Market Data Event Processing** spans `messageBus`, `continuumGoodsStoresMessageBusConsumer`, `continuumGoodsStoresWorkers`, `continuumGoodsStoresDb`, and `continuumGoodsStoresElasticsearch`. See [Market Data Event Processing](market-data-event-processing.md).
- **Contract Lifecycle** spans `continuumGoodsStoresApi`, `continuumGoodsStoresWorkers`, `continuumDealManagementApi`, and `continuumGoodsInventoryService`. See [Contract Lifecycle](contract-lifecycle.md).
- **Batch Import/Sync** spans `continuumGoodsStoresWorkers`, `continuumDealCatalogService`, `continuumGoodsInventoryService`, and `continuumGoodsStoresS3`. See [Batch Import/Sync](batch-import-sync.md).

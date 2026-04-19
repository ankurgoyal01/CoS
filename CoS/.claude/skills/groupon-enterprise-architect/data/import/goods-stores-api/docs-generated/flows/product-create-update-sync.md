---
service: "goods-stores-api"
title: "Product Create/Update & Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "product-create-update-sync"
flow_type: asynchronous
trigger: "API request — POST or PUT /v2/products"
participants:
  - "continuumGoodsStoresApi"
  - "continuumGoodsStoresApi_v2Api"
  - "continuumGoodsStoresApi_auth"
  - "continuumGoodsStoresDb"
  - "continuumGoodsStoresRedis"
  - "continuumGoodsStoresWorkers"
  - "continuumGoodsStoresWorkers_postProcessors"
  - "continuumGoodsStoresWorkers_elasticsearchIndexer"
  - "continuumGoodsStoresWorkers_publishers"
  - "continuumDealCatalogService"
  - "continuumGoodsInventoryService"
  - "continuumGoodsStoresElasticsearch"
architecture_ref: "dynamic-goods-stores-product-create-update-sync"
---

# Product Create/Update & Sync

## Summary

This flow covers the full lifecycle of creating or updating a goods product via the v2 REST API. After the API persists the change to MySQL, it enqueues asynchronous Resque jobs that run post-processing pipelines (inventory, fulfillment, images, merchant attributes, options), sync the record to the Deal Catalog and Goods Inventory service, publish outbound product/deal events, and re-index the product in Elasticsearch.

## Trigger

- **Type**: api-call
- **Source**: GPAPI client or merchant tooling — `POST /v2/products` (create) or `PUT /v2/products/:id` (update)
- **Frequency**: On-demand per product create/update action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| V2 Goods Stores API | Receives request, validates payload, persists to DB | `continuumGoodsStoresApi_v2Api` |
| Authorization & Token Helper | Validates GPAPI token and role before processing | `continuumGoodsStoresApi_auth` |
| Goods Stores MySQL | Stores product record and audit trail | `continuumGoodsStoresDb` |
| Goods Stores Redis | Receives Resque job enqueue | `continuumGoodsStoresRedis` |
| Goods Stores Workers — Post-Processors | Runs post-processing pipeline after domain change | `continuumGoodsStoresWorkers_postProcessors` |
| Goods Stores Workers — Elasticsearch Indexer | Indexes updated product in Elasticsearch | `continuumGoodsStoresWorkers_elasticsearchIndexer` |
| Goods Stores Workers — Event Publishers | Publishes product/deal/inventory updated events | `continuumGoodsStoresWorkers_publishers` |
| Deal Catalog Service | Receives synced deal/product data | `continuumDealCatalogService` |
| Goods Inventory Service | Receives inventory state update | `continuumGoodsInventoryService` |
| Goods Stores Elasticsearch | Stores indexed product document | `continuumGoodsStoresElasticsearch` |

## Steps

1. **Receive API Request**: Client sends `POST /v2/products` or `PUT /v2/products/:id` with product payload.
   - From: `GPAPI client`
   - To: `continuumGoodsStoresApi_v2Api`
   - Protocol: REST/HTTP

2. **Validate Authorization**: Token and role are checked before processing begins.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_auth`
   - Protocol: direct (in-process)

3. **Validate and Persist Product**: Request payload is validated; product record is written to MySQL; Paper Trail creates a version audit entry.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

4. **Enqueue Post-Processing Job**: API enqueues a Resque job for the post-processing pipeline via Redis.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

5. **Return API Response**: API returns 201 Created or 200 OK with the product representation to the caller.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `GPAPI client`
   - Protocol: REST/HTTP

6. **Run Post-Processing Pipeline**: Worker dequeues job; runs PostProcessors for inventory, fulfillment, images, merchant attributes, and options; updates MySQL with derived state.
   - From: `continuumGoodsStoresWorkers_postProcessors`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

7. **Sync to Deal Catalog**: Workers call Deal Catalog service to sync deal nodes and variants for the product.
   - From: `continuumGoodsStoresWorkers`
   - To: `continuumDealCatalogService`
   - Protocol: SchemaDrivenClient/HTTP

8. **Update Inventory Service**: Workers call Goods Inventory service to publish inventory and product state updates.
   - From: `continuumGoodsStoresWorkers`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP/JSON

9. **Publish Product Events**: Event Publishers emit `products/updated` and `deals/updated` messages to notify downstream consumers.
   - From: `continuumGoodsStoresWorkers_publishers`
   - To: downstream event consumers
   - Protocol: MessageBus/JMS

10. **Index in Elasticsearch**: Elasticsearch Indexer writes the updated product document to the search index.
    - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
    - To: `continuumGoodsStoresElasticsearch`
    - Protocol: Elasticsearch client

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authorization failure | `continuumGoodsStoresApi_auth` rejects request | HTTP 401/403 returned to caller; no DB write |
| Payload validation failure | Grape validates params; returns 422 with errors array | HTTP 422 returned; no DB write |
| MySQL write failure | Exception raised; Resque job not enqueued | HTTP 500 returned; product not persisted |
| Resque enqueue failure | Redis unavailable; enqueue raises exception | API may still return 200/201 if DB write succeeded; post-processing delayed |
| Post-processor failure | Resque job fails; Resque retry policy applies | Product persisted; derived state may be stale until retry succeeds |
| Deal Catalog sync failure | Worker retries via Resque retry | Deal Catalog may have stale data until retry succeeds |
| Elasticsearch indexing failure | Indexing worker retries with logging | Search results may be stale until re-index succeeds |

## Sequence Diagram

```
GPAPI Client -> continuumGoodsStoresApi_v2Api: POST/PUT /v2/products
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_auth: Validate token and role
continuumGoodsStoresApi_auth --> continuumGoodsStoresApi_v2Api: Authorized
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresDb: Persist product (ActiveRecord)
continuumGoodsStoresDb --> continuumGoodsStoresApi_v2Api: Product saved
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresRedis: Enqueue post-processing Resque job
continuumGoodsStoresApi_v2Api --> GPAPI Client: 201/200 product response
continuumGoodsStoresWorkers_postProcessors -> continuumGoodsStoresDb: Run post-processing pipeline
continuumGoodsStoresWorkers_postProcessors -> continuumGoodsStoresWorkers_elasticsearchIndexer: Trigger re-index
continuumGoodsStoresWorkers -> continuumDealCatalogService: Sync deal nodes/variants
continuumGoodsStoresWorkers -> continuumGoodsInventoryService: Publish inventory update
continuumGoodsStoresWorkers_publishers -> messageBus: Emit products/updated, deals/updated
continuumGoodsStoresWorkers_elasticsearchIndexer -> continuumGoodsStoresElasticsearch: Index product document
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-product-create-update-sync`
- Related flows: [Elasticsearch Indexing](elasticsearch-indexing.md), [Authorization Token Validation](authorization-token-validation.md), [Contract Lifecycle](contract-lifecycle.md)

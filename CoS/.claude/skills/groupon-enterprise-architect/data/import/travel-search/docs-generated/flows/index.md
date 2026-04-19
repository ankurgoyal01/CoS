---
service: "travel-search"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Getaways Search Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotel Search Flow](hotel-search-flow.md) | synchronous | REST API call from Getaways client | End-to-end hotel search: receives search request, fans out to geo/deal/availability services, aggregates and returns results |
| [Hotel Detail Retrieval Flow](hotel-detail-retrieval.md) | synchronous | REST API call from Getaways client | Fetches, merges, and caches full hotel detail including content, availability, and rates |
| [EAN Price Update Flow](ean-price-update.md) | asynchronous | Kafka event from EAN price update stream | Consumes EAN price update messages and propagates price changes to Redis cache and MySQL |
| [MDS Hotel Update Flow](mds-hotel-update.md) | event-driven | Hotel detail change or MDS control API call | Publishes MDS hotel update events to the internal Message Bus after hotel data changes |
| [Background Inventory Sync Flow](background-inventory-sync.md) | scheduled | Periodic scheduled job | Periodically syncs hotel inventory and content from external providers; uploads OTA feeds to Google Hotels |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Hotel Search Flow** spans `continuumTravelSearchService`, `externalGetawaysClients_2f4a`, `externalGeoService_4c0d`, `externalInventoryService_5d2a`, `continuumDealCatalogService`, `externalRelevanceService_c3d4`, and `externalGapFilteringService_d4e5`. See the central architecture dynamic view `dynamic-hotelSearchFlow`.
- The **MDS Hotel Update Flow** spans `continuumTravelSearchService` and `externalMessageBus_e5f6`. MDS consumers are downstream services in the Continuum platform.
- The **EAN Price Update Flow** originates from `externalKafkaCluster_f6a7` outside this service's boundary.

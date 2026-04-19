---
service: "travel-search"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 10
internal_count: 2
---

# Integrations

## Overview

The Getaways Search Service integrates with 10 external systems and 2 internal Continuum services. External integrations span travel content providers, geo resolution, inventory management, OTA partners (Expedia EAN, Google Hotels), card-deal search, relevance ranking, locale filtering, and messaging infrastructure. Internal integrations cover deal catalog data and currency conversion. All outbound calls are made by the `travelSearch_externalClients` component using HTTP clients.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Content Service | REST | Fetches rich hotel content (descriptions, amenities, images) | yes | `externalContentService_3b91` |
| Geo Service | REST | Resolves destination identifiers and geo-based hotel lists | yes | `externalGeoService_4c0d` |
| Inventory Service | REST | Fetches availability summaries and OTA-level updates | yes | `externalInventoryService_5d2a` |
| Expedia EAN API | REST | Retrieves external hotel availability and rate data | yes | `externalExpediaEanApi_a1b2` |
| Google Hotels | REST / Feed | Uploads OTA inventory and rate feeds | no | `externalGoogleHotels_b2c3` |
| RAPI Service | REST | Searches card-based deal inventory | no | `externalRapiService_7a2c` |
| Backpack Service | REST | Queries Getaways systems search index | no | `externalBackpackService_8b3d` |
| Relevance Service | REST | Retrieves relevance-ranked deal search results | no | `externalRelevanceService_c3d4` |
| Gap-Filtering Service | REST | Applies locale-specific gap filtering to search results | no | `externalGapFilteringService_d4e5` |
| Message Bus (MBus) | JMS / MBus | Receives inbound hotel update events; publishes MDS hotel updates | yes | `externalMessageBus_e5f6` |
| Kafka Cluster | Kafka | Consumes EAN price update stream | yes | `externalKafkaCluster_f6a7` |

### Content Service Detail

- **Protocol**: REST (HTTP)
- **Base URL / SDK**: Resolved via `externalContentService_3b91` stub
- **Auth**: > No evidence found — verify in service configuration
- **Purpose**: Provides hotel content attributes (descriptions, amenities, images, etc.) to `hotelDetailsManager` during hotel detail aggregation
- **Failure mode**: Hotel detail responses return partial data; content fields may be absent
- **Circuit breaker**: > No evidence found

### Geo Service Detail

- **Protocol**: REST (HTTP)
- **Base URL / SDK**: Resolved via `externalGeoService_4c0d` stub
- **Auth**: > No evidence found — verify in service configuration
- **Purpose**: Translates destination search terms into geo identifiers and returns hotel lists scoped to a geographic area; used by `searchManager` during search flow
- **Failure mode**: Search results may be degraded or empty for destination-based queries
- **Circuit breaker**: > No evidence found

### Inventory Service Detail

- **Protocol**: REST (HTTP)
- **Base URL / SDK**: Resolved via `externalInventoryService_5d2a` stub
- **Auth**: > No evidence found — verify in service configuration
- **Purpose**: Provides availability summaries for date-range queries and OTA-level inventory updates consumed during background sync
- **Failure mode**: Availability data unavailable; hotel detail may return without availability
- **Circuit breaker**: > No evidence found

### Expedia EAN API Detail

- **Protocol**: REST (HTTP)
- **Base URL / SDK**: Resolved via `externalExpediaEanApi_a1b2` stub
- **Auth**: > No evidence found — EAN typically uses API key; verify in service configuration
- **Purpose**: Primary source of external hotel availability and rate data; results are cached in Redis and persisted to MySQL
- **Failure mode**: Rate and availability data falls back to cached or stored values
- **Circuit breaker**: > No evidence found

### Google Hotels Detail

- **Protocol**: REST / OTA feed upload
- **Base URL / SDK**: Resolved via `externalGoogleHotels_b2c3` stub
- **Auth**: > No evidence found — verify in service configuration
- **Purpose**: Outbound OTA inventory and rate feed upload executed by `travelSearch_backgroundJobs` periodically
- **Failure mode**: Feed delivery failure; retry handled by background job scheduler
- **Circuit breaker**: > No evidence found

### Message Bus (MBus) Detail

- **Protocol**: JMS / internal MBus
- **Base URL / SDK**: Resolved via `externalMessageBus_e5f6` stub
- **Auth**: Internal service credentials
- **Purpose**: Bidirectional MBus integration — inbound hotel update events trigger data refresh; outbound MDS hotel update events published by `travelSearch_mbusPublisher`
- **Failure mode**: Inbound events queued for retry; outbound publish failures may be retried or logged for manual re-trigger
- **Circuit breaker**: > No evidence found

### Kafka Cluster Detail

- **Protocol**: Kafka (Kafka Streams)
- **Base URL / SDK**: Resolved via `externalKafkaCluster_f6a7` stub
- **Auth**: Internal cluster credentials
- **Purpose**: Provides real-time EAN price update stream consumed by `travelSearch_kafkaConsumer`; updates hotel pricing in Redis and MySQL
- **Failure mode**: Consumer lag increases; prices become stale until catch-up
- **Circuit breaker**: Not applicable (Kafka consumer offset management handles recovery)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | REST | Fetches deal catalog data for search result enrichment | `continuumDealCatalogService` |
| Forex Service | REST | Retrieves currency conversion rates for multi-currency pricing | `continuumForexService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Getaways client applications | REST | Hotel search, hotel detail, availability, and recommendation requests |

> Upstream consumers are also tracked in the central architecture model (`externalGetawaysClients_2f4a`).

## Dependency Health

> No explicit health check, retry, or circuit breaker configuration is captured in the architecture model for individual external dependencies. Operational health of dependencies should be monitored via the Continuum platform observability stack. Verify retry and timeout policies in the `travelSearch_externalClients` HTTP client configuration in source code.

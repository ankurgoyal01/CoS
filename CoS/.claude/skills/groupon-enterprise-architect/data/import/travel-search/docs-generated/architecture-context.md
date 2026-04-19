---
service: "travel-search"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumTravelSearchService, continuumTravelSearchDb, continuumTravelSearchRedis]
---

# Architecture Context

## System Context

The Getaways Search Service sits within the **Continuum** platform — Groupon's legacy/modern commerce engine. It is the primary backend for the Getaways vertical's hotel search and availability use cases. Getaways client applications send search and hotel-detail requests to this service; the service fans out to a network of external travel APIs, internal platform services, and its own data stores before returning aggregated results. It also participates in async messaging: consuming EAN price updates from a Kafka cluster and publishing MDS hotel updates to the internal Message Bus.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Search Service | `continuumTravelSearchService` | Service | Java / Jetty WAR | — | Core travel search, hotel detail, availability, recommendations, and MDS update service |
| Travel Search MySQL | `continuumTravelSearchDb` | Database | MySQL | — | Primary relational store for hotel entities, configuration, and availability data |
| Travel Search Redis | `continuumTravelSearchRedis` | Cache | Redis | — | Hotel and deal data cache; backed by MySQL fallback |

## Components by Container

### Getaways Search Service (`continuumTravelSearchService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST Resources (`travelSearch_apiResources`) | Exposes HTTP endpoints for search, deals, recommendations, and MDS control; routes inbound requests to internal orchestration | JAX-RS |
| Search Orchestration (`searchManager`) | Coordinates end-to-end search flows; aggregates results from hotel details, external deal/geo lookups, and builds API responses | Java |
| Hotel Details Manager (`hotelDetailsManager`) | Fetches, merges, and caches hotel detail and availability data; reads cache then falls back to external content/inventory clients | Java |
| Cache Layer (`travelSearch_cacheLayer`) | Reads and writes hotel and deal data to Redis; falls back to persistence layer on cache miss | Redis client |
| Persistence Layer (`travelSearch_persistenceLayer`) | Reads and writes MySQL-backed hotel entities and configuration | Ebean |
| External Service Clients (`travelSearch_externalClients`) | Issues outbound HTTP calls to content, inventory, geo, deal catalog, RAPI, Backpack, Expedia EAN, Relevance, Gap-filtering, and Forex services | HTTP clients |
| Background Jobs (`travelSearch_backgroundJobs`) | Executes periodic inventory synchronisation and OTA (Google Hotels) upload tasks | Scheduled jobs |
| Kafka Consumer (`travelSearch_kafkaConsumer`) | Consumes EAN price update messages from the Kafka cluster; updates cache and persists price data | Kafka Streams |
| MBus Publisher (`travelSearch_mbusPublisher`) | Publishes MDS hotel update events to the internal Message Bus | JMS |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `externalGetawaysClients_2f4a` | `continuumTravelSearchService` | Search and hotel detail requests | REST |
| `externalMessageBus_e5f6` | `continuumTravelSearchService` | Hotel update events (MBus inbound) | JMS / MBus |
| `externalKafkaCluster_f6a7` | `continuumTravelSearchService` | EAN price update stream | Kafka |
| `continuumTravelSearchService` | `continuumTravelSearchDb` | Reads and writes hotel entities | JDBC / Ebean |
| `continuumTravelSearchService` | `continuumTravelSearchRedis` | Caches and retrieves hotel data | Redis protocol |
| `continuumTravelSearchService` | `continuumDealCatalogService` | Fetches deal catalog data | REST |
| `continuumTravelSearchService` | `continuumForexService` | Gets currency conversion rates | REST |
| `continuumTravelSearchService` | `externalContentService_3b91` | Fetches hotel content | REST |
| `continuumTravelSearchService` | `externalGeoService_4c0d` | Resolves destinations and geo hotel lists | REST |
| `continuumTravelSearchService` | `externalInventoryService_5d2a` | Fetches availability summaries and OTA updates | REST |
| `continuumTravelSearchService` | `externalRapiService_7a2c` | Searches card-based deals | REST |
| `continuumTravelSearchService` | `externalBackpackService_8b3d` | Queries Getaways systems search | REST |
| `continuumTravelSearchService` | `externalExpediaEanApi_a1b2` | Gets external hotel availability and rates | REST |
| `continuumTravelSearchService` | `externalGoogleHotels_b2c3` | Uploads OTA inventory and rate feeds | REST / Feed |
| `continuumTravelSearchService` | `externalRelevanceService_c3d4` | Gets relevance-ranked deal search results | REST |
| `continuumTravelSearchService` | `externalGapFilteringService_d4e5` | Applies locale gap filtering to results | REST |
| `continuumTravelSearchService` | `externalMessageBus_e5f6` | Publishes MDS hotel updates | JMS / MBus |
| `travelSearch_apiResources` | `searchManager` | Invokes search flows | direct |
| `searchManager` | `hotelDetailsManager` | Requests hotel details | direct |
| `searchManager` | `travelSearch_externalClients` | Fetches deals, geo, and availability | direct |
| `searchManager` | `travelSearch_persistenceLayer` | Reads stored configuration | direct |
| `hotelDetailsManager` | `travelSearch_cacheLayer` | Reads/writes cached hotel data | direct |
| `hotelDetailsManager` | `travelSearch_externalClients` | Fetches content and inventory | direct |
| `hotelDetailsManager` | `travelSearch_persistenceLayer` | Reads/writes hotel details | direct |
| `hotelDetailsManager` | `travelSearch_mbusPublisher` | Publishes MDS updates | direct |
| `travelSearch_cacheLayer` | `travelSearch_persistenceLayer` | Fallback to persistent data on cache miss | direct |
| `travelSearch_backgroundJobs` | `travelSearch_externalClients` | Syncs inventory and content periodically | direct |
| `travelSearch_backgroundJobs` | `travelSearch_persistenceLayer` | Updates stored entities after sync | direct |
| `travelSearch_kafkaConsumer` | `travelSearch_cacheLayer` | Updates cached hotel prices | direct |
| `travelSearch_kafkaConsumer` | `travelSearch_persistenceLayer` | Persists price updates | direct |

## Architecture Diagram References

- System context: `contexts-travel-search`
- Container: `containers-travel-search`
- Component: `components-travelSearchServiceComponents`
- Dynamic (hotel search flow): `dynamic-hotelSearchFlow`

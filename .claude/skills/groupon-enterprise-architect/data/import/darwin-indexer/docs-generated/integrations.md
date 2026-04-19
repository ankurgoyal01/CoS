---
service: "darwin-indexer"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 5
internal_count: 8
---

# Integrations

## Overview

darwin-indexer depends on 13 downstream systems to build enriched search documents. Eight are Continuum-internal services called via REST (Retrofit2). Two are shared infrastructure stores (Elasticsearch cluster, Redis cache). One is an external ML platform (Holmes via Kafka). One is an S3-backed feature store (Watson). One is an external catalog service (Hotel Offer Catalog). The service does not expose any inbound integration points other than its Dropwizard admin port.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Elasticsearch Cluster | Elasticsearch HTTP/transport | Destination for all indexed deal and hotel offer documents | yes | `elasticsearchCluster` |
| Kafka / Holmes Platform | Kafka | Publish `ItemIntrinsicFeatureEvent` for ML ranking pipeline | yes | `holmesPlatform`, `kafkaCluster` |
| Watson Feature Bucket | S3 | Read and write item feature vectors for ML enrichment | no | `watsonItemFeatureBucket` |
| Hotel Offer Catalog | REST | Fetch hotel offer records for indexing (stub only in current model) | yes | `hotelOfferCatalogService` |
| UGC Review Service | REST | Fetch user-generated review signals for deal enrichment (stub only in current model) | no | `ugcReviewService` |

### Elasticsearch Cluster Detail

- **Protocol**: Elasticsearch transport client or HTTP REST API
- **Base URL / SDK**: Elasticsearch 5.6.16 Java client
- **Auth**: > No evidence found — assumed internal cluster auth or none
- **Purpose**: Receives bulk-written deal and hotel offer documents; serves as the primary output of all indexing pipelines
- **Failure mode**: Indexing job fails; documents not updated; stale index served to search consumers until next successful run
- **Circuit breaker**: > No evidence found

### Kafka / Holmes Platform Detail

- **Protocol**: Kafka producer
- **Base URL / SDK**: Kafka client (version tied to Dropwizard integration)
- **Auth**: > No evidence found
- **Purpose**: Publishes `ItemIntrinsicFeatureEvent` per deal item to Holmes ML platform for ranking model consumption
- **Failure mode**: Feature events not delivered; ML models operate on stale feature data; does not block Elasticsearch indexing
- **Circuit breaker**: > No evidence found

### Watson Feature Bucket Detail

- **Protocol**: S3 SDK
- **Base URL / SDK**: AWS S3 SDK
- **Auth**: > No evidence found — assumed IAM role-based
- **Purpose**: Reads item feature vectors during deal enrichment; may write computed features back
- **Failure mode**: Feature enrichment skipped or uses defaults; deals indexed without ML feature data
- **Circuit breaker**: > No evidence found

### Hotel Offer Catalog Detail

- **Protocol**: REST
- **Base URL / SDK**: Retrofit2 HTTP client
- **Auth**: > No evidence found
- **Purpose**: Source of hotel offer records for the hotel offer indexing pipeline
- **Failure mode**: Hotel offer indexing job cannot proceed; hotel index not refreshed
- **Circuit breaker**: > No evidence found

### UGC Review Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Retrofit2 HTTP client
- **Auth**: > No evidence found
- **Purpose**: Provides user-generated review scores and counts to enrich deal documents with social proof signals
- **Failure mode**: Review signals omitted from deal documents; search documents degraded but indexing continues
- **Circuit breaker**: > No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | REST | Fetches deal records for indexing pipeline input | `continuumDealCatalogService` |
| Taxonomy Service | REST | Fetches deal and hotel offer taxonomy/category data for document enrichment | `continuumTaxonomyService` |
| Geo Service | REST | Fetches geo and location taxonomy data for deal geo-enrichment | `continuumGeoService` |
| Merchant API | REST | Fetches merchant profile and metadata for deal document enrichment | `continuumMerchantApi` |
| Inventory Service | REST | Fetches inventory availability data for deal document enrichment | `continuumInventoryService` |
| Badges Service | REST | Fetches deal badges (e.g., "Top Pick", "Editors Choice") for document enrichment | `continuumBadgesService` |
| Merchant Place Read Service | REST | Fetches merchant place/location data for deal enrichment (stub only in current model) | `merchantPlaceReadService` |
| Redis Cache | Redis | Reads sponsored campaign and feature flag data during deal enrichment | `continuumRedisCache` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. darwin-indexer does not expose an inbound HTTP API. Its outputs (Elasticsearch indexes and Kafka events) are consumed by:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Search / Ranking services | Elasticsearch query API | Query deal and hotel offer indexes for search result retrieval |
| Holmes Platform | Kafka | Consumes `ItemIntrinsicFeatureEvent` for ML model training and online inference |

## Dependency Health

- All REST upstream calls are made using Retrofit2; retry behavior and timeout configuration are managed per-client in the Dropwizard YAML configuration.
- Health of Elasticsearch and PostgreSQL connections is reported via the `/healthcheck` endpoint on port 9001.
- No circuit breaker framework (e.g., Hystrix, Resilience4j) is explicitly referenced in the inventory; failure handling is assumed to be exception-based with job-level retry or abort logic.

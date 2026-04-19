---
service: "darwin-groupon-deals"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDarwinAggregatorService]
---

# Architecture Context

## System Context

The Darwin Aggregator Service (`continuumDarwinAggregatorService`) is a container within the `continuumSystem` software system — Groupon's core commerce platform. It acts as the aggregation and personalization layer between consumer-facing deal discovery surfaces (mobile, web) and the diverse set of upstream data services that supply deal content, user context, geo context, and merchandising signals. It has no peer that owns deal search ranking; it is the authoritative aggregator for this domain.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Darwin Aggregator Service | `continuumDarwinAggregatorService` | Service | Java, Dropwizard | 2.1.12 | Aggregates and ranks deal data for relevance and personalization. Deployed as a containerized Dropwizard HTTP server. |

## Components by Container

### Darwin Aggregator Service (`continuumDarwinAggregatorService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiResource` | Exposes HTTP endpoints for deal search and aggregation; receives and validates inbound requests | Dropwizard / Jersey (JAX-RS) |
| `aggregationEngine` | Orchestrates fan-out to upstream services, applies relevance ranking using ML model artifacts, blends results | Java |
| `externalClients` | Manages HTTP client connections to all upstream services (Deal Catalog, Badges, Geo, User Identities, Citrus Ads, etc.) | OkHttp / Jersey Client |
| `cacheLayer` | Checks and populates Redis cache for deal responses; serializes payloads with Kryo | Redis / Jedis |
| `modelStore` | Reads ML model artifacts and feature data from Watson Object Storage buckets | Object Storage SDK |
| `messagingAdapter_DarGroDea` | Produces aggregated results to Kafka and consumes incoming async aggregation request events | Kafka Clients / Dropwizard-Kafka |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDarwinAggregatorService` | `continuumDealCatalogService` | Fetches deal catalog data | REST/HTTP |
| `continuumDarwinAggregatorService` | `continuumBadgesService` | Fetches badges for deals | REST/HTTP |
| `continuumDarwinAggregatorService` | `continuumUserIdentitiesService` | Resolves user identities for personalization | REST/HTTP |
| `continuumDarwinAggregatorService` | `continuumGeoPlacesService` | Looks up geo places for location-based filtering | REST/HTTP |
| `continuumDarwinAggregatorService` | `continuumGeoDetailsService` | Looks up geo details for enrichment | REST/HTTP |
| `continuumDarwinAggregatorService` | `elasticsearchClusterExt_b8f21c` | Queries deal index for full-text and filtered search | Elasticsearch HTTP |
| `continuumDarwinAggregatorService` | `redisClusterExt_9d0c11` | Caches deal responses | Redis protocol |
| `continuumDarwinAggregatorService` | `kafkaClusterExt_4b2e1f` | Publishes and consumes aggregation events | Kafka protocol |
| `continuumDarwinAggregatorService` | `watsonObjectStorageExt_3a1f2c` | Reads ML model buckets | Object Storage SDK |
| `continuumDarwinAggregatorService` | `cardatronServiceExt_bf5c13` | Fetches card and deck data | REST/HTTP |
| `continuumDarwinAggregatorService` | `alligatorDeckConfigServiceExt_8c4d21` | Loads deck configuration | REST/HTTP |
| `continuumDarwinAggregatorService` | `audienceUserAttributesServiceExt_6e01f4` | Fetches audience attributes for personalization | REST/HTTP |
| `continuumDarwinAggregatorService` | `citrusAdsServiceExt_19e7ad` | Requests sponsored ad placements | REST/HTTP |
| `continuumDarwinAggregatorService` | `targetedDealMessageServiceExt_42fd2a` | Fetches targeted deal messages | REST/HTTP |
| `continuumDarwinAggregatorService` | `recentlyViewedDealsServiceExt_2c9d0e` | Fetches recently viewed deals for user context | REST/HTTP |
| `continuumDarwinAggregatorService` | `spellCorrectionServiceExt_7a0f02` | Queries spell correction for search terms | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `darwinAggregatorServiceComponents`

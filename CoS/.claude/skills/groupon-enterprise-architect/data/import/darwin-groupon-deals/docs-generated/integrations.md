---
service: "darwin-groupon-deals"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 11
internal_count: 5
---

# Integrations

## Overview

The Darwin Aggregator Service has 16 total downstream dependencies — 5 internal Continuum services and 11 external or platform-level systems. All upstream calls are coordinated by the `externalClients` component and orchestrated by `aggregationEngine`. The service applies circuit-breaker patterns (Hystrix, accessible at `/admin/hystrix`) to isolate failures from individual dependencies and prevent cascading degradation of the aggregation pipeline.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Elasticsearch Cluster | Elasticsearch HTTP | Queries the deal index for full-text and filtered search results | yes | `elasticsearchClusterExt_b8f21c` |
| Redis Cluster | Redis protocol | Response caching for aggregated deal results | yes | `redisClusterExt_9d0c11` |
| Kafka Cluster | Kafka protocol | Async aggregation request consumption and response publishing | yes | `kafkaClusterExt_4b2e1f` |
| Watson Object Storage | Object Storage SDK | Reads ML model artifacts and feature data for ranking | yes | `watsonObjectStorageExt_3a1f2c` |
| Cardatron Service | REST/HTTP | Fetches card layout and deck data for response construction | yes | `cardatronServiceExt_bf5c13` |
| Alligator Deck Config | REST/HTTP | Loads deck configuration for deal card assembly | no | `alligatorDeckConfigServiceExt_8c4d21` |
| Audience User Attributes | REST/HTTP | Fetches audience segmentation attributes for personalization | yes | `audienceUserAttributesServiceExt_6e01f4` |
| Citrus Ads | REST/HTTP | Requests sponsored ad placements to blend into deal results | no | `citrusAdsServiceExt_19e7ad` |
| Targeted Deal Message | REST/HTTP | Fetches targeted deal messages for personalized messaging | no | `targetedDealMessageServiceExt_42fd2a` |
| Recently Viewed Deals | REST/HTTP | Fetches the user's recently viewed deals for context signals | no | `recentlyViewedDealsServiceExt_2c9d0e` |
| Spell Correction | REST/HTTP | Corrects misspelled search terms before query execution | no | `spellCorrectionServiceExt_7a0f02` |

### Elasticsearch Cluster Detail

- **Protocol**: Elasticsearch HTTP
- **Base URL / SDK**: Elasticsearch HTTP client configured at service startup
- **Auth**: Internal cluster auth (credentials via secrets)
- **Purpose**: Primary deal search index — all deal query execution routes through here
- **Failure mode**: Cache-only results returned if available; degraded search quality if Elasticsearch is unreachable
- **Circuit breaker**: Yes (Hystrix)

### Redis Cluster Detail

- **Protocol**: Redis protocol (Jedis 2.9.0)
- **Base URL / SDK**: Redis cluster endpoint configured via environment variable
- **Auth**: Internal cluster auth
- **Purpose**: Response cache — eliminates redundant upstream fan-out for repeated queries
- **Failure mode**: Cache miss; service falls through to full aggregation pipeline
- **Circuit breaker**: Yes (Hystrix)

### Kafka Cluster Detail

- **Protocol**: Kafka protocol (Kafka Clients 3.7.0 / Dropwizard-Kafka 1.8.3)
- **Base URL / SDK**: Kafka bootstrap servers configured via environment variable
- **Auth**: Internal cluster auth
- **Purpose**: Async aggregation requests consumed; aggregated responses published
- **Failure mode**: Async flow pauses; synchronous REST path unaffected
- **Circuit breaker**: No evidence found

### Watson Object Storage Detail

- **Protocol**: Object Storage SDK
- **Base URL / SDK**: Watson Object Storage SDK, bucket URL configured via environment variable
- **Auth**: IBM Cloud / Watson credentials via secrets
- **Purpose**: ML model artifacts loaded for ranking and personalization
- **Failure mode**: Service continues with stale or default model; ranking quality degrades
- **Circuit breaker**: No evidence found

### Cardatron Service Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Internal service endpoint
- **Auth**: Internal service auth
- **Purpose**: Fetches card layout and deck data for formatting aggregated deal results
- **Failure mode**: Deal cards returned without deck-specific layout data
- **Circuit breaker**: Yes (Hystrix)

### Audience User Attributes Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Internal service endpoint
- **Auth**: Internal service auth
- **Purpose**: Provides audience segmentation signals for personalized ranking
- **Failure mode**: Ranking falls back to non-personalized signals
- **Circuit breaker**: Yes (Hystrix)

### Citrus Ads Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Internal/external Citrus Ads service endpoint
- **Auth**: Internal service auth
- **Purpose**: Inserts sponsored deal placements into the ranked deal list
- **Failure mode**: Sponsored placements omitted; organic results returned
- **Circuit breaker**: Yes (Hystrix)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | REST/HTTP | Fetches deal catalog data (deal details, availability) | `continuumDealCatalogService` |
| Badges Service | REST/HTTP | Fetches deal badges (e.g., "Best Seller", "Limited Time") | `continuumBadgesService` |
| User Identities Service | REST/HTTP | Resolves user identities for personalization signals | `continuumUserIdentitiesService` |
| Geo Places Service | REST/HTTP | Looks up geo places for location-based deal filtering | `continuumGeoPlacesService` |
| Geo Details Service | REST/HTTP | Looks up detailed geo data for result enrichment | `continuumGeoDetailsService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Circuit-breaker state for all Hystrix-wrapped dependencies is available in real time at the `/admin/hystrix` endpoint (Server-Sent Events stream). This stream can be connected to a Hystrix Dashboard or Turbine aggregator for cluster-level visibility. Individual dependency health degrades gracefully — the aggregation pipeline continues with partial data wherever possible.

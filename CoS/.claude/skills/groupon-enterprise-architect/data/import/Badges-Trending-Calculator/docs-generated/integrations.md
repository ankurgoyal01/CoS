---
service: "badges-trending-calculator"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

The service has four internal Groupon dependencies: the Janus Kafka event bus (event source), Watson KV (deal metadata enrichment), Bhuvan geo-places service (division data), and RaaS/Redis (badge state store). All downstream HTTP calls use mTLS (PKCS12 keystore + truststore). No external third-party integrations exist.

## External Dependencies

> No evidence found in codebase for external (non-Groupon) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus (`janus-tier1` / `janus-cloud-tier1`) | Kafka (SSL) | Source of `DealPurchase` event stream | `janusTier1Topic` |
| Watson KV (`watson-kv`) | HTTPS | Reads item-intrinsic metadata (channel, division, merchantServiceCategory) per deal UUID | `watsonKv` |
| Bhuvan (`bhuvan`) | HTTPS | Reads supported geographic division permalinks by country | `continuumBhuvanService` |
| Redis / RaaS (`raas`) | Redis protocol | Reads/writes badge aggregates and division cache | `continuumBadgesRedisStore` |

### Janus Kafka Detail

- **Protocol**: Kafka SSL (PKCS12 keystore)
- **Topic**: `janus-tier1` (production), `janus-cloud-tier1` (staging)
- **Broker (prod)**: `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`
- **Auth**: SSL with `badges-keystore.jks` and `truststore.jks`
- **Purpose**: Primary event source for all deal purchase signals.
- **Failure mode**: If Kafka is unreachable at startup, the Spark job fails to initialize. Mid-stream disconnects trigger Kafka offset out-of-range errors; resolution requires a broker-side offset reset.
- **Circuit breaker**: No evidence found in codebase.

### Watson KV Detail

- **Protocol**: HTTPS
- **Base URL (prod)**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- **Path**: `/v1/dds/buckets/relevance-item-intrinsic/data/deals/{dealUUID}`
- **Client ID**: `badges_storm_dev_snc1` (NA), `badges_storm_prod_dub1` (EMEA)
- **Auth**: mTLS (`badges-keystore.jks` + `truststore.jks`); `Host` header set to `watson-api--dealkv.production.service`
- **Timeout**: 2000 ms connect + request
- **Max connections**: 200 total, 100 per route
- **Purpose**: Provides `channel`, `divPermalink`, and `merchantServiceCategory` used to partition badges by geographic division and deal type.
- **Failure mode**: `ClientProtocolException` logged and row skipped (division/channel remain empty strings).
- **Circuit breaker**: No evidence found in codebase.

### Bhuvan (Geo Service) Detail

- **Protocol**: HTTPS
- **Base URL (prod)**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- **Path**: `/geoplaces/v1.3/divisions`
- **Query params**: `client_id=badges`, `country={countryCode}`, `limit=1000`
- **Auth**: mTLS (`badges-keystore.jks` + `truststore.jks`); `host` header set to `bhuvan.production.service`
- **Timeout**: 2000 ms
- **Purpose**: Retrieves the full list of valid division permalinks per country so the processor can filter deals to supported geographic areas.
- **Failure mode**: `IOException` caught; empty division set returned; previously cached divisions in Redis continue to be used.
- **Circuit breaker**: No evidence found in codebase.

### Redis / RaaS Detail

- **Protocol**: Redis (TCP, plaintext inside VPC)
- **Production cluster**: `badges-cluster-new-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`
- **Mode**: cluster (production), standalone (staging)
- **Client**: Lettuce 6.0.2 (cluster mode) or Jedis (standalone mode), selected at runtime via `redisConfig.mode`
- **Pool config (prod)**: minIdle=40, maxIdle=100, maxTotal=300, commandTimeout=5000ms
- **Purpose**: Stores all badge state (intermediate counts, final rankings, division cache).
- **Failure mode**: `JedisConnectionException` caught and logged per base-key iteration; results for that partition key are skipped.
- **Circuit breaker**: Retry with 5 attempts / 50ms interval per Redis read in `calculatorTask`.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `badges-service` | Redis | Reads Trending and Top Seller ranked lists to serve deal badge data to Groupon frontends |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- Watson and Bhuvan calls use Apache HttpClient with configurable connect/request timeouts (2000ms default).
- Redis reads in `calculatorTask` use a 5-attempt retry with 50ms intervals via the `Retry` utility.
- There are no circuit breakers or bulkhead patterns implemented beyond the retry loop.

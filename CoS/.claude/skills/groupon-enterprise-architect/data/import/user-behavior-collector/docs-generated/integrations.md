---
service: "user-behavior-collector"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 7
---

# Integrations

## Overview

User Behavior Collector integrates with 7 internal Continuum/Groupon services and 3 infrastructure-level systems. All integrations are outbound; no external or internal system calls into this job. The primary integration pattern is synchronous REST via OkHttp/Retrofit, with HDFS filesystem access for Kafka event files and audience output, and Redis for deal info caching. Retry logic (via `failsafe`) is applied to audience API calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Janus Kafka Event Files (HDFS/GCS) | HDFS / GCS (Parquet) | Source of raw user behavior events | yes | `janusKafkaEventFiles_3b6f` (stub) |
| Gdoop Hadoop Cluster | HDFS | Cluster on which Spark jobs run and intermediate files are written | yes | `gdoopHadoopCluster_8d2c` (stub) |
| Telegraf / InfluxDB | InfluxDB line protocol | Receives operational metrics from the Metrics Reporter | no | `telegrafInfluxEndpoint_2a7e` (stub) |

### Janus Kafka Event Files Detail

- **Protocol**: HDFS/GCS Parquet file reads via Hadoop FileSystem API and Spark `read().parquet()`
- **Base URL / SDK**: `AppConfig.getProperty("gdoop_host")` + path `/user/kafka/source=janus-all/ds=<date>/hour=<hour>/`
- **Auth**: Hadoop cluster credentials (Kerberos / service account)
- **Purpose**: Raw user behavior events (deal views, purchases, searches, ratings, email opens) stored as Parquet by the Janus analytics pipeline; this job consumes them batch-daily
- **Failure mode**: Spark job fails; batch job sends failure email and PagerDuty alert; file pointer is not advanced; manual retry required
- **Circuit breaker**: No

### Gdoop Hadoop Cluster Detail

- **Protocol**: YARN (Spark job submission) and HDFS (file I/O)
- **Base URL / SDK**: `AppConfig.getProperty("gdoop_host")`; Spark app name `user-behavior-collector`, master `yarn`
- **Auth**: Hadoop cluster service user (`svc_emerging_channel`)
- **Purpose**: Executes the Spark job and hosts intermediate result folders under `/grp_gdoop_emerging_channels/`
- **Failure mode**: Spark job cannot be submitted; batch job fails and triggers alerts
- **Circuit breaker**: No

### Telegraf / InfluxDB Detail

- **Protocol**: InfluxDB line protocol via `InfluxDBFactory.connect(AppConfig.getProperty("telegraf.endpoint"))`
- **Base URL / SDK**: `telegraf.endpoint` config property
- **Auth**: No evidence of auth; internal endpoint
- **Purpose**: Collects HTTP response counters and custom counters tagged with `service=user-behavior-collector`, `source=ubc_gcp_spark`, `env`, and `_rollup=counter:*`
- **Failure mode**: Metrics are dropped; batch processing continues
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GAPI (api-proxy) | REST (Retrofit/OkHttp) | Fetches deal metadata: availability, options, inventory segments | `gapiService_5c1a` (stub) |
| Deal Catalog Service | REST (Retrofit/OkHttp) | Fetches deal catalog data for deal info refresh | `continuumDealCatalogService` |
| Taxonomy Service | REST | Fetches taxonomy metadata for deal categorization | `continuumTaxonomyService` |
| Wishlist Service | REST (OkHttp) | Queries `wishlists/v1/lists/query` for consumer wishlist items | `continuumWishlistService` |
| VIS (Voucher Inventory Service) | REST (Retrofit/OkHttp) | Checks voucher availability via `POST /inventory/v1/products/availability` | `visInventoryService_f4b0` (stub) |
| Audience Management Service (AMS/Cerebro) | REST (OkHttp) | Uploads audience files to Cerebro HDFS; calls `updateUserSourcedAudience` (PUT) and `updateSourcedAudienceState` (POST) | `audienceService_d1f2` (stub) |
| Token Service (push-token-service) | REST | Queries device tokens for push notification audience building | `tokenService_e9a1` (stub) |

### GAPI Detail

- **Protocol**: REST via Retrofit
- **Base URL / SDK**: `AppConfig.getProperty("gapi.clientId")`; NA endpoint `GET /v2/deals/{dealID}`, EMEA endpoint `GET /api/mobile/{country}/deals/{dealID}`
- **Auth**: `client_id` query parameter from `gapi.clientId` config
- **Purpose**: Retrieves deal availability, price summary, options, and inventory segments to build enriched `RedisDealInfo` objects
- **Failure mode**: Returns `Optional.absent()`; deal info not updated for that deal; processing continues
- **Circuit breaker**: No

### Wishlist Service Detail

- **Protocol**: REST via OkHttp
- **Base URL / SDK**: `SSLHttpClient`; endpoint `wishlists/v1/lists/query?consumerId=<uuid>&listName=default&sort=created`
- **Auth**: SSL (internal service-to-service)
- **Purpose**: Retrieves the default wishlist for each consumer who has viewed deals, to sync wishlist state into the DB
- **Failure mode**: Returns empty list; wishlist update skipped for that consumer; logged at INFO level
- **Circuit breaker**: No

### Audience Management Service Detail

- **Protocol**: REST via OkHttp (`SSLHttpClient`)
- **Base URL / SDK**: `AppConfig.getProperty("audience.aws.host")`; calls `updateUserSourcedAudience` (PUT) and `updateSourcedAudienceState` (POST)
- **Auth**: SSL (internal service-to-service)
- **Purpose**: Notifies AMS that a new audience CSV file is available on Cerebro HDFS and triggers state transition to `IMPORT`
- **Failure mode**: Retried up to 3 times with exponential backoff (initial 500s, max 3000s via `failsafe`); throws `RuntimeException` after all retries
- **Circuit breaker**: No; retry-only via `RetryUtility`

### VIS (Voucher Inventory Service) Detail

- **Protocol**: REST via Retrofit
- **Base URL / SDK**: `POST /inventory/v1/products/availability` with `clientId` and `locale` query params
- **Auth**: `clientId` from `<inventoryType>.inventory.clientId` config property
- **Purpose**: Checks whether sold-out deal options have become available again (back-in-stock detection)
- **Failure mode**: Returns `false`; deal skipped; processing continues
- **Circuit breaker**: No

## Consumed By

> Upstream consumers are tracked in the central architecture model. No services directly consume this job's output via API; downstream consumers read the audience CSV files from Cerebro HDFS after AMS ingests them.

## Dependency Health

- **Audience API**: Retried 3 times with exponential backoff (500ms initial, 3000ms max) via `failsafe`/`RetryUtility`; confirmed idempotent by Audience team
- **GAPI / VIS / Wishlist**: No retry or circuit breaker; failures result in skipped records for the affected deal or consumer
- **HDFS / Spark**: No retry; failure causes the whole batch job to fail and triggers PagerDuty alert
- **Redis**: No retry evidence; failure in deal info write would cause that deal's cache to be stale

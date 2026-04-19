---
service: "product-bundling-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

Product Bundling Service has four internal Continuum platform dependencies (Deal Catalog Service, Voucher Inventory Service, Goods Inventory Service, and Watson KV Kafka) and three external/infrastructure dependencies (Flux API for ML scoring, HDFS/Cerebro for recommendation inputs, and HDFS/Gdoop for Flux outputs). All HTTP clients are built on OkHttp + Retrofit via `jtier-retrofit`. Authentication to downstream services uses a `clientId` query parameter.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Flux API | REST/HTTP | Creates and polls recommendation scoring runs | yes | Not in federated model |
| HDFS / Cerebro | HDFS | Reads latest recommendation input files for Flux runs | yes | Not in federated model |
| HDFS / Gdoop | HDFS | Reads Flux output files for recommendation publishing | yes | Not in federated model |

### Flux API Detail

- **Protocol**: HTTP/JSON via `jtier-retrofit` (`fluxServiceClient` configuration)
- **Base URL**: Configured via `fluxServiceClient.url` in the environment config file
- **Auth**: `clientId` query parameter
- **Purpose**: PBS creates a Flux run by POSTing to the Flux API with recommendation input data. It then polls the Flux API for run status until the run completes, at which point it reads the output from HDFS.
- **Failure mode**: If Flux API is unavailable, the recommendations refresh job fails for that run. The job is retried on the next scheduled trigger.
- **Circuit breaker**: No evidence found in codebase.

### HDFS / Cerebro Detail

- **Protocol**: HDFS via `hadoop-client 2.8.1` (`hadoopInputClient` configuration)
- **Base URL**: Configured via `hadoopInputClientConfiguration` in the environment config file
- **Auth**: Kerberos / Hadoop cluster credentials (managed by `HadoopInputClientConfiguration`)
- **Purpose**: Reads the latest recommendation input CSV/file from the Cerebro data path to supply as input to the Flux scoring run.
- **Failure mode**: If the input file is missing or HDFS is unavailable, the recommendation job cannot proceed and fails for that run.
- **Circuit breaker**: No evidence found in codebase.

### HDFS / Gdoop Detail

- **Protocol**: HDFS via `hadoop-client 2.8.1` (`hadoopOutputClient` configuration)
- **Base URL**: Configured via `hadoopOutputClientConfiguration` in the environment config file
- **Auth**: Kerberos / Hadoop cluster credentials (managed by `HadoopOutputClientConfiguration`)
- **Purpose**: Reads Flux run output files containing scored recommendation payloads, then transforms and publishes them to Kafka.
- **Failure mode**: If Flux output is missing or HDFS is unavailable, the recommendation publish step is skipped for that run.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP/JSON | Reads deal and option metadata; upserts and deletes bundle nodes in Deal Catalog | `continuumDealCatalogService` |
| Voucher Inventory Service | HTTP/JSON | Fetches voucher inventory product details for warranty bundle refresh | `continuumVoucherInventoryService` |
| Goods Inventory Service | HTTP/JSON | Fetches goods inventory product details for warranty bundle refresh | `continuumGoodsInventoryService` |
| Watson KV Kafka | Kafka (publish) | Publishes recommendation payloads after recommendations refresh jobs complete | Not in federated model |

### Deal Catalog Service Detail

- **Protocol**: HTTP/JSON via Retrofit (`dealCatalogServiceClient`)
- **Base URL (staging)**: `http://deal-catalog-staging.snc1`
- **Auth**: `clientId` query parameter (`c2aff1bb06a5da39-goods_cx`)
- **Purpose**: PBS calls DCS to search deals, look up deal options, and register or remove `bundles` nodes via `PUT /deal_catalog/v3/deals/{dealUuid}/nodes/bundles` and `DELETE /deal_catalog/v3/deals/{dealUuid}/nodes/bundles`. DCS is also used to resolve bundled product creative content during bundle creation.
- **Failure mode**: If DCS is unavailable, bundle creation and deletion will still persist to PBS Postgres, but the Deal Catalog node will not be updated — causing stale data in DC responses.
- **Circuit breaker**: No evidence found in codebase; OkHttp pool bounded by `maxRequestsPerHost: 10`, `maxConcurrentRequests: 10`.

### Voucher Inventory Service Detail

- **Protocol**: HTTP/JSON via Retrofit (`voucherInventoryServiceClient`)
- **Base URL (staging)**: `http://voucher-inventory-ht-staging.snc1`
- **Auth**: `clientId` query parameter (`428ee44af73a8f06-goods-customer-experience`)
- **Purpose**: During warranty bundle refresh, PBS fetches product inventory details from VIS for eligible deal options to determine pricing and warranty eligibility.
- **Failure mode**: If VIS is unavailable, the warranty refresh job will fail for affected options.
- **Circuit breaker**: No evidence found in codebase.

### Goods Inventory Service Detail

- **Protocol**: HTTP/JSON via Retrofit (`goodsInventoryServiceClient`)
- **Base URL (staging)**: `http://goods-inventory-service-vip-staging.snc1`
- **Auth**: `clientId` query parameter (`f8b62c930507a143-goodscx`)
- **Purpose**: During warranty bundle refresh, PBS fetches product inventory details from GIS for eligible goods deal options (complementary to VIS for voucher products).
- **Failure mode**: If GIS is unavailable, the warranty refresh job will fail for affected options.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The known primary consumer is the Deal Catalog / DAG layer, which reads bundle data via the PBS REST API to include bundle information in DC responses. Internal admin tooling and operators also call the refresh endpoint directly.

## Dependency Health

- HTTP client pools are bounded via OkHttp configuration (`maxRequestsPerHost`, `maxConcurrentRequests`) to prevent connection exhaustion.
- The service exposes `/grpn/status` and a heartbeat file (`heartbeat.txt`) for health monitoring.
- PagerDuty service page: `https://groupon.pagerduty.com/services/PDONLHN`
- Wavefront dashboards monitor HTTP in/out metrics via SMA instrumentation.

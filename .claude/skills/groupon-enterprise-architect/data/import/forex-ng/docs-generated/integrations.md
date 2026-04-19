---
service: "forex-ng"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

Forex NG has two external dependencies and two internal Groupon infrastructure integrations. The critical external dependency is the NetSuite exchange-rate scriptlet API, which is the sole source of currency rate data. AWS S3 is the durable storage layer. Internally, the service ships structured logs to the Groupon logging stack and pushes metrics to the metrics stack.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| NetSuite Exchange Rates API | HTTPS/REST | Fetch daily CSV currency exchange rate exports | yes | `continuumForexNetsuiteApi` |
| AWS S3 | AWS SDK v2 (HTTPS) | Read and write forex rate JSON files and health check artifacts | yes | `continuumForexS3Bucket` |

### NetSuite Exchange Rates API Detail

- **Protocol**: HTTPS/REST (GET with query parameters)
- **Base URL**: `https://1202613.extforms.netsuite.com/`
- **Endpoint**: `/app/site/hosting/scriptlet.nl`
- **Query parameters**:
  - `StartDate` — date in `yyyyMMdd` format (set to today's date)
  - `EndDate` — date in `yyyyMMdd` format (set to today's date)
  - `BaseCurrency` — ISO 4217 currency code
  - `script=195`, `deploy=1`, `compid=1202613`, `h=590457ab4ae5f6a25951` — authentication/routing parameters
- **Auth**: Query parameter-based token (`h` parameter) — see `netsuiteRetroClient.authenticationOptions` in config
- **Response format**: CSV with header `Base Currency,Target Currency,Exchange Rate,Effective Date` — each row is one base/quote rate
- **Purpose**: Provides the authoritative source of daily foreign exchange rates for all 46 configured currencies
- **Failure mode**: If NetSuite is unreachable or returns a non-200, the affected currency is retried up to `maxRetryCount` (2) times. If all retries fail, a `DataProviderException` is thrown and the rate refresh job aborts; no stale rates are published.
- **Circuit breaker**: No dedicated circuit breaker. Retry logic via `fetchNetsuiteData` with configurable `concurrentFreq` (10 in production) and `maxRetryCount` (2).
- **Timeouts**: `connectTimeout: 10s`, `readTimeout: 20s` (from `netsuiteRetroClient.client` in config)

### AWS S3 Detail

- **Protocol**: AWS SDK v2 `S3AsyncClient`
- **Bucket**: Resolved from environment variable `FOREXS3_S3_BUCKET_NAME`
- **Region**: Resolved from environment variable `AWS_REGION` (defaults to `us-west-2`)
- **Auth**: AWS Web Identity Token File credentials (`WebIdentityTokenFileCredentialsProvider`) via `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` environment variables
- **IAM Role**: `forex-job` (as configured in `.meta/deployment/cloud/components/cron-job/production-us-west-1.yml`)
- **Purpose**: Durable object store for all currency rate JSON files; serves as the read source for the rate API
- **Failure mode**: Write and copy operations retry up to 2 times on partial failure (`MAX_RETRY = 3`). If S3 writes fail entirely, the rate refresh aborts and the live `v1/rates/` directory retains its previous contents.
- **Circuit breaker**: No circuit breaker. Per-operation retry with `MAX_RETRY = 3`.
- **Concurrency**: Up to 50 concurrent async S3 operations per batch (`AWS_CONCURRENT_OPERATIONS = 50`).

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Logging Stack (Steno + Filebeat) | Filebeat / Kafka | Structured Steno JSON log shipping | `loggingStack` |
| Metrics Stack (Telegraf + Wavefront) | HTTP (Telegraf on port 8186) | Service and Quartz job metrics | `metricsStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The service is deployed as an internal HTTP service accessible at:
- Production (snc1): `http://forex-vip.snc1`
- Production (sac1): `http://forex-vip.sac1`
- Production (dub1): `http://forex-vip.dub1`
- Staging (snc1): `http://forex-vip-staging.snc1`

## Dependency Health

- **NetSuite**: Retry-based resilience only. No health check endpoint is called proactively before rate refresh — failures surface as exceptions during the fetch. Partial currency failures are retried individually before aborting the full job.
- **AWS S3**: Health check sentinel file (`grpn/healthcheck`) is written and read back after every successful rate update to verify end-to-end S3 read/write connectivity. A `SanityFailedException` is thrown if the sentinel cannot be confirmed.
- **S3 Client lifecycle**: `AWSS3Client` is a singleton. The S3AsyncClient is lazily initialized and explicitly closed after each batch of S3 operations. A new client instance is created on the next operation if the prior client was closed.

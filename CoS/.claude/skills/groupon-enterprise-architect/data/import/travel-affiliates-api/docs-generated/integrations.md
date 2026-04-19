---
service: "travel-affiliates-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The Travel Affiliates API has three upstream affiliate partner callers (external) and two internal downstream dependencies it actively calls: Getaways API and SEO Name Service. AWS S3 is used as a storage target via the AWS SDK. The Getaways API is the critical path dependency; all availability, pricing, bundle, product-set, and hotel-detail data originates from it. The service uses Spring's `RestTemplate` (backed by Apache HttpComponents) for all outbound HTTP calls, with connection pooling and configurable timeouts.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Getaways API | REST/JSON | Availability summaries, hotel bundles, product sets, batch hotel details | yes | `continuumGetawaysApi` |
| SEO Name Service | HTTP/JSON | Resolves affiliate partner SEO identifiers to internal PartnerEnum definitions | no | `continuumSeoNameService` |
| AWS S3 | AWS SDK v2 | Stores generated hotel feed XML files in the configured feed bucket | yes | `continuumTravelAffiliatesFeedBucket` |

### Getaways API Detail

- **Protocol**: REST/JSON over HTTP
- **Base URL / SDK**: Configured via `settings.properties` / `{env}-US-settings.properties`; endpoint masks defined in `RemoteGetawaysApiClient`: `%s/inventory/availabilitySummary` and `%s/hotel/bundles/detail`
- **Auth**: `client_id` query parameter (API key); product-sets endpoint uses `Authorization` header (value from `getaways.api.content.productsets.authorization` config property)
- **Purpose**: Provides real-time hotel availability summaries, room bundle details, paginated product sets (active deals), and batch hotel metadata for all affiliate partner responses and feed generation
- **Failure mode**: Connection failures and timeouts throw `HotelAvailabilityBusyException`, which propagates to the caller as a service error. `HttpServerErrorException` from Getaways is re-thrown. Feed generation falls back to empty results per batch.
- **Circuit breaker**: No evidence found in codebase of a circuit breaker implementation.

**Configured timeouts** (from `CronConfig` / `AppConfig`):
- `getaways.api.connection.timeout.seconds` (default: 5)
- `getaways.api.socket.timeout.seconds` (default: 5)

**Connection pool** (configured in `CronConfig`):
- Max total connections: 1000
- Max connections per route: 100

**Key Getaways API operations used**:

| Operation | Path mask | Used by |
|-----------|-----------|---------|
| Availability summary | `{base}/inventory/availabilitySummary` | `HotelAvailabilityApiController`, `HotelPricingSummaryManager` |
| Hotel bundles | `{base}/hotel/bundles/detail` | `HotelBundlesSummaryManager` |
| Product sets | Configured via `getaways.api.content.productsets.*` | `ActiveDealsSummaryManager` |
| Batch hotel details | Configured via `getaways.api.content.batchhoteldetail.*` | `ActiveDealsSummaryManager` |

### SEO Name Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Resolved via `SeoResolver` component; base URL from application config
- **Auth**: No evidence found in codebase.
- **Purpose**: Maps affiliate partner SEO name path parameters (e.g., `tripadvisor`, `google`) to internal `PartnerEnum` definitions used for partner-specific business logic
- **Failure mode**: No evidence found in codebase of explicit fallback.
- **Circuit breaker**: No evidence found in codebase.

### AWS S3 Detail

- **Protocol**: AWS SDK v2 (`software.amazon.awssdk:s3` 2.20.102)
- **Base URL / SDK**: Bucket, prefix, region, and credentials loaded by `GetawaysAwsBucketConfiguration`
- **Auth**: AWS credentials from application configuration (secret path: `.meta/deployment/cloud/secrets`)
- **Purpose**: Receives generated hotel feed XML files uploaded by `AwsFileUploadService` in both the API and cron containers
- **Failure mode**: No evidence found in codebase of explicit retry or fallback.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Travel Affiliates DB | JDBC | Reads/writes operational data via JNDI GpnDataDb datasource | `continuumTravelAffiliatesDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Google Hotel Ads | HTTPS | Queries hotel availability, transaction pricing (Live Query), query control messages, and hotel list feeds |
| Skyscanner | HTTPS | Requests availability transaction data |
| TripAdvisor | HTTPS | Calls legacy hotel availability endpoint |

> Upstream consumer details are also tracked in the central architecture model: `continuumGoogleHotelAds`, `continuumSkyscanner`, `continuumTripAdvisor`.

## Dependency Health

The `gpn-heartbeat` library (version 4.0.4) provides a heartbeat mechanism at `/resources/manage/heartbeat`. The Getaways API client logs all connection failures and timeouts at ERROR level via Steno structured logging. No automated circuit breaker or retry policy is implemented in the codebase; failures are surfaced to callers as HTTP errors.

---
service: "s2s"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 8
---

# Integrations

## Overview

S2S maintains a large integration footprint: 7 external ad/SaaS platform integrations and 8 internal Groupon service dependencies. External integrations are all outbound HTTP/SDK calls to ad partner APIs, the DataBreaker SaaS platform, and Google Sheets/SMTP. Internal integrations cover consent validation, customer data enrichment, deal and pricing lookups, and order context. All HTTP clients are initialized via `continuumS2sService_retrofitClients` (Retrofit) with retry and circuit breaker policies provided by Failsafe 3.3.2.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Facebook CAPI | HTTP/SDK (Facebook Java SDK 23.0.0) | Receive web and app conversion events from Groupon | yes | `continuumFacebookCapi` |
| Google Ads / Enhanced Conversions | HTTP/SDK (Google Ads API 38.0.0) | Receive purchase and engagement conversion events | yes | `continuumGoogleAdsApi` |
| Google Appointments API | HTTP/JSON | Receive booking appointment creation events | no | `continuumGoogleAppointmentsApi` |
| TikTok Ads API | HTTP/JSON | Receive web, iOS, and Android conversion events | yes | `continuumTiktokApi` |
| Reddit Ads API | HTTP/JSON | Receive web conversion events | yes | `continuumRedditApi` |
| DataBreaker | HTTP/JSON | Booster datapoints, items ingestion, and recommendation queries | yes | `continuumDataBreakerApi` |
| Google Sheets API | HTTP/SDK | ROI report export for Google Ads automation proposals | no | — |
| SMTP | SMTP | Email notifications for booster and automation flows | no | — |

### Facebook CAPI Detail

- **Protocol**: HTTP/JSON via Facebook Java SDK 23.0.0
- **Base URL / SDK**: Facebook Java SDK — `com.facebook.business.sdk`
- **Auth**: Facebook API access token (secret)
- **Purpose**: Forward Groupon purchase and engagement conversion events to Facebook's Conversion API for ad attribution and optimization
- **Failure mode**: Events queued in `continuumS2sService_delayedEventsService` (Postgres) for replay. Advanced matching flows retried
- **Circuit breaker**: Failsafe 3.3.2 retry policies applied via Retrofit client registry

### Google Ads / Enhanced Conversions Detail

- **Protocol**: HTTP/JSON via Google Ads API 38.0.0
- **Base URL / SDK**: Google Ads Java client library
- **Auth**: Google OAuth2 service account credentials (secret)
- **Purpose**: Forward purchase conversion events to Google Ads and Enhanced Conversions for campaign attribution and ROAS optimization
- **Failure mode**: Event dropped or retried based on Failsafe policy; no explicit DLQ evidence
- **Circuit breaker**: Failsafe 3.3.2

### TikTok Ads API Detail

- **Protocol**: HTTP/JSON (Retrofit client)
- **Base URL / SDK**: TikTok marketing API base URL (configured via environment)
- **Auth**: TikTok access token (secret)
- **Purpose**: Forward web, iOS, and Android conversion events to TikTok Ads API for campaign attribution
- **Failure mode**: Events queued via `continuumS2sService_tiktokClientService` with per-platform queuing
- **Circuit breaker**: Failsafe 3.3.2

### Reddit Ads API Detail

- **Protocol**: HTTP/JSON (Retrofit client)
- **Base URL / SDK**: Reddit conversion API endpoint (configured via environment)
- **Auth**: Reddit API credentials (secret)
- **Purpose**: Forward web conversion events to Reddit Ads API for campaign attribution
- **Failure mode**: Events queued in `continuumS2sService_delayedEventsService` (Postgres) for replay via `continuumS2sService_redditClientService`
- **Circuit breaker**: Failsafe 3.3.2 with throttling in Reddit Client Service

### DataBreaker Detail

- **Protocol**: HTTP/JSON (Retrofit client)
- **Base URL / SDK**: DataBreaker SaaS API endpoint (configured via environment)
- **Auth**: DataBreaker API token obtained at runtime via token endpoint
- **Purpose**: Ingest booster datapoints and deal items; retrieve booster recommendation status per deal
- **Failure mode**: MDS-related failures stored via `continuumS2sService_mdsRetryService`; datapoint failures not explicitly retried based on available evidence
- **Circuit breaker**: Failsafe 3.3.2

### Google Sheets API Detail

- **Protocol**: HTTP/SDK (Google Sheets API)
- **Base URL / SDK**: Google Sheets Java API client
- **Auth**: Google OAuth2 service account credentials (shared with Google Ads)
- **Purpose**: Export ROI data and booster automation proposals to Google Sheets for SEM team review
- **Failure mode**: Non-critical; failures logged and reported via SMTP notification
- **Circuit breaker**: No evidence found

### SMTP Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Java SMTP client (configured via environment)
- **Auth**: SMTP credentials (secret)
- **Purpose**: Deliver automation output and booster workflow notifications to SEM/Display Engineering team
- **Failure mode**: Non-critical; notification delivery failures are logged
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Consent Service | HTTP/JSON | Validate customer consent before forwarding events to ad partners | `continuumConsentService` |
| Merchant Data Service (MDS) | HTTP/JSON | Fetch deal metadata and activation status for booster processing | `continuumMdsService` |
| Pricing API | HTTP/JSON | Retrieve deal pricing for booster payload enrichment | `continuumPricingApi` |
| Orders Service | HTTP/JSON | Retrieve order and parent order details for IV/GP calculation | `continuumOrdersService` |
| Deal Catalog Service | HTTP/JSON | Query deal catalog for booster mapping enrichment | `continuumDealCatalogService` |
| User Service | HTTP/JSON | Fetch user profile data for advanced matching enrichment | `continuumUserService` |
| Trask Service | HTTP/JSON | Send booster and tracking updates | `continuumTraskService` |
| Groupon Web/API | HTTP/JSON | Perform validation calls to Groupon public endpoints | `continuumGrouponApi` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. S2S does not expose a public API — all inbound traffic arrives via `continuumS2sKafka` (Janus Tier topics) and `continuumS2sMBus` (booster topics). HTTP endpoints at `/logs`, `/groupon`, `/update`, and `/jobs/*` are consumed by internal operators only.

## Dependency Health

- All HTTP dependencies use Retrofit clients initialized via `continuumS2sService_retrofitClients` with Failsafe 3.3.2 retry and circuit breaker policies.
- Consent Service responses are cached in-process via Cache2k 2.1.1 to reduce load during high-throughput Kafka processing.
- MDS failures are persisted to `continuumS2sPostgres` via `continuumS2sService_mdsRetryService` for scheduled retry.
- Partner API (Facebook, Reddit) failures are persisted to `continuumS2sPostgres` via `continuumS2sService_delayedEventsService` for replay.
- Teradata EDW is accessed only during scheduled batch jobs — not in the real-time event processing path.

---
service: "afl-3pgw"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

AFL-3PGW integrates with two external affiliate networks (Commission Junction and Awin) and four internal Groupon services (MBUS message bus, Orders Service, Marketing Deal Service, and Incentive Service). All outbound calls to external networks use Retrofit HTTP clients with configurable base URLs and credentials. Internal service calls also use Retrofit clients configured via YAML per environment. The service supports an adapter pattern that allows switching any integration between `http` (live) and `logging` (dry-run) modes via configuration.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Commission Junction (CJ) | REST/HTTP (S2S), GraphQL, CSV | Submit real-time sale registrations; reconcile corrections (new_sale, refund, cancelled, chargeback); fetch performance reports and commission data | yes | `cjAffiliate` |
| Awin | REST/HTTP | Submit real-time transaction events; fetch and approve network transactions; retrieve network reports | yes | `awinAffiliate` |

### Commission Junction (CJ) Detail

- **Protocol**: REST (S2S pixel tracking via GET `/u`), GraphQL (report and restatement queries), CSV file download
- **Base URL / SDK**: Configured via `cjClient`, `cjGraphQlClient`, and `cjRestatementClient` Retrofit configurations in service YAML (`Afl3pgwConfiguration`)
- **Auth**: Shared signature secret (`signature` field in `CJParams`); CID per brand and platform (android/ios/web/unknown)
- **Purpose**: Real-time registration of affiliate sales via `CJHttpClient.registerSale()`; batch correction submissions (refunds, cancellations, chargebacks, new sales); report and commission data fetch
- **Failure mode**: CJ submission failures are logged and captured in audit tables; reconciliation jobs retry on subsequent scheduled runs; Wavefront alerts fire if no events are sent for 2+ hours
- **Circuit breaker**: Failsafe (`net.jodah:failsafe`) retry policies applied via Retrofit client configuration

### Awin Detail

- **Protocol**: REST/HTTP via `AwinClient` and `AwinConversionClient` Retrofit interfaces
- **Base URL / SDK**: Configured via `awinClient` and `awinConversionClient` in service YAML (`AwinConfiguration.conversionBaseUrl`)
- **Auth**: Bearer token (`AwinConfiguration.token`) per environment
- **Purpose**: Real-time transaction submission; transaction approval and verification workflows; network report retrieval; Awin correction processing
- **Failure mode**: Awin submission failures are captured in the `awin_cancellation` table; Quartz retry jobs pick up failures on next scheduled run
- **Circuit breaker**: Failsafe retry policies; adapter pattern allows fallback to logging mode via `outputType` configuration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBUS (Message Bus) | JMS/MBUS | Consumes `jms.topic.afl_rta.attribution.orders` for real-time order attribution events | `messageBus` |
| Orders Service | REST/HTTP | Fetches order details (line items, payment, quantity) to enrich affiliate submission payloads | `continuumOrdersService` |
| Marketing Deal Service (MDS) | REST/HTTP | Fetches deal taxonomy and category metadata for payload enrichment | `continuumMarketingDealService` |
| Incentive Service | REST/HTTP | Fetches discount, gBucks, and incentive data to include in CJ commission payload | `continuumIncentiveService` |
| Mailman | REST/HTTP | Distributes Spotify offer emails on behalf of the SpotifySubmitOffersJob | (via `.service.yml` dependency: `mailman`) |

## Consumed By

> Upstream consumers are tracked in the central architecture model. AFL-3PGW does not expose a REST API for other services. It is triggered exclusively by MBUS events published by `afl-rta`.

## Dependency Health

- **MBUS**: Monitored via the `jms.topic.afl_rta.attribution.orders` topic. If no events are received for 2 hours, the `AFL-3PGW No MBUS Orders Received` Wavefront alert fires. The MBUS dashboard at `mbus-dashboard.groupondev.com` provides topic-level visibility.
- **Orders Service / MDS / Incentive Service**: Failures cause individual event processing to fail; the MBUS event is not acknowledged and expires from the topic. MDS unavailability (missing `topCategory`) is a known alert trigger — contact the MDS team for affected deal UUIDs.
- **Commission Junction**: Monitored by Wavefront alerts for 0 submissions in 2h, 12h, and 48h windows. Retry logic via Failsafe on HTTP errors.
- **Awin**: Monitored by Wavefront alerts (SpotifySubmitOffersJob, Awin transaction job alerts). Failsafe retry policies in place.
- **Mailman**: Failure of `SpotifySubmitOffersJob` triggers the `SpotifySubmitOffersJob Job Not run in last 24 hrs` alert.

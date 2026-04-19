---
service: "s2s"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for S2S — Display Advertising Server-to-Server.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Janus Consent Filter Pipeline](janus-consent-filter-pipeline.md) | event-driven | Janus Tier2/Tier3 Kafka event | Consumes raw Janus events, applies consent filtering, enriches with IV/GP, and publishes to partner-specific outbound topics |
| [Partner Event Dispatch](partner-event-dispatch.md) | event-driven | Consent-filtered Kafka event from `da_s2s_events` | Routes filtered events to Facebook CAPI, Google Ads, TikTok Ads, and Reddit Ads partner APIs |
| [MBus Booster DataBreaker Ingestion](mbus-booster-databreaker.md) | event-driven | MBus regional booster deal update topic | Ingests deal updates, enriches with MDS/pricing/deal catalog data, and sends items and datapoints to DataBreaker |
| [Teradata Customer Info Job](teradata-customer-info-job.md) | scheduled | Quartz scheduler / manual `/jobs/edw/customerInfo` trigger | Batch backfill of hashed customer PII from Teradata EDW into operational Postgres for partner event enrichment |
| [Facebook Automatization ROI](facebook-automatization-roi.md) | scheduled | Quartz scheduler / Google Ads automation job | Reads BigQuery financial tables, computes ROI metrics, exports proposals to Google Sheets, and sends email notifications |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The [Partner Event Dispatch](partner-event-dispatch.md) flow spans `continuumS2sService`, `continuumConsentService`, `continuumOrdersService`, `continuumFacebookCapi`, `continuumGoogleAdsApi`, `continuumTiktokApi`, and `continuumRedditApi`. The central architecture dynamic view is `dynamic-s2s-event-dispatch`.

The [MBus Booster DataBreaker Ingestion](mbus-booster-databreaker.md) flow spans `continuumS2sService`, `continuumS2sMBus`, `continuumMdsService`, `continuumPricingApi`, `continuumDealCatalogService`, and `continuumDataBreakerApi`.

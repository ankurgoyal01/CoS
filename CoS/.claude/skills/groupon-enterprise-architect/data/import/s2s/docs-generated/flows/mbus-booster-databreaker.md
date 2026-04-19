---
service: "s2s"
title: "MBus Booster DataBreaker Ingestion"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "mbus-booster-databreaker"
flow_type: event-driven
trigger: "Booster deal update event arrives on MBus regional topic (NA or EMEA)"
participants:
  - "continuumS2sMBus"
  - "continuumS2sService"
  - "continuumMdsService"
  - "continuumPricingApi"
  - "continuumDealCatalogService"
  - "continuumDataBreakerApi"
  - "continuumS2sPostgres"
architecture_ref: "dynamic-s2s-event-dispatch"
---

# MBus Booster DataBreaker Ingestion

## Summary

This flow handles Groupon's booster campaign lifecycle management. When a deal changes state (activation, update, deactivation), a booster deal update message is published to regional MBus topics. S2S consumes these messages, enriches them with deal metadata from MDS, pricing from Pricing API, and catalog data from Deal Catalog Service, then pushes the resulting items and events to the DataBreaker SaaS platform for booster recommendation computation. The `/update` HTTP endpoint can also trigger this flow manually for individual deals.

## Trigger

- **Type**: event (also: manual HTTP trigger via `/update`)
- **Source**: MBus regional booster topics (NA/EMEA) on `continuumS2sMBus`; manual `/update` POST request
- **Frequency**: Per deal update event (real-time MBus stream) or on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus (NA/EMEA booster topics) | Source of booster deal update messages | `continuumS2sMBus` |
| S2S Service — DataBreaker Items Processor | Orchestrates MBus consumption and DataBreaker submission | `continuumS2sService_dataBreakerItemsProcessor` |
| S2S Service — DataBreaker MBus Mapper | Enriches MBus deal updates into booster payloads | `continuumS2sService_databreakerMBusMapper` |
| S2S Service — MDS Client | Fetches deal metadata and activation state | `continuumS2sService_mdsService` |
| Merchant Data Service (MDS) | Provides deal details and activation status | `continuumMdsService` |
| S2S Service — Pricing Service | Retrieves deal pricing | `continuumS2sService_pricingService` |
| Pricing API | Provides deal pricing data | `continuumPricingApi` |
| S2S Service — Deal Catalog Service | Fetches deal catalog metadata | `continuumS2sService_dealCatalogService` |
| Deal Catalog Service | Provides deal catalog details | `continuumDealCatalogService` |
| S2S Service — MDS Retry Service | Persists failed MDS calls for retry | `continuumS2sService_mdsRetryService` |
| S2S Service — DataBreaker Send Event Service | Posts datapoints and items to DataBreaker | `continuumS2sService_dataBreakerSendEventService` |
| DataBreaker API | SaaS platform receiving booster items and events | `continuumDataBreakerApi` |
| S2S Postgres | Stores MDS retry records and booster history | `continuumS2sPostgres` |
| S2S Resource (API) | Accepts manual deal update triggers via `/update` | `continuumS2sService_apiResource` |

## Steps

1. **Receive deal update message**: DataBreaker Items Processor receives a booster deal update message from the MBus NA or EMEA regional topic. Alternatively, the `/update` HTTP endpoint routes a manual deal update to the same processor.
   - From: `continuumS2sMBus` (or `continuumS2sService_apiResource`)
   - To: `continuumS2sService_dataBreakerItemsProcessor`
   - Protocol: MBus / HTTP

2. **Map MBus message to booster payload**: DataBreaker MBus Mapper enriches the raw deal update with deal metadata (MDS), pricing (Pricing API), and catalog details (Deal Catalog Service) to produce a complete booster-friendly payload.
   - From: `continuumS2sService_dataBreakerItemsProcessor`
   - To: `continuumS2sService_databreakerMBusMapper`
   - Protocol: internal

3. **Fetch deal metadata from MDS**: MBus Mapper calls MDS Client to retrieve deal details and activation status. On MDS failure, the call is persisted to the MDS Retry Service in Postgres.
   - From: `continuumS2sService_databreakerMBusMapper`
   - To: `continuumS2sService_mdsService` → `continuumMdsService`
   - Protocol: HTTP/JSON (Retrofit + Failsafe)

4. **Fetch pricing data**: MBus Mapper calls Pricing Service to retrieve current deal pricing for booster payload enrichment.
   - From: `continuumS2sService_databreakerMBusMapper`
   - To: `continuumS2sService_pricingService` → `continuumPricingApi`
   - Protocol: HTTP/JSON

5. **Fetch deal catalog details**: MBus Mapper calls Deal Catalog Service to retrieve deal category and catalog metadata for booster mapping.
   - From: `continuumS2sService_databreakerMBusMapper`
   - To: `continuumS2sService_dealCatalogService` → `continuumDealCatalogService`
   - Protocol: HTTP/JSON

6. **Persist MDS retry on failure**: If MDS call fails, MDS Retry Service writes the retry record to Postgres for scheduled retry.
   - From: `continuumS2sService_databreakerMBusMapper`
   - To: `continuumS2sService_mdsRetryService` → `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

7. **Read MDS delta for DataBreaker payload**: DataBreaker Items Processor reads the MDS delta details from the enriched payload to prepare the final items submission.
   - From: `continuumS2sService_dataBreakerItemsProcessor`
   - To: `continuumS2sService_mdsService`
   - Protocol: internal

8. **Submit items and events to DataBreaker**: DataBreaker Send Event Service posts the enriched booster payload (items + events) to the DataBreaker SaaS API.
   - From: `continuumS2sService_dataBreakerItemsProcessor`
   - To: `continuumS2sService_dataBreakerSendEventService` → `continuumDataBreakerApi`
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MDS unavailable | MDS retry record written to `continuumS2sPostgres` via `continuumS2sService_mdsRetryService` | Booster update deferred; replayed by scheduled AES retry job or `/update` trigger |
| Pricing API unavailable | Failsafe retry; payload submitted without pricing if retry exhausted | DataBreaker receives item without current pricing enrichment |
| Deal Catalog unavailable | Failsafe retry; payload submitted with reduced metadata | DataBreaker receives item without full catalog enrichment |
| DataBreaker API unavailable | Failsafe retry via `continuumS2sService_dataBreakerSendEventService` | Submission deferred; no explicit persistent retry found — DataBreaker availability is critical |

## Sequence Diagram

```
continuumS2sMBus                            -> continuumS2sService_dataBreakerItemsProcessor : Deliver booster deal update
continuumS2sService_dataBreakerItemsProcessor -> continuumS2sService_databreakerMBusMapper  : Map to booster payload
continuumS2sService_databreakerMBusMapper     -> continuumS2sService_mdsService              : Fetch deal metadata
continuumS2sService_mdsService                -> continuumMdsService                         : HTTP GET deal details
continuumMdsService                          --> continuumS2sService_mdsService               : Deal details / error
continuumS2sService_databreakerMBusMapper     -> continuumS2sService_mdsRetryService          : Persist retry on failure
continuumS2sService_mdsRetryService           -> continuumS2sPostgres                         : JDBI write retry record
continuumS2sService_databreakerMBusMapper     -> continuumS2sService_pricingService            : Fetch pricing
continuumS2sService_pricingService            -> continuumPricingApi                          : HTTP GET price
continuumPricingApi                          --> continuumS2sService_pricingService            : Price data
continuumS2sService_databreakerMBusMapper     -> continuumS2sService_dealCatalogService        : Fetch catalog details
continuumS2sService_dealCatalogService        -> continuumDealCatalogService                  : HTTP GET catalog
continuumDealCatalogService                  --> continuumS2sService_dealCatalogService        : Catalog details
continuumS2sService_dataBreakerItemsProcessor -> continuumS2sService_dataBreakerSendEventService : Send enriched items
continuumS2sService_dataBreakerSendEventService -> continuumDataBreakerApi                    : HTTP POST items + events
continuumDataBreakerApi                      --> continuumS2sService_dataBreakerSendEventService : 200 OK / error
```

## Related

- Architecture dynamic view: `dynamic-s2s-event-dispatch`
- Related flows: [Teradata Customer Info Job](teradata-customer-info-job.md), [Partner Event Dispatch](partner-event-dispatch.md)

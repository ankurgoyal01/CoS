---
service: "lpapi"
title: "UGC Worker Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "ugc-worker-sync"
flow_type: scheduled
trigger: "Scheduled UGC synchronization cycle initiated by ugcSyncRunner"
participants:
  - "continuumLpapiApp"
  - "appUgcOrchestrator"
  - "continuumLpapiUgcWorker"
  - "ugcSyncRunner"
  - "ugcRapiFetcher"
  - "ugcServiceFetcher"
  - "ugcDataAccess"
  - "continuumRelevanceApi"
  - "continuumUgcService"
  - "continuumLpapiPrimaryPostgres"
architecture_ref: "dynamic-ugcSyncFlow"
---

# UGC Worker Sync

## Summary

The UGC Worker Sync flow enriches LPAPI landing pages with merchant review data from the UGC Service. The `continuumLpapiUgcWorker` background process coordinates the synchronization: it first fetches merchant/deal card context from the Relevance API to identify sync targets, then retrieves review payloads from the UGC Service, and finally upserts normalized review records into `continuumLpapiPrimaryPostgres`. The flow is initiated by `appUgcOrchestrator` in `continuumLpapiApp` and executed by `ugcSyncRunner` within the worker process.

## Trigger

- **Type**: schedule
- **Source**: `ugcSyncRunner` in `continuumLpapiUgcWorker`, initiated by `appUgcOrchestrator`
- **Frequency**: Periodic scheduled runs; configured per-locale and per-page set

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LPAPI App | Provides orchestration hook to initiate UGC sync | `continuumLpapiApp` |
| UGC Coordinator | Triggers the UGC Worker synchronization | `appUgcOrchestrator` |
| LPAPI UGC Worker | Background worker process that executes the sync | `continuumLpapiUgcWorker` |
| UGC Sync Runner | Coordinates sync cycles across locales and pages | `ugcSyncRunner` |
| RAPI Merchant Fetcher | Fetches merchant/deal card context to identify targets | `ugcRapiFetcher` |
| UGC Service Fetcher | Calls UGC API to retrieve merchant reviews | `ugcServiceFetcher` |
| UGC Data Access | Persists normalized review records | `ugcDataAccess` |
| Relevance API | Source of merchant card context and deal signals | `continuumRelevanceApi` |
| UGC Service | Source of merchant review payloads | `continuumUgcService` |
| LPAPI Primary Postgres | Target for normalized UGC review records | `continuumLpapiPrimaryPostgres` |

## Steps

1. **Initiates UGC sync**: `appUgcOrchestrator` triggers a new synchronization cycle in `continuumLpapiUgcWorker`
   - From: `appUgcOrchestrator`
   - To: `ugcSyncRunner`
   - Protocol: direct (in-process / worker invocation)

2. **Fetches merchant card context**: `ugcRapiFetcher` queries `continuumRelevanceApi` to obtain merchant and deal card data for each target page, identifying which merchants have UGC to sync
   - From: `ugcRapiFetcher`
   - To: `continuumRelevanceApi`
   - Protocol: HTTP

3. **Fetches merchant review payloads**: For each identified merchant target, `ugcServiceFetcher` calls `continuumUgcService` to retrieve review content
   - From: `ugcServiceFetcher`
   - To: `continuumUgcService`
   - Protocol: HTTP

4. **Normalizes review data**: `ugcSyncRunner` normalizes the raw review payloads into the LPAPI review schema
   - From: `ugcSyncRunner`
   - To: `ugcDataAccess`
   - Protocol: direct (in-process)

5. **Upserts normalized reviews**: `ugcDataAccess` persists the normalized UGC review records to `continuumLpapiPrimaryPostgres`
   - From: `ugcDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RAPI unavailable | `ugcRapiFetcher` fails to identify merchant targets | Sync cycle aborted or skipped; previously stored reviews remain |
| UGC Service unavailable | `ugcServiceFetcher` cannot retrieve review payloads | Affected merchant reviews not updated; previously stored reviews remain |
| DB write failure | `ugcDataAccess` write exception | Review upsert fails for affected records; sync continues for remaining merchants |
| Merchant has no reviews | Empty response from `continuumUgcService` | No records written; existing reviews may be cleared or left unchanged (service-level behavior) |

## Sequence Diagram

```
appUgcOrchestrator -> ugcSyncRunner: trigger UGC synchronization cycle
ugcSyncRunner -> ugcRapiFetcher: load merchant card context
ugcRapiFetcher -> continuumRelevanceApi: fetch merchant context for each target page
continuumRelevanceApi --> ugcRapiFetcher: merchant/deal card payloads
ugcSyncRunner -> ugcServiceFetcher: load merchant reviews (per merchant)
ugcServiceFetcher -> continuumUgcService: fetch review payloads
continuumUgcService --> ugcServiceFetcher: merchant review content
ugcSyncRunner -> ugcDataAccess: persist normalized reviews
ugcDataAccess -> continuumLpapiPrimaryPostgres: UPSERT UGC review records
continuumLpapiPrimaryPostgres --> ugcDataAccess: write confirmation
```

## Related

- Architecture dynamic view: `dynamic-ugcSyncFlow`
- Architecture component view: `lpapiUgcWorkerComponents`
- Related flows: [Landing Page CRUD](landing-page-crud.md)

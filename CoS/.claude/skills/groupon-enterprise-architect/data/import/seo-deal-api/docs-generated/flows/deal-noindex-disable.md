---
service: "seo-deal-api"
title: "Deal Noindex Disable"
generated: "2026-03-03"
type: flow
flow_name: "deal-noindex-disable"
flow_type: synchronous
trigger: "PUT /seodeals/deals/{dealId}/edits/noindex called by ingestion-jtier during deal loading"
participants:
  - "ingestion-jtier"
  - "continuumSeoDealApiService"
  - "seoDealApi_apiResources"
  - "orchestrator"
  - "seoDataDao"
  - "continuumSeoDealPostgres"
architecture_ref: "components-seoDealApiServiceComponents"
---

# Deal Noindex Disable

## Summary

During the deal ingestion pipeline (`ingestion-jtier`), when a new deal is being loaded into Groupon's platform, the pipeline calls SEO Deal API to disable SEO indexing for the deal. This prevents search engines from indexing a deal that is not yet fully loaded or live. The call is treated as non-critical by `ingestion-jtier` — if the SEO call fails, the ingestion pipeline logs a warning and continues without interruption. Authentication uses a `clientId` query parameter (`3pip_local_feed`).

## Trigger

- **Type**: api-call
- **Source**: `ingestion-jtier` `SEOService.disableSeoIndexing` (Retrofit interface) — called during the deal loading workflow
- **Frequency**: Per-deal, during each deal ingestion event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `ingestion-jtier` | Deal ingestion pipeline; initiates the noindex request as a side step | External consumer |
| `continuumSeoDealApiService` | Receives and processes the noindex disable request | `continuumSeoDealApiService` |
| API Resources (`seoDealApi_apiResources`) | Handles the inbound HTTP PUT request | `seoDealApi_apiResources` |
| Orchestrator (`orchestrator`) | Delegates the noindex flag write | `orchestrator` |
| SEO Data DAO (`seoDataDao`) | Persists the noindex flag to PostgreSQL | `seoDataDao` |
| SEO Deal Database | Stores the noindex flag per deal | `continuumSeoDealPostgres` |

## Steps

1. **Initiates noindex request**: `ingestion-jtier` calls `PUT /seodeals/deals/{dealId}/edits/noindex?clientId=3pip_local_feed` with body `true` via the Retrofit `SEOService` interface
   - From: `ingestion-jtier`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP (Retrofit/OkHttp)

2. **Routes to API Resources**: The Dropwizard/JAX-RS router dispatches the request to the API Resources component
   - From: `continuumSeoDealApiService`
   - To: `seoDealApi_apiResources`
   - Protocol: Direct (in-process)

3. **Delegates to Orchestrator**: API Resources delegates the noindex write to the Orchestrator
   - From: `seoDealApi_apiResources`
   - To: `orchestrator`
   - Protocol: Direct (in-process)

4. **Persists noindex flag**: SEO Data DAO writes the noindex flag (`true`) for the given deal UUID to PostgreSQL
   - From: `orchestrator` -> `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

5. **Returns response**: API Resources returns HTTP 200 on success
   - From: `continuumSeoDealApiService`
   - To: `ingestion-jtier`
   - Protocol: REST/HTTP

6. **Non-critical failure handling**: If the request fails (non-200 or network error), `ingestion-jtier` logs `failed_to_disable_seo_indexing` as a warning and continues the ingestion pipeline without blocking
   - From: `ingestion-jtier` error handler
   - To: Log output
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP non-200 response | `ingestion-jtier` logs warning `failed_to_disable_seo_indexing` and continues | Deal is ingested; noindex flag not applied; deal may be indexed by search engines prematurely |
| Network/connection error | `ingestion-jtier` catches exception, logs warning, continues | Same as above |
| Database write failure | Not specified in available evidence | HTTP 500 returned to `ingestion-jtier`; non-critical failure path taken |

## Sequence Diagram

```
ingestion-jtier -> continuumSeoDealApiService: PUT /seodeals/deals/{dealId}/edits/noindex?clientId=3pip_local_feed body: true
continuumSeoDealApiService -> seoDealApi_apiResources: Route request
seoDealApi_apiResources -> orchestrator: Delegate noindex write
orchestrator -> seoDataDao: Set noindex = true for dealId
seoDataDao -> continuumSeoDealPostgres: SQL UPDATE noindex WHERE deal_id = {dealId}
continuumSeoDealPostgres --> seoDataDao: Write confirmed
seoDataDao --> orchestrator: OK
orchestrator --> seoDealApi_apiResources: OK
seoDealApi_apiResources --> continuumSeoDealApiService: HTTP 200
continuumSeoDealApiService --> ingestion-jtier: HTTP 200 (success)
```

## Related

- Architecture dynamic view: `components-seoDealApiServiceComponents`
- Related flows: [Deal SEO Attribute Update](deal-seo-attribute-update.md)

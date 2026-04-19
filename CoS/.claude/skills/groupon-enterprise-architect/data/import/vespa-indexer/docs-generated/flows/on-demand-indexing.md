---
service: "vespa-indexer"
title: "On-Demand Deal Indexing by UUID"
generated: "2026-03-03"
type: flow
flow_name: "on-demand-indexing"
flow_type: synchronous
trigger: "POST /indexing/index-deals HTTP request with list of deal UUIDs"
participants:
  - "indexingEndpoints"
  - "indexDealsByUuidsUseCase"
  - "mdsRestAdapter"
  - "mdsRestClient"
  - "continuumMarketingDealService"
  - "bigQueryDealOptionEnricher"
  - "bigQueryClient"
  - "bigQuery"
  - "searchIndexAdapter"
  - "vespaClient"
  - "vespaCluster"
architecture_ref: "components-vespa-indexer"
---

# On-Demand Deal Indexing by UUID

## Summary

This flow allows operators or automated tooling to index a specific set of deals in Vespa without waiting for the next scheduled refresh. Given a list of up to 50 deal UUIDs, the service fetches the full deal option data from the MDS REST API, enriches it with BigQuery ML features, and writes the documents to Vespa. The HTTP response is returned immediately after the background task is enqueued; actual indexing occurs asynchronously.

## Trigger

- **Type**: api-call
- **Source**: Operator or automated tooling calling `POST /indexing/index-deals` with a JSON body containing `deal_uuids`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Indexing Endpoints | Receives the HTTP request; validates input; enqueues background task | `indexingEndpoints` |
| Index Deals By UUIDs Use Case | Orchestrates UUID-based fetch from MDS REST and Vespa write | `indexDealsByUuidsUseCase` |
| MDS REST Adapter | Fetches full deal option records by UUID from MDS REST API | `mdsRestAdapter` |
| MDS REST Client | Low-level httpx HTTP client | `mdsRestClient` |
| MDS REST API | Authoritative source of deal and option data | `continuumMarketingDealService` |
| BigQuery Deal Option Enricher | Enriches deal options with ML feature data | `bigQueryDealOptionEnricher` |
| BigQuery Client | Executes BigQuery feature queries | `bigQueryClient` |
| BigQuery | Source of ML feature tables | `bigQuery` |
| Search Index Adapter | Transforms enriched options to Vespa documents | `searchIndexAdapter` |
| Vespa Client | Writes documents to Vespa | `vespaClient` |
| Vespa Cluster | Target search index | `vespaCluster` |

## Steps

1. **Receive request**: `indexingEndpoints` receives `POST /indexing/index-deals` with body `{"deal_uuids": ["<uuid1>", ...]}`. Validates that 1–50 UUIDs are provided (enforced by Pydantic `min_items=1`, `max_items=50`).
   - From: caller (operator / tooling)
   - To: `indexingEndpoints`
   - Protocol: REST (HTTP POST)

2. **Enqueue background task**: `indexingEndpoints` adds `run_index_deals_async(use_case, deal_uuids)` to FastAPI `BackgroundTasks` and returns `{"status": "accepted", "deal_count": N}` immediately.
   - From: `indexingEndpoints`
   - To: `indexDealsByUuidsUseCase`
   - Protocol: direct (Python asyncio background task)

3. **Fetch deal options from MDS REST**: `indexDealsByUuidsUseCase.execute(deal_uuids)` calls `mdsRestAdapter.get_deals_by_uuids(deal_uuids)`, which issues `GET /deals?client=vespa-indexer&uuids=<uuids>` via `mdsRestClient` (httpx). Timeout 30 s; up to 3 retries.
   - From: `mdsRestAdapter` → `mdsRestClient`
   - To: `continuumMarketingDealService`
   - Protocol: REST (HTTPS)

4. **Enrich with ML features**: `mdsRestAdapter` calls `bigQueryDealOptionEnricher.enrich()` on the returned options. Queries deal feature table, option feature table, and distance bucket table in batches.
   - From: `bigQueryDealOptionEnricher`
   - To: `bigQueryClient` → `bigQuery`
   - Protocol: BigQuery SDK

5. **Transform and write to Vespa**: `indexDealsByUuidsUseCase` calls `searchIndexAdapter.index_option()` for each enriched option. `searchIndexAdapter` applies transformations and calls `vespaClient.feed_document()`.
   - From: `searchIndexAdapter`
   - To: `vespaClient` → `vespaCluster`
   - Protocol: HTTP (pyvespa)

6. **Log completion**: Successful completion or exceptions are logged by `run_index_deals_async`; no response is sent back to the original caller (the request already returned at step 2).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request (0 or more than 50 UUIDs) | Pydantic validation raises HTTP 422 before task is enqueued | Request rejected; no indexing started |
| MDS REST fetch fails after retries | Exception logged in background task | Affected deals not indexed; caller must re-submit |
| BigQuery enrichment fails | Exception logged; indexing proceeds without ML features | Documents indexed with empty feature fields |
| Vespa write fails | Exception logged | Affected options not indexed; caller must re-submit |
| Use case not initialised in app state | HTTP 500 returned synchronously | Indexing not started |

## Sequence Diagram

```
caller -> indexingEndpoints: POST /indexing/index-deals {"deal_uuids": [...]}
indexingEndpoints -> indexingEndpoints: validate (1-50 UUIDs)
indexingEndpoints --> caller: {"status": "accepted", "deal_count": N}
indexingEndpoints -> indexDealsByUuidsUseCase: execute(deal_uuids) [background task]
indexDealsByUuidsUseCase -> mdsRestAdapter: get_deals_by_uuids(deal_uuids)
mdsRestAdapter -> mdsRestClient: GET /deals?client=vespa-indexer&uuids=...
mdsRestClient -> continuumMarketingDealService: HTTP GET
continuumMarketingDealService --> mdsRestClient: deal option records (JSON)
mdsRestClient --> mdsRestAdapter: parsed DealOption list
mdsRestAdapter -> bigQueryDealOptionEnricher: enrich(options)
bigQueryDealOptionEnricher -> bigQueryClient: query feature tables
bigQueryClient -> bigQuery: SQL queries
bigQuery --> bigQueryClient: feature rows
bigQueryDealOptionEnricher --> mdsRestAdapter: enriched options
mdsRestAdapter --> indexDealsByUuidsUseCase: enriched DealOption list
indexDealsByUuidsUseCase -> searchIndexAdapter: index_option(option)
searchIndexAdapter -> vespaClient: feed_document(doc)
vespaClient -> vespaCluster: HTTP PUT
vespaCluster --> vespaClient: 200 OK
```

## Related

- Related flows: [Scheduled Deal Refresh from Feed](scheduled-deal-refresh.md), [Real-Time Deal Update Indexing](real-time-deal-update.md)
- [API Surface](../api-surface.md) — `POST /indexing/index-deals` endpoint details

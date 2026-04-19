---
service: "vespa-indexer"
title: "Scheduled Deal Refresh from Feed"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-deal-refresh"
flow_type: scheduled
trigger: "Kubernetes CronJob cronjob-deal-refresh; daily at 10:00 UTC"
participants:
  - "continuumVespaIndexerCronJobs"
  - "schedulerEndpoints"
  - "refreshFromFeedUseCase"
  - "dealFeedAdapter"
  - "gcsClient"
  - "mdsRestAdapter"
  - "mdsRestClient"
  - "continuumMarketingDealService"
  - "bigQueryDealOptionEnricher"
  - "bigQueryClient"
  - "searchIndexAdapter"
  - "vespaClient"
  - "vespaCluster"
architecture_ref: "dynamic-vespa-indexer-refresh-from-feed"
---

# Scheduled Deal Refresh from Feed

## Summary

This flow performs a full daily refresh of all deal options in the Vespa index. It is designed to handle the bulk synchronisation case — ensuring that every deal option known to the Groupon platform is represented in Vespa with up-to-date data and ML features. The flow is initiated by a Kubernetes CronJob that posts to the service's scheduler endpoint; the actual work runs asynchronously in a background task within the service.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob `vespa-indexer-deal-refresh` (`cronjob-deal-refresh` component)
- **Frequency**: Daily at 10:00 UTC (`0 10 * * *`; 10 AM chosen because MDS feed export runs at 8 AM)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vespa Indexer CronJobs | Initiates the flow by calling the scheduler endpoint | `continuumVespaIndexerCronJobs` |
| Scheduler Endpoints | Receives the `POST /scheduler/refresh-deals` request and enqueues background task | `schedulerEndpoints` |
| Refresh From Feed Use Case | Orchestrates the full refresh: streams UUIDs, fetches data, enriches, indexes | `refreshFromFeedUseCase` |
| Deal Feed Adapter | Streams deal UUIDs from GCS feed file | `dealFeedAdapter` |
| GCS Client | Downloads gzipped MDS feed blob from GCS in 8 MB chunks | `gcsClient` |
| MDS REST Adapter | Fetches full deal option records from MDS REST API by UUID batches | `mdsRestAdapter` |
| MDS REST Client | Low-level httpx HTTP client for MDS REST API | `mdsRestClient` |
| MDS REST API | Authoritative source of deal and option data | `continuumMarketingDealService` |
| BigQuery Deal Option Enricher | Enriches deal options with ML features from BigQuery | `bigQueryDealOptionEnricher` |
| BigQuery Client | Executes BigQuery feature table queries | `bigQueryClient` |
| Search Index Adapter | Transforms enriched options to Vespa document format | `searchIndexAdapter` |
| Vespa Client | Writes documents to Vespa via pyvespa HTTP API | `vespaClient` |
| Vespa Cluster | Target search index | `vespaCluster` |

## Steps

1. **CronJob fires**: Kubernetes CronJob runs an Alpine container that executes `curl -X POST ${VESPA_SERVICE_URL}/scheduler/refresh-deals`.
   - From: `continuumVespaIndexerCronJobs`
   - To: `schedulerEndpoints`
   - Protocol: HTTP POST

2. **Enqueue background task**: `schedulerEndpoints` accepts the request, wraps `RefreshFromFeed.execute()` in a `SchedulerJobMetricsTracker`, and adds it to FastAPI `BackgroundTasks`. Returns `202`-style `{"status": "accepted"}` immediately.
   - From: `schedulerEndpoints`
   - To: `refreshFromFeedUseCase`
   - Protocol: direct (Python asyncio background task)

3. **Stream deal UUIDs from GCS**: `refreshFromFeedUseCase` calls `dealFeedAdapter.get_deal_uuids_stream()`, which uses `gcsClient.download_blob_async_stream()` to download the gzipped MDS feed (`mds_feeds/vespa_ai_US.gz`) in 8 MB chunks. The adapter parses the gzip stream line-by-line (each line is a JSON object) and yields only the `deal_uuid` field — lightweight and memory-efficient.
   - From: `dealFeedAdapter`
   - To: `gcsClient` → `cloudPlatform` (GCS)
   - Protocol: GCS SDK

4. **Batch UUIDs**: `refreshFromFeedUseCase` accumulates yielded UUIDs into batches of `REFRESH_BATCH_SIZE` (default 50, matching `MDS_MAX_UUIDS_PER_REQUEST`).
   - From: `refreshFromFeedUseCase`
   - To: internal accumulator
   - Protocol: direct

5. **Fetch deal options from MDS REST**: For each batch, `refreshFromFeedUseCase` calls `mdsRestAdapter.get_deals_by_uuids(batch)`, which issues `GET /deals?client=vespa-indexer&uuids=<uuids>` against the MDS REST API via `mdsRestClient` (httpx). Timeout: `MDS_REST_TIMEOUT_SECONDS` (30 s); retries: `MDS_REST_MAX_RETRIES` (3).
   - From: `mdsRestAdapter` → `mdsRestClient`
   - To: `continuumMarketingDealService`
   - Protocol: REST (HTTPS)

6. **Enrich with ML features**: For each batch of returned `DealOption` objects, `mdsRestAdapter` calls `bigQueryDealOptionEnricher.enrich()`, which queries deal feature table, option feature table, and distance bucket table from BigQuery in batches of `FEATURE_BATCH_SIZE` (default 500) with up to `FEATURE_REFRESH_MAX_WORKERS` (default 10) concurrent tasks.
   - From: `bigQueryDealOptionEnricher`
   - To: `bigQueryClient` → `bigQuery`
   - Protocol: BigQuery SDK

7. **Transform and index to Vespa**: `refreshFromFeedUseCase` calls `searchIndexAdapter.index_option()` for each enriched option. `searchIndexAdapter` applies transformations (unicode cleaning, type coercion, computed fields) and calls `vespaClient.feed_document()`.
   - From: `searchIndexAdapter`
   - To: `vespaClient` → `vespaCluster`
   - Protocol: HTTP (pyvespa)

8. **Job completes**: `SchedulerJobMetricsTracker` records job duration and success/failure status as Prometheus metrics.
   - From: `schedulerEndpoints` wrapper
   - To: Prometheus metrics store
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS feed file missing or download fails | Exception logged; job aborts | No deals refreshed for this run; stale index until next CronJob |
| MDS REST batch request fails after retries | Exception logged; batch skipped; remaining batches continue | Partial refresh; affected deals remain at previous version |
| BigQuery feature query fails for a batch | Exception logged; options indexed without ML features | Features temporarily absent for affected options |
| Vespa write fails for a document | Exception logged; remaining documents continue | Single document may be stale; re-indexed on next run |
| CronJob container fails (HTTP non-200) | CronJob retries up to `backoffLimit` (2) | If all retries fail, alert generated; re-trigger manually |

## Sequence Diagram

```
continuumVespaIndexerCronJobs -> schedulerEndpoints: POST /scheduler/refresh-deals
schedulerEndpoints --> continuumVespaIndexerCronJobs: {"status": "accepted"}
schedulerEndpoints -> refreshFromFeedUseCase: execute() [background task]
refreshFromFeedUseCase -> dealFeedAdapter: get_deal_uuids_stream()
dealFeedAdapter -> gcsClient: download_blob_async_stream(mds_feeds/vespa_ai_US.gz, chunk=8MB)
gcsClient --> dealFeedAdapter: gzip stream chunks
dealFeedAdapter --> refreshFromFeedUseCase: AsyncIterator[deal_uuid]
loop for each batch of 50 UUIDs
  refreshFromFeedUseCase -> mdsRestAdapter: get_deals_by_uuids(batch)
  mdsRestAdapter -> mdsRestClient: GET /deals?client=vespa-indexer&uuids=...
  mdsRestClient -> continuumMarketingDealService: HTTP GET
  continuumMarketingDealService --> mdsRestClient: deal option records (JSON)
  mdsRestClient --> mdsRestAdapter: parsed DealOption list
  mdsRestAdapter -> bigQueryDealOptionEnricher: enrich(options)
  bigQueryDealOptionEnricher -> bigQueryClient: query feature tables
  bigQueryClient --> bigQueryDealOptionEnricher: feature rows
  bigQueryDealOptionEnricher --> mdsRestAdapter: enriched options
  mdsRestAdapter --> refreshFromFeedUseCase: enriched DealOption list
  refreshFromFeedUseCase -> searchIndexAdapter: index_option(option)
  searchIndexAdapter -> vespaClient: feed_document(doc)
  vespaClient -> vespaCluster: HTTP PUT
  vespaCluster --> vespaClient: 200 OK
end
```

## Related

- Architecture dynamic view: `dynamic-vespa-indexer-refresh-from-feed`
- Related flows: [Real-Time Deal Update Indexing](real-time-deal-update.md), [Scheduled ML Feature Refresh](scheduled-feature-refresh.md)

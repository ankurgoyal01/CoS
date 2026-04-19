---
service: "vespa-indexer"
title: "Scheduled ML Feature Refresh"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-feature-refresh"
flow_type: scheduled
trigger: "Kubernetes CronJob cronjob-feature-refresh; three times daily at 04:00, 16:00, 22:00 UTC"
participants:
  - "continuumVespaIndexerCronJobs"
  - "schedulerEndpoints"
  - "refreshFeaturesUseCase"
  - "featureProviderAdapter"
  - "bigQueryClient"
  - "bigQuery"
  - "searchIndexAdapter"
  - "vespaClient"
  - "vespaCluster"
architecture_ref: "dynamic-vespa-indexer-refresh-from-feed"
---

# Scheduled ML Feature Refresh

## Summary

This flow refreshes ML ranking features on existing Vespa documents without performing a full deal data reload. It is a lightweight, high-frequency complement to the daily deal refresh: three times per day it queries BigQuery feature tables and issues partial updates to Vespa, ensuring that COEC signals and distance bucket priors used for ranking remain fresh. Features are also refreshed as part of the daily deal refresh, so in total ML features are updated four times per day.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob `vespa-indexer-feature-refresh` (`cronjob-feature-refresh` component)
- **Frequency**: Three times daily at 04:00, 16:00, 22:00 UTC (`0 4,16,22 * * *`); a fourth feature refresh occurs implicitly via the deal refresh at 10:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vespa Indexer CronJobs | Initiates the flow by calling the scheduler endpoint | `continuumVespaIndexerCronJobs` |
| Scheduler Endpoints | Receives `POST /scheduler/refresh-features` and enqueues background task | `schedulerEndpoints` |
| Refresh Features Use Case | Orchestrates feature streaming and Vespa partial updates | `refreshFeaturesUseCase` |
| Feature Provider Adapter | Implements `FeatureProvider` by querying BigQuery feature tables | `featureProviderAdapter` |
| BigQuery Client | Executes BigQuery queries for each feature entity type | `bigQueryClient` |
| BigQuery | Source of ML feature tables | `bigQuery` |
| Search Index Adapter | Issues partial Vespa document updates with feature field values | `searchIndexAdapter` |
| Vespa Client | Low-level pyvespa HTTP client for partial updates | `vespaClient` |
| Vespa Cluster | Target search index | `vespaCluster` |

## Steps

1. **CronJob fires**: Kubernetes CronJob runs an Alpine container that executes `curl -X POST ${VESPA_SERVICE_URL}/scheduler/refresh-features`.
   - From: `continuumVespaIndexerCronJobs`
   - To: `schedulerEndpoints`
   - Protocol: HTTP POST

2. **Enqueue background task**: `schedulerEndpoints` wraps `RefreshFeaturesUseCase.execute()` in a `SchedulerJobMetricsTracker` and adds it to FastAPI `BackgroundTasks`. Returns `{"status": "accepted"}` immediately.
   - From: `schedulerEndpoints`
   - To: `refreshFeaturesUseCase`
   - Protocol: direct (Python asyncio background task)

3. **Query BigQuery deal features**: `refreshFeaturesUseCase` calls `featureProviderAdapter.stream_features()` for deal-level features. `featureProviderAdapter` uses `bigQueryClient` to query `DEAL_FEATURE_TABLE` in batches of `FEATURE_BATCH_SIZE` (default 500), fetching `deal_id`, `deal_cvr_coec_log_30d` (→ `fs_deal_cvr_coec`), and `deal_gppi_coec_log_30d` (→ `fs_deal_gppi_coec`).
   - From: `featureProviderAdapter`
   - To: `bigQueryClient` → `bigQuery`
   - Protocol: BigQuery SDK

4. **Query BigQuery option features**: `featureProviderAdapter` queries `DEAL_OPTION_FEATURE_TABLE` for option-level features: `option_id`, `option_cvr_coec_log_30d` (→ `fs_option_cvr_coec`), `option_gppi_coec_log_30d` (→ `fs_option_gppi_coec`).
   - From: `featureProviderAdapter`
   - To: `bigQueryClient` → `bigQuery`
   - Protocol: BigQuery SDK

5. **Query BigQuery distance bucket features**: `featureProviderAdapter` queries `DEAL_DISTANCE_BUCKET_TABLE` (`prj-grp-relevance-dev-2867.fs.deal_distance_bucket_prior_v2`) for deal-level distance bucket priors: `log_oe_b0` … `log_oe_b8` (→ `fs_dist_gppi_b0` … `fs_dist_gppi_b8`). These are deal-level and applied to all options of each deal.
   - From: `featureProviderAdapter`
   - To: `bigQueryClient` → `bigQuery`
   - Protocol: BigQuery SDK

6. **Partial update Vespa documents**: For each feature entity batch, `refreshFeaturesUseCase` calls `searchIndexAdapter.update_option()` with only the feature fields. `searchIndexAdapter` calls `vespaClient.update_document()` (partial update — does not overwrite non-feature fields). Up to `FEATURE_REFRESH_MAX_WORKERS` (default 10) concurrent async tasks run in parallel.
   - From: `searchIndexAdapter`
   - To: `vespaClient` → `vespaCluster`
   - Protocol: HTTP (pyvespa partial update)

7. **Job completes**: `SchedulerJobMetricsTracker` records job duration and success/failure as Prometheus metrics.
   - From: `schedulerEndpoints` wrapper
   - To: Prometheus metrics store
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BigQuery table unavailable | Exception logged; job aborts | Feature values in Vespa remain at last-known state until next successful run |
| Single feature batch query fails | Exception logged; remaining batches continue | Partial feature refresh; some documents temporarily have stale features |
| Vespa partial update fails | Exception logged; remaining documents continue | Affected option retains previous feature values; re-applied on next run |
| `RefreshFeaturesUseCase` not available (BigQuery disabled) | `schedulerEndpoints` returns HTTP 503 | CronJob curl returns non-zero exit code; CronJob retries |

## Sequence Diagram

```
continuumVespaIndexerCronJobs -> schedulerEndpoints: POST /scheduler/refresh-features
schedulerEndpoints --> continuumVespaIndexerCronJobs: {"status": "accepted"}
schedulerEndpoints -> refreshFeaturesUseCase: execute() [background task]
refreshFeaturesUseCase -> featureProviderAdapter: stream_features(deal)
featureProviderAdapter -> bigQueryClient: query DEAL_FEATURE_TABLE (batches of 500)
bigQueryClient -> bigQuery: SQL query
bigQuery --> bigQueryClient: feature rows
bigQueryClient --> featureProviderAdapter: deal feature records
featureProviderAdapter --> refreshFeaturesUseCase: Feature stream
refreshFeaturesUseCase -> featureProviderAdapter: stream_features(option)
featureProviderAdapter -> bigQueryClient: query DEAL_OPTION_FEATURE_TABLE
bigQueryClient -> bigQuery: SQL query
bigQuery --> bigQueryClient: feature rows
featureProviderAdapter --> refreshFeaturesUseCase: Feature stream
refreshFeaturesUseCase -> featureProviderAdapter: stream_features(distance_bucket)
featureProviderAdapter -> bigQueryClient: query DEAL_DISTANCE_BUCKET_TABLE
bigQuery --> bigQueryClient: feature rows
featureProviderAdapter --> refreshFeaturesUseCase: Feature stream
loop for each feature batch (up to 10 concurrent tasks)
  refreshFeaturesUseCase -> searchIndexAdapter: update_option(features)
  searchIndexAdapter -> vespaClient: update_document(partial doc)
  vespaClient -> vespaCluster: HTTP PATCH
  vespaCluster --> vespaClient: 200 OK
end
```

## Related

- Related flows: [Scheduled Deal Refresh from Feed](scheduled-deal-refresh.md), [Real-Time Deal Update Indexing](real-time-deal-update.md)

---
service: "emailsearch-dataloader"
title: "Engage Upload Job"
generated: "2026-03-03"
type: flow
flow_name: "engage-upload-job"
flow_type: scheduled
trigger: "Quartz scheduler fires EngageUploadJob on configured cron schedule"
participants:
  - "continuumEmailSearchDataloaderService"
  - "continuumCampaignManagementService"
  - "externalCampaignPerformanceService_9f3b"
  - "externalPhraseeService_1a8c"
  - "continuumEmailSearchPostgresDb"
architecture_ref: "emailsearch_dataloader_components"
---

# Engage Upload Job

## Summary

The Engage Upload Job is a scheduled batch flow that identifies Phrasee/Engage-type campaigns that sent within a configurable delay window, fetches their performance metrics, evaluates statistical significance, and uploads the results to the Phrasee (Engage) service. This flow enables the Phrasee natural language generation platform to learn from campaign performance outcomes and improve future subject line optimization. It processes campaigns for all configured countries in parallel using a ForkJoinPool.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler fires `EngageUploadJob` on a configured cron schedule (from runtime YAML `quartz` config)
- **Frequency**: Configured per deployment; the `uploadDelayHours` setting determines which campaigns are in scope for each run (campaigns that sent `uploadDelayHours` to `uploadDelayHours + 1` hours ago)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Schedulers | Initiates the job | `continuumEmailSearchDataloaderService` |
| Campaign Management Service | Provides the list of APPROVED EXPLORE campaigns per country | `continuumCampaignManagementService` |
| Campaign Performance Service | Provides per-treatment performance metrics | `externalCampaignPerformanceService_9f3b` |
| Phrasee Service | Receives uploaded campaign performance results | `externalPhraseeService_1a8c` |
| Email Search Service / StatSigMetricsDao | Persists stat-sig metrics to Postgres | `continuumEmailSearchDataloaderService` |
| Email Search Postgres | Stores statistical significance outcome data | `continuumEmailSearchPostgresDb` |

## Steps

1. **Quartz fires EngageUploadJob**: The Quartz scheduler invokes `EngageUploadJob.run()` with an `EngageUploadConfig` (includes `uploadDelayHours`, `threads`, and other settings).
   - From: `quartzSchedulers`
   - To: `EngageUploadJob`
   - Protocol: in-process (JVM)

2. **Fetch campaigns per country (parallel)**: For each country in `appConfig.countries()`, calls `CampaignManagementServiceClient.getCampaigns(EXPLORE, country, sendDate, APPROVED)` asynchronously using `CompletableFuture`. The `sendDate` is `now() - uploadDelayHours / 24 days`.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `continuumCampaignManagementService`
   - Protocol: REST (Retrofit)

3. **Filter to Engage campaigns in upload window**: From all returned campaigns, filters to those that:
   - Have a Phrasee config with type `"engage"`
   - Have treatment time-of-day configured
   - Sent between `uploadDelayHours` and `uploadDelayHours + 1` hours ago (time window check)
   - From: `EngageUploadJob` (in-process filtering)

4. **Spawn per-campaign upload tasks**: For each eligible campaign, creates an `EngageUploadTask` and submits it to a `ForkJoinPool` with `engageUploadConfig.threads()` threads.
   - From: `EngageUploadJob`
   - To: `EngageUploadTask` instances (parallel)
   - Protocol: in-process (ForkJoinPool)

5. **Fetch campaign performance metrics**: Each `EngageUploadTask` calls `CampaignPerformanceServiceClient` to retrieve per-treatment performance metrics.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `externalCampaignPerformanceService_9f3b`
   - Protocol: REST (Retrofit)

6. **Evaluate statistical significance**: Computes treatment significance scores using `CampaignPerformanceEvaluator` (same logic as `DecisionJob`). Results stored as `CampaignStatSigMetrics`.
   - From: `EngageUploadTask` (in-process)

7. **Persist stat-sig metrics to Postgres**: Writes the computed significance metrics to `campaign_stat_sig_metrics` in Email Search Postgres via `StatSigMetricsDao`.
   - From: `daoLayer_EmaDat`
   - To: `continuumEmailSearchPostgresDb`
   - Protocol: JDBC

8. **Upload results to Phrasee Service**: Calls `PhraseeClient` to upload the campaign performance outcome data (treatment names and significance) to the Phrasee/Engage platform.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `externalPhraseeService_1a8c`
   - Protocol: REST (Retrofit)

9. **Emit metrics**: Job duration and campaign count emitted to Wavefront via `metricsHelper`.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `wavefront`
   - Protocol: REST (Retrofit)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `EngageUploadConfig` is null | `METRIC_FAILED_JOB_COUNT` incremented; `JobExecutionException` thrown | Job fails; Quartz logs the failure |
| Campaign fetch per country fails | `CompletionException` thrown and logged with country context | That country's campaigns are skipped; other countries continue |
| No campaigns in upload window | `METRIC_CAMPAIGN_COUNT` emitted as 0; ForkJoinPool not created | Job completes as no-op |
| Performance fetch fails per campaign | Exception caught in `EngageUploadTask`; logged | That campaign skipped; other campaigns in pool continue |
| Phrasee Service unavailable | Exception propagated from Retrofit call | Upload for that campaign fails; no retry observed |
| Generic exception in `run()` | `METRIC_FAILED_JOB_COUNT` incremented; error logged; exception not re-thrown | Job marked as failed in metrics; Quartz does not re-trigger |

## Sequence Diagram

```
QuartzScheduler -> EngageUploadJob: fire(EngageUploadConfig)
EngageUploadJob -> CampaignManagementService: getCampaigns(EXPLORE, country, sendDate, APPROVED) [per country, parallel]
CampaignManagementService --> EngageUploadJob: List<Campaign> per country
EngageUploadJob -> EngageUploadJob: filter(engage type, time window)
EngageUploadJob -> EngageUploadTask[N]: execute() [parallel, ForkJoinPool]
EngageUploadTask -> CampaignPerformanceService: getPerformances(campaignSendIds)
CampaignPerformanceService --> EngageUploadTask: performance metrics
EngageUploadTask -> EngageUploadTask: evaluateSignificance() [in-process]
EngageUploadTask -> StatSigMetricsDao: addStatSigMetric(metrics) [JDBC]
StatSigMetricsDao -> EmailSearchPostgres: INSERT [JDBC]
EngageUploadTask -> PhraseeService: uploadResults(campaignPerformance)
EngageUploadJob -> Wavefront: submitTimerMetric(processTime)
```

## Related

- Architecture component view: `emailsearch_dataloader_components`
- Related flows: [Campaign Decision Job](campaign-decision-job.md), [Metrics Export to Hive](metrics-export-to-hive.md)

---
service: "emailsearch-dataloader"
title: "Campaign Decision Job"
generated: "2026-03-03"
type: flow
flow_name: "campaign-decision-job"
flow_type: scheduled
trigger: "Quartz scheduler fires DecisionJob on configured cron schedule"
participants:
  - "continuumEmailSearchDataloaderService"
  - "continuumCampaignManagementService"
  - "externalCampaignPerformanceService_9f3b"
  - "externalInboxManagementEmailUiService_6a2d"
  - "externalInboxManagementPushUiService_63de"
  - "continuumArbitrationService"
  - "continuumEmailSearchPostgresDb"
  - "continuumDecisionEnginePostgresDb"
  - "wavefront"
architecture_ref: "emailsearch_dataloader_components"
---

# Campaign Decision Job

## Summary

The Campaign Decision Job is the core scheduled flow of the Email Search Dataloader. It runs periodically via Quartz, evaluates the statistical significance of A/B treatment experiments for all APPROVED campaigns, and either rolls out the best-performing treatment or rolls out the control depending on the outcome. Decision results and statistical significance metrics are persisted to PostgreSQL and counters are emitted to Wavefront. The job supports email and push platform campaigns (Turbo and Phrasee/Engage experiment types).

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`quartzSchedulers` component) fires `DecisionJob` based on the cron expression defined in the runtime YAML `quartz` config block
- **Frequency**: Configured per deployment (not hardcoded); typically runs multiple times per hour during campaign send windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Schedulers | Initiates the job | `continuumEmailSearchDataloaderService` |
| Campaign Management Service | Provides list of APPROVED campaigns; receives rollout commands | `continuumCampaignManagementService` |
| Campaign Performance Service | Provides per-treatment click/open/send/push metrics | `externalCampaignPerformanceService_9f3b` |
| Inbox Management Email UI Service | Provides email inbox accepted count for significance threshold | `externalInboxManagementEmailUiService_6a2d` |
| Inbox Management Push UI Service | Provides push inbox accepted count for significance threshold | `externalInboxManagementPushUiService_63de` |
| Email Search Service | Core evaluation logic | `continuumEmailSearchDataloaderService` |
| Email Search Postgres | Persists stat-sig metrics results | `continuumEmailSearchPostgresDb` |
| Decision Engine Postgres | Reads order/GP data for GP-metric campaigns | `continuumDecisionEnginePostgresDb` |
| Wavefront | Receives operational metric counters and timers | `wavefront` |

## Steps

1. **Quartz fires DecisionJob**: The Quartz scheduler triggers `DecisionJob.run()` with a `DecisionConfig` from the job data map.
   - From: `quartzSchedulers`
   - To: `DecisionJob`
   - Protocol: in-process (JVM)

2. **Fetch APPROVED campaigns**: `DecisionJob` calls `BaseDecisionJob.processCampaigns()`, which queries the Campaign Management Service for all APPROVED campaigns of type `EXPLORE` for the configured set of countries and the current send date.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `continuumCampaignManagementService`
   - Protocol: REST (Retrofit)

3. **Spawn per-campaign decision tasks**: For each returned campaign, a `CampaignDecisionTask` is created and submitted to a `ForkJoinPool` (thread count: min of campaign count and configured `decisionThreads`).
   - From: `DecisionJob`
   - To: `CampaignDecisionTask` instances (parallel)
   - Protocol: in-process (ForkJoinPool)

4. **Validate campaign eligibility**: Each `CampaignDecisionTask.execute()` first checks whether the current time is past the `decisionStartOffset` (computed from exploit send time + configured offset minutes). Campaigns not yet eligible for evaluation are skipped.
   - From: `CampaignDecisionTask`
   - To: campaign schedule data (in-memory)
   - Protocol: in-process

5. **Sync GP data (if primary metric is GP)**: If the campaign uses the GP metric, `CampaignDecisionTask.syncGpData()` reads order gross revenue from `OrderDao` (Decision Engine Postgres) and updates campaign performance GP metrics via `CampaignPerformanceService`.
   - From: `continuumEmailSearchDataloaderService` (`daoLayer_EmaDat`)
   - To: `continuumDecisionEnginePostgresDb`
   - Protocol: JDBC

6. **Fetch Inbox Management metrics (parallel with step 7)**: Calls the appropriate Inbox Management client (email or push, based on `campaign.mediaType()`) to retrieve accepted count for the campaign send ID. On failure, returns `Optional.empty()` and logs the error.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `externalInboxManagementEmailUiService_6a2d` or `externalInboxManagementPushUiService_63de`
   - Protocol: REST (Retrofit)

7. **Fetch Campaign Performance metrics (parallel with step 6)**: Calls `CampaignPerformanceService` with all treatment send IDs to retrieve click, open, send, and push metrics for each treatment. Throws `IllegalStateException` if any treatment has zero sends.
   - From: `continuumEmailSearchDataloaderService` (`webClients`)
   - To: `externalCampaignPerformanceService_9f3b`
   - Protocol: REST (Retrofit)

8. **Calculate statistical significance**: `CampaignPerformanceEvaluator.getTreatmentPerformances()` computes significance (using `commons-math3` statistical tests) for each non-control treatment versus the control. Supports OPENS, CLICKS, and GP metrics across EMAIL and PUSH platforms. Results are collected as `CampaignStatSigMetrics` objects.
   - From: `emailSearchService` (in-process)
   - To: in-memory
   - Protocol: in-process

9. **Calculate dynamic significance threshold**: If Inbox Management data is present, the threshold is looked up from a bucket-size map in `decisionConfig.decisionSettings.significanceThresholds`; otherwise defaults to 95%.
   - From: `CampaignDecisionTask`
   - To: in-memory config
   - Protocol: in-process

10. **Evaluate rollout decision**: `shouldRollOut()` and `shouldConclude()` determine the appropriate outcome. Rollout occurs if statistical significance is reached and `autoRollout=true` and campaign is not already rolled out. Control is rolled out if the deadline (`decisionStopOffset`) is passed and control performs better or no stat-sig was reached.
    - From: `CampaignDecisionTask` (in-process)
    - Decision flags: `DF_NONE_0`, `DF_CONTROL_DEFAULT_1`, `DF_TREATMENT_BEST_2`, `DF_CONTROL_WIN_3`, `DF_TREATMENT_WIN_4`

11. **Issue rollout command**: If rollout is warranted and `dryRun=false`, calls `campaignManagementServiceClient.rolloutTemplateTreatment()` with the winning treatment name. Records the rollout delay metric.
    - From: `continuumEmailSearchDataloaderService` (`webClients`)
    - To: `continuumCampaignManagementService`
    - Protocol: REST (Retrofit)

12. **Persist stat-sig metrics**: Writes `CampaignStatSigMetrics` (including the decision flag and significance values) to `campaign_stat_sig_metrics` table in Email Search Postgres via `StatSigMetricsDao.addStatSigMetric()`.
    - From: `continuumEmailSearchDataloaderService` (`daoLayer_EmaDat`)
    - To: `continuumEmailSearchPostgresDb`
    - Protocol: JDBC

13. **Emit metrics to Wavefront**: Counters and timers (`custom.decision.*`, `custom.treatment.roll-out-count`, `custom.control.roll-out-count`, job time) are sent to Wavefront.
    - From: `continuumEmailSearchDataloaderService` (`webClients`)
    - To: `wavefront`
    - Protocol: REST (Retrofit)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `DecisionConfig` is null | `failedJobCount` counter incremented; `JobExecutionException` thrown | Job fails; Quartz scheduler logs the failure |
| Campaign fetch from CMS fails | `CompletionException` thrown; logged with country context | That country's campaigns are skipped for this run |
| Campaign Performance data missing | `METRIC_MISSING_CP_METRICS_COUNT` incremented; `IllegalStateException` thrown | That campaign's decision task fails; does not affect other campaigns |
| Inbox Management data missing | `METRIC_MISSING_IM_METRICS_COUNT` incremented; `Optional.empty()` returned | Falls back to default 95% significance threshold |
| Treatment has zero sends | `IllegalStateException: One or more treatments have no sends` | Decision task fails for that campaign |
| Rollout command to CMS fails | `CompletableFuture` exception; logged; `METRIC_FAILED_DECISION_COUNT` incremented | Rollout not issued; campaign remains in current state |
| Generic exception in decision task | `METRIC_FAILED_DECISION_COUNT` incremented; error logged | Other campaigns in ForkJoinPool continue |

## Sequence Diagram

```
QuartzScheduler -> DecisionJob: fire(DecisionConfig)
DecisionJob -> CampaignManagementService: getCampaigns(EXPLORE, country, date, APPROVED)
CampaignManagementService --> DecisionJob: List<Campaign>
DecisionJob -> CampaignDecisionTask[N]: execute() [parallel, ForkJoinPool]
CampaignDecisionTask -> InboxManagementService: getCampaignMetrics(campaignSendId) [async]
CampaignDecisionTask -> CampaignPerformanceService: listPerformances(campaignSendIds) [async]
InboxManagementService --> CampaignDecisionTask: Optional<MetricsResponse>
CampaignPerformanceService --> CampaignDecisionTask: CampaignPerformances
CampaignDecisionTask -> CampaignDecisionTask: calculateSignificance() [in-process]
CampaignDecisionTask -> CampaignDecisionTask: evaluateRollout() [in-process]
CampaignDecisionTask -> CampaignManagementService: rolloutTemplateTreatment(treatmentName) [if rollout]
CampaignDecisionTask -> EmailSearchPostgres: addStatSigMetric(metrics) [JDBC]
DecisionJob -> Wavefront: submitTimerMetric(jobTime)
```

## Related

- Architecture component view: `emailsearch_dataloader_components`
- Related flows: [Metrics Export to Hive](metrics-export-to-hive.md), [Kafka Event Ingestion](kafka-event-ingestion.md)

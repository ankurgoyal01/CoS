---
service: "aes-service"
title: "Scheduled Audience Export"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-audience-export"
flow_type: scheduled
trigger: "Daily Quartz cron job (default expression set via audienceJobCronExpression config)"
participants:
  - "aesSchedulingEngine"
  - "aesTargetSyncPipeline"
  - "aesDataAccessLayer"
  - "aesIntegrationClients"
  - "continuumAudienceExportPostgres"
  - "continuumAudienceExportPostgresS2S"
  - "continuumCIAService"
  - "continuumCerebroWarehouse"
  - "facebookAds"
  - "googleAds"
  - "microsoftAds"
  - "tiktokAds"
  - "continuumGcpStorage"
architecture_ref: "dynamic-audience-export-flow"
---

# Scheduled Audience Export

## Summary

The scheduled audience export is the core operational flow of AES. Every day, the Quartz scheduler fires a job for each active audience, which fetches the audience's source data from the Cerebro/Hive warehouse, computes the delta of users to add or remove compared to the previous run, resolves customer identifiers to hashed emails and device IDs, and pushes the resulting membership changes to each configured ad-network partner (Facebook, Google, Microsoft, TikTok).

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`aesSchedulingEngine`) fires per-audience cron trigger
- **Frequency**: Daily (default; configurable per-audience via `audienceJobCronExpression`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduling Engine | Fires the cron trigger and initiates the pipeline | `aesSchedulingEngine` |
| Target Sync Pipeline | Orchestrates all task stages in order | `aesTargetSyncPipeline` |
| Data Access Layer | Reads/writes job state and audience metadata throughout the run | `aesDataAccessLayer` |
| Integration Clients | Calls CIA, Cerebro, and ad-network partner APIs | `aesIntegrationClients` |
| AES Postgres | Persists job status, delta data, and partner update records | `continuumAudienceExportPostgres` |
| AES Postgres S2S | Provides customer-ID-to-email/device-ID mapping | `continuumAudienceExportPostgresS2S` |
| CIA | Returns audience schedule and segment definition | `continuumCIAService` |
| Cerebro / Hive Warehouse | Provides raw audience customer ID source tables | `continuumCerebroWarehouse` |
| Facebook Ads | Receives add/delete user lists for custom audience | `facebookAds` |
| Google Ads | Receives add/delete customer match members | `googleAds` |
| Microsoft Bing Ads | Receives customer list delta upload | `microsoftAds` |
| TikTok Ads | Receives audience segment member add/delete | `tiktokAds` |
| GCP Cloud Storage | Stores temporary export files for Google Cloud workflows | `continuumGcpStorage` |

## Steps

1. **Trigger Job**: Quartz cron fires the audience job trigger.
   - From: `aesSchedulingEngine`
   - To: `aesTargetSyncPipeline`
   - Protocol: internal

2. **INIT — Set status to IN_PROGRESS**: Writes job status `IN_PROGRESS`, sub-status `INIT` to Postgres.
   - From: `aesTargetSyncPipeline`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

3. **Fetch audience metadata from CIA**: Retrieves schedule definition, cron expression, segment details, and Hive table reference.
   - From: `aesIntegrationClients`
   - To: `continuumCIAService`
   - Protocol: HTTPS/REST

4. **COPY_EXPORT_DATA — Read source data from Cerebro**: Queries the Hive audience table in batches (`cerebroFetchBatchSize`) for the relevant NA or EMEA database.
   - From: `aesIntegrationClients`
   - To: `continuumCerebroWarehouse`
   - Protocol: JDBC (Hive JDBC)

5. **COMPUTE_DELTA — Calculate delta**: For MOVING_WINDOW audiences, computes the set of user IDs to add (new members) and remove (lapsed members) compared to the previous export. For INCREMENTAL audiences, the Hive table already contains only the delta.
   - From: `aesTargetSyncPipeline`
   - To: `aesDataAccessLayer` / `continuumAudienceExportPostgres`
   - Protocol: JDBC

6. **INSERT_DATA_TO_DELTA — Persist delta records**: Writes computed add/delete sets to Postgres staging tables.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

7. **MAP_CUSTOMER_INFO — Resolve customer identifiers**: Looks up hashed email addresses and device IDs (IDFA) for each customer ID in the delta via the S2S database.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgresS2S`
   - Protocol: JDBC

8. **TARGETS_UPDATE — Push updates to each active ad partner**: For each partner in `activePartners`, calls the appropriate Integration Client to upload the add/delete lists. Sub-status steps per partner (e.g., `FACEBOOK_EMAIL_ADD`, `GOOGLE_IDFA_DEL`, etc.).
   - From: `aesIntegrationClients`
   - To: `facebookAds` / `googleAds` / `microsoftAds` / `tiktokAds`
   - Protocol: HTTPS/REST, HTTPS/gRPC, HTTPS/Bulk API

9. **GOOGLECLOUD_DATA_TRANSFER (Google Cloud variant)**: For Google Cloud audience type, uploads export file to GCP Cloud Storage.
   - From: `aesIntegrationClients`
   - To: `continuumGcpStorage`
   - Protocol: GCS API

10. **COMMIT — Update audience metadata**: Rotates the `currentTablename` / `previousTablename` pointers; updates `afterFilterSize` and timestamp fields in Postgres.
    - From: `aesDataAccessLayer`
    - To: `continuumAudienceExportPostgres`
    - Protocol: JDBC

11. **CLEAN_UP — Remove staging data and set COMPLETED**: Deletes temporary delta tables/rows; sets `jobStatus=SUCCESS`, `jobSubStatus=COMPLETED`.
    - From: `aesDataAccessLayer`
    - To: `continuumAudienceExportPostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any pipeline stage fails | Job status set to `FAILED`; retry job scheduled after `audienceJobRetryInterval` | Up to `audienceJobRetryCount` (3) retries; Grafana alert if not successful in 25 hours |
| CIA API unavailable | Immediate failure of INIT stage; retry on next cycle | Audience skipped until CIA recovers |
| Cerebro query timeout | Job fails at COPY_EXPORT_DATA; retried | Device-ID lookups fall back to pre-imported S2S tables |
| Partner API failure (Facebook/Google/etc.) | Job fails at per-partner sub-status; retry with exponential back-off within retry count | Partner audience out of sync until retry succeeds; alert fires if prolonged |
| Retry limit exceeded | Job stops retrying until next scheduled run | Manual execution required via `GET /api/v1/metadata/{id}/executeJob` |

## Sequence Diagram

```
QuartzScheduler -> aesTargetSyncPipeline: Fire audience cron trigger
aesTargetSyncPipeline -> continuumAudienceExportPostgres: Set status INIT/IN_PROGRESS
aesTargetSyncPipeline -> continuumCIAService: Fetch audience schedule and segment details
aesTargetSyncPipeline -> continuumCerebroWarehouse: Read source audience data (COPY_EXPORT_DATA)
aesTargetSyncPipeline -> continuumAudienceExportPostgres: Compute and store delta (COMPUTE_DELTA/INSERT_DATA_TO_DELTA)
aesTargetSyncPipeline -> continuumAudienceExportPostgresS2S: Resolve customer emails/device IDs (MAP_CUSTOMER_INFO)
aesTargetSyncPipeline -> facebookAds: Upload add/delete email and IDFA lists
aesTargetSyncPipeline -> googleAds: Upload add/delete customer match members
aesTargetSyncPipeline -> microsoftAds: Upload customer list delta
aesTargetSyncPipeline -> tiktokAds: Upload audience segment updates
aesTargetSyncPipeline -> continuumAudienceExportPostgres: Commit metadata; set COMPLETED
```

## Related

- Architecture dynamic view: `dynamic-audience-export-flow`
- Related flows: [Scheduled Audience Creation](scheduled-audience-creation.md), [Audience Pause and Resume](audience-pause-resume.md)
- Troubleshooting: [Runbook](../runbook.md)

---
service: "ai-reporting"
title: "Audience Management Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "audience-management-sync"
flow_type: scheduled
trigger: "Quartz scheduler fires audience table update and sync jobs on configured cadence"
participants:
  - "continuumAiReportingService_scheduler"
  - "continuumAiReportingService_audienceService"
  - "continuumAiReportingService_hiveAnalytics"
  - "continuumAiReportingService_audienceManagementClient"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingService_gcsClient"
  - "continuumAiReportingMySql"
  - "continuumAiReportingHive"
  - "continuumAiReportingGcs"
  - "continuumAudienceManagementService"
architecture_ref: "dynamic-audience-management-sync"
---

# Audience Management Sync

## Summary

This flow synchronizes merchant audience data between Groupon's Hive-based analytics warehouse and the Audience Management Service (`continuumAudienceManagementService`). The Quartz scheduler periodically triggers the Audience Service, which reads raw audience segment data from Hive, computes membership deltas against the last-synced state in MySQL, and pushes updated audience memberships to the Audience Management Service for use in campaign targeting. Optionally, Hive materializations are uploaded to GCS for downstream use.

## Trigger

- **Type**: schedule
- **Source**: Quartz Scheduler (`continuumAiReportingService_scheduler`) configured in JTier config
- **Frequency**: Scheduled (cadence defined in Quartz config; typically daily or multiple times per day for delta sync)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires audience table update and sync jobs | `continuumAiReportingService_scheduler` |
| Audience Service | Orchestrates audience delta computation and sync | `continuumAiReportingService_audienceService` |
| Hive Analytics Executor | Executes Hive JDBC queries for audience source data | `continuumAiReportingService_hiveAnalytics` |
| Audience Management Client | Sends audience membership updates to AMS | `continuumAiReportingService_audienceManagementClient` |
| MySQL JDBI Repositories | Reads and writes audience history and delta state | `continuumAiReportingService_mysqlRepositories` |
| GCS Client | Uploads Hive materializations to GCS when required | `continuumAiReportingService_gcsClient` |
| AI Reporting MySQL | Stores audience history, sync state, and deltas | `continuumAiReportingMySql` |
| AI Reporting Hive | Analytics warehouse — source of audience segment data | `continuumAiReportingHive` |
| AI Reporting GCS | Destination for Hive materializations | `continuumAiReportingGcs` |
| Audience Management Service | Platform service that owns audience segment memberships for targeting | `continuumAudienceManagementService` |

## Steps

1. **Scheduler fires audience sync job**: Quartz triggers the audience table update and sync task
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_audienceService`
   - Protocol: direct (in-process)

2. **Reads last-synced audience state from MySQL**: Audience Service retrieves the previous sync timestamp and membership snapshot for each audience segment
   - From: `continuumAiReportingService_audienceService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

3. **Queries audience source data from Hive**: Executes Hive JDBC queries via Hive Analytics Executor to retrieve current audience segment membership
   - From: `continuumAiReportingService_audienceService`
   - To: `continuumAiReportingHive` via `continuumAiReportingService_hiveAnalytics`
   - Protocol: Hive JDBC

4. **Computes audience membership delta**: Audience Service computes additions and removals since the last sync
   - From: `continuumAiReportingService_audienceService`
   - To: internal delta computation
   - Protocol: direct (in-process)

5. **Persists delta and updated history to MySQL**: Writes audience delta records and updates the sync state in MySQL
   - From: `continuumAiReportingService_audienceService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

6. **Uploads Hive materialization to GCS (optional)**: If the job requires materialized output for downstream use, Hive Analytics Executor uploads results to GCS
   - From: `continuumAiReportingService_hiveAnalytics`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

7. **Pushes audience membership to Audience Management Service**: Sends computed delta (additions/removals) to `continuumAudienceManagementService`
   - From: `continuumAiReportingService_audienceService`
   - To: `continuumAudienceManagementService` via `continuumAiReportingService_audienceManagementClient`
   - Protocol: HTTPS/JSON

8. **Records sync completion**: Updates last-sync timestamp and member count in MySQL
   - From: `continuumAiReportingService_audienceService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive query failure | Job fails; Quartz retries on next cycle; last sync state preserved in MySQL | Audience data not updated for this cycle; AMS not called |
| Audience Management Service unavailable | Delta computed and persisted to MySQL; AMS sync retried on next cycle | Targeting may use stale audience data temporarily |
| GCS upload failure (materialization) | Logged as non-critical; AMS sync continues without GCS materialization | Downstream GCS consumers may see stale materialization |
| MySQL write failure during delta persistence | Job fails; Quartz retry; Hive re-queried on next run | No partial state; idempotent re-run on retry |
| Empty delta (no changes) | No-op for AMS sync; sync state timestamp still updated | Efficient — avoids redundant AMS API calls |

## Sequence Diagram

```
scheduler -> audienceService: triggerAudienceSync()
audienceService -> mysqlRepositories: getLastSyncState(audienceIds)
mysqlRepositories -> continuumAiReportingMySql: SQL SELECT
continuumAiReportingMySql --> mysqlRepositories: lastSyncTimestamp, memberCounts
audienceService -> hiveAnalytics: queryAudienceSegments(sinceTimestamp)
hiveAnalytics -> continuumAiReportingHive: Hive JDBC SELECT
continuumAiReportingHive --> hiveAnalytics: audience membership rows
hiveAnalytics -> gcsClient: uploadMaterialization(resultFile) [optional]
gcsClient -> continuumAiReportingGcs: GCS PUT
audienceService -> audienceService: computeDelta(current, last)
audienceService -> mysqlRepositories: persistDelta(additions, removals)
mysqlRepositories -> continuumAiReportingMySql: SQL INSERT/UPDATE
audienceService -> audienceManagementClient: syncMembership(audienceId, additions, removals)
audienceManagementClient -> continuumAudienceManagementService: HTTPS POST /audiences/sync
continuumAudienceManagementService --> audienceManagementClient: 200 OK
audienceService -> mysqlRepositories: updateSyncTimestamp(audienceId)
```

## Related

- Architecture dynamic view: `dynamic-audience-management-sync`
- Related flows: [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md), [Ads Reporting Aggregation](ads-reporting-aggregation.md)

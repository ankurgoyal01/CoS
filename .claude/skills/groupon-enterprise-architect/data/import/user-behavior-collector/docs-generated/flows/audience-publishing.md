---
service: "user-behavior-collector"
title: "Audience Publishing"
generated: "2026-03-03"
type: flow
flow_name: "audience-publishing"
flow_type: scheduled
trigger: "Daily cron (publish_audience) at 23:00 UTC (NA) / 10:30 UTC (EMEA)"
participants:
  - "continuumUserBehaviorCollectorJob"
  - "continuumDealViewNotificationDb"
  - "audienceService_d1f2"
  - "gdoopHadoopCluster_8d2c"
architecture_ref: "continuumUserBehaviorCollectorJob-components"
---

# Audience Publishing

## Summary

The Audience Publishing flow reads behavioral audience data from the `deal_view_notification` PostgreSQL database, segments users by behavior type (deal views, searches, post-purchase, email opens, web-touch, back-in-stock) and by country, generates per-country CSV files (with bcookie or consumer_id columns), uploads those files to the Cerebro HDFS cluster, and notifies the Audience Management Service (AMS) via REST API calls so that downstream notification campaigns can target the right users. It runs as a separate cron invocation (`publish_audience`) from the main deal-views batch job.

## Trigger

- **Type**: schedule
- **Source**: System cron at `/etc/cron.d/user-behavior-collector`; runs the `publish_audience` script
- **Frequency**: Daily — NA production: 23:00 UTC; EMEA production: 10:30 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Initiates audience publishing with `-publishAudienceOnly` flag | `continuumUserBehaviorCollectorJob` |
| Audience Publisher | Reads DB, generates CSV files, uploads to HDFS, calls AMS API | `continuumUserBehaviorCollectorJob` (audiencePublisher component) |
| Deal View Notification DB | Source of all audience segments | `continuumDealViewNotificationDb` |
| Cerebro HDFS | Receives uploaded audience CSV files | `gdoopHadoopCluster_8d2c` (Cerebro) |
| Audience Management Service (AMS) | Receives notification of new audience file and triggers IMPORT state | `audienceService_d1f2` |

## Steps

1. **Read audience segments from DB**: Audience Publisher queries multiple audience types from `continuumDealViewNotificationDb`:
   - `getDealViewAudienceInfo()` — DealView audience (bcookie)
   - `getDealViewAudienceInfoForAudience()` — DealView email audience (consumerId)
   - `getUserSearchPushAudienceInfo()` — UserSearch push audience
   - `getUserSearchEmailAudienceInfo()` — UserSearch email audience
   - `getPurchaseAudienceInfo()` — PostPurchase (PVF + BIA deduped)
   - `getPurchaseEmailAudienceInfo()` — PostPurchase email audience
   - `getWebTouchAudienceInfoForAudience()` — WebTouch inbox audience
   - `getBackInStockPushAudienceInfo()` — BackInStock push audience
   - `getBackInStockEmailAudienceInfo()` — BackInStock email audience
   - From: `continuumUserBehaviorCollectorJob` (audiencePublisher)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC (read-only)

2. **Segment users by country**: Groups `AudienceInfo` list by `countryCode`; country list sourced from `AppConfig.getProperty("ec.countries")` (comma-separated)

3. **Look up sourced audience IDs**: For each audience type and country, retrieves the `sourcedAudienceId` from `app-config` using key `<sourcedAudienceString>_<country>`

4. **Generate audience CSV on local disk**: For each country, writes a CSV file with header `bcookie` or `consumer_id` to local path `~/<EC_AUDIENCE>/<AudienceType>_<country>_<YYYY-MM-DD>`
   - From: `continuumUserBehaviorCollectorJob` (audiencePublisher)
   - To: local filesystem (job host)
   - Protocol: direct file I/O

5. **Upload CSV to Cerebro HDFS**: Copies local CSV file to Cerebro HDFS at `<cerebro_host>/<cerebro_folder>/<AudienceType>_<country>_<date>.csv`
   - From: `continuumUserBehaviorCollectorJob` (audiencePublisher)
   - To: `gdoopHadoopCluster_8d2c` (Cerebro HDFS)
   - Protocol: HDFS (`fs.copyFromLocalFile`)

6. **Notify AMS — update user sourced audience**: Calls `PUT updateUserSourcedAudience` on AMS with the Cerebro HDFS path and sourced audience ID
   - From: `continuumUserBehaviorCollectorJob` (audiencePublisher)
   - To: `audienceService_d1f2`
   - Protocol: REST (OkHttp, SSL)

7. **Notify AMS — update sourced audience state**: Calls `POST updateSourcedAudienceState` on AMS to transition audience state to `IMPORT`
   - From: `continuumUserBehaviorCollectorJob` (audiencePublisher)
   - To: `audienceService_d1f2`
   - Protocol: REST (OkHttp, SSL)

8. **Retry on AMS failure**: Steps 6 and 7 are retried together up to 3 times with exponential backoff (initial 500s, max 3000s) via `RetryUtility`; both calls confirmed idempotent

9. **Clean up aged audience files**: Deletes local audience files and Cerebro HDFS audience files older than `AUDIENCE_RETENTION_DAYS`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS API call fails | Retry up to 3 times with exponential backoff; throws RuntimeException after all retries | Audience publishing fails; PagerDuty alert; rerun with `-publishAudienceOnly` |
| Cerebro HDFS upload fails | IOException propagated | Audience file not available; AMS not notified; job fails |
| Consumer/bcookie has no country | Filtered out in `generateUserListByCountry()` | User not included in any audience segment |
| Old audience file delete fails on local disk | Logged as WARN; processing continues | Old local file remains; no impact on audience delivery |
| Old audience file delete fails on HDFS | IOException propagated | Logged as ERROR; old file remains; current file may overlap |

## Sequence Diagram

```
CronScheduler -> JobOrchestrator: Invoke publish_audience script (-publishAudienceOnly)
JobOrchestrator -> AudiencePublisher: publishAudience() for each AudienceType
loop for each AudienceType (DealView, UserSearch, PostPurchase, WebTouch, BackInStock, etc.)
  AudiencePublisher -> DealViewNotificationDb: Query audience segment (read-only JDBC)
  DealViewNotificationDb --> AudiencePublisher: List<AudienceInfo> (userId, countryCode)
  AudiencePublisher -> AudiencePublisher: Segment by country; lookup sourcedAudienceId from config
  loop for each country
    AudiencePublisher -> LocalFS: Write audience CSV file
    AudiencePublisher -> CerebroHDFS: fs.copyFromLocalFile(localPath, hdfsPath)
    CerebroHDFS --> AudiencePublisher: Copy complete
    AudiencePublisher -> AMS: PUT updateUserSourcedAudience(hdfsPath, sourcedAudienceId)
    AMS --> AudiencePublisher: HTTP response
    AudiencePublisher -> AMS: POST updateSourcedAudienceState(sourcedAudienceId, "IMPORT")
    AMS --> AudiencePublisher: HTTP response
    AudiencePublisher -> CerebroHDFS: Delete old audience file (retention cleanup)
  end
end
AudiencePublisher --> JobOrchestrator: All audiences published
```

## Related

- Architecture dynamic view: `continuumUserBehaviorCollectorJob-components`
- Related flows: [Spark Event Ingestion](spark-event-ingestion.md), [Back-in-Stock Update](back-in-stock-update.md)

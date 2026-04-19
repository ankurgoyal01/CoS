---
service: "amsJavaScheduler"
title: "SAD Materialization"
generated: "2026-03-03"
type: flow
flow_name: "sad-materialization"
flow_type: scheduled
trigger: "cron4j scheduler — nightly, region-specific cron expression"
participants:
  - "continuumAmsJavaScheduler"
  - "continuumAudienceManagementService"
  - "continuumAmsSchedulerScheduleStore"
architecture_ref: "dynamic-ams-scheduler-sad-amsScheduler_sadMaterialization"
---

# SAD Materialization

## Summary

The SAD Materialization flow is the primary purpose of AMS Java Scheduler. It runs nightly per region (NA and EMEA) and materializes Scheduled Audience Definitions (SADs) into Scheduled Audience Instances (SAIs) by calling the AMS REST API. Before launching new-flow jobs, the runner checks YARN queue headroom to avoid overwhelming Hadoop resources. If any SADs are found in an unverified state, the Alerting Notifier sends email notifications to the audience engineering team.

## Trigger

- **Type**: schedule
- **Source**: `cron4j` scheduler fires the `UserSadScheduledAction`, `BcookieSadScheduledAction`, and `UniversalSadScheduledAction` action classes according to the schedule file for the active region/environment
- **Frequency**: Nightly — NA production: User SAD at `00:20 UTC`, Bcookie SAD at `23:00 UTC`, Universal SAD at `21:00 UTC`; EMEA production: User SAD at `22:30 UTC`, Bcookie SAD at `22:00 UTC`, Universal SAD at `23:30 UTC`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Schedule Store | Provides the cron expression and action class mapping | `continuumAmsSchedulerScheduleStore` |
| SAD Materialization Runner | Orchestrates SAD search, capacity check, SAI creation, and alerting | `amsScheduler_sadMaterialization` |
| YARN Capacity Client | Checks Hadoop queue headroom before launching new-flow jobs | `amsScheduler_yarnCapacity` |
| AMS REST Client Adapter | Executes HTTP calls to AMS `searchScheduledAudienceDefinitions` and `createScheduledAudienceInstance` endpoints | `amsScheduler_amsRestClient` |
| Alerting Notifier | Sends email alerts for unverified SADs | `amsScheduler_alerting` |
| Audience Management Service | Provides SAD search results and processes SAI creation requests | `continuumAudienceManagementService` |

## Steps

1. **Cron Trigger**: `cron4j` fires the SAD action class (e.g., `UserSadScheduledAction`, `BcookieSadScheduledAction`, or `UniversalSadScheduledAction`) at the scheduled time for the active region
   - From: `amsScheduler_actionDispatchers`
   - To: `amsScheduler_sadMaterialization`
   - Protocol: Direct (in-process)

2. **Read Cron Schedule and Action Mappings**: Scheduler references the active schedule file to determine which action to run and when
   - From: `continuumAmsJavaScheduler`
   - To: `continuumAmsSchedulerScheduleStore`
   - Protocol: File I/O (already loaded at startup)

3. **YARN Capacity Check** (new-flow jobs only): The YARN Capacity Client queries the Hadoop ResourceManager REST API to determine current queue utilization and calculate how many new jobs can safely be launched concurrently
   - From: `amsScheduler_sadMaterialization`
   - To: `amsScheduler_yarnCapacity` → YARN ResourceManager HTTP API
   - Protocol: HTTP REST

4. **Search Scheduled Audience Definitions**: The AMS REST Client calls the AMS `searchScheduledAudienceDefinitions` API to retrieve all eligible SADs for the current run (filtered by realm, type, and materialization window)
   - From: `amsScheduler_sadMaterialization` via `amsScheduler_amsRestClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP/JSON

5. **Unverified SAD Alert** (conditional): If any retrieved SADs are in an unverified state, the Alerting Notifier sends an email to the audience engineering team
   - From: `amsScheduler_sadMaterialization`
   - To: `amsScheduler_alerting` → SMTP relay
   - Protocol: SMTP

6. **Create Scheduled Audience Instances**: For each eligible SAD within the YARN capacity limit, the AMS REST Client calls `createScheduledAudienceInstance` on the AMS service to initiate audience materialization
   - From: `amsScheduler_sadMaterialization` via `amsScheduler_amsRestClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP/JSON

7. **Job Complete**: The runner finishes processing all eligible SADs; the pod exits normally
   - From: `amsScheduler_sadMaterialization`
   - To: Kubernetes CronJob controller (via pod exit code)
   - Protocol: Kubernetes pod lifecycle

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS `searchScheduledAudienceDefinitions` API error | HTTP error propagated; runner logs error and exits | Pod fails; next scheduled run retries; no partial SAIs created |
| YARN API unreachable | Capacity check skipped or defaults to zero headroom | New-flow job launches may be blocked; runner exits without creating SAIs |
| AMS `createScheduledAudienceInstance` API error (one SAD) | Error logged per SAD; subsequent SADs may still be processed | Partial materialization possible; affected SAD will be retried on next run |
| Unverified SAD detected | Email alert sent via `amsScheduler_alerting` | Alert delivered; job continues processing remaining SADs |
| SMTP relay unavailable | Email send silently fails | No alert delivered; job execution continues unaffected |

## Sequence Diagram

```
cron4j -> SadMaterializationRunner: Fire action (UserSad/BcookieSad/UniversalSad)
SadMaterializationRunner -> YarnCapacityClient: Check queue headroom
YarnCapacityClient -> YarnResourceManager: GET queue usage
YarnResourceManager --> YarnCapacityClient: Queue stats
YarnCapacityClient --> SadMaterializationRunner: Max concurrent jobs
SadMaterializationRunner -> AmsRestClient: searchScheduledAudienceDefinitions
AmsRestClient -> AudienceManagementService: GET /searchScheduledAudienceDefinitions
AudienceManagementService --> AmsRestClient: SAD list
AmsRestClient --> SadMaterializationRunner: SAD list
SadMaterializationRunner -> AlertingNotifier: Send unverified SAD email (if any)
SadMaterializationRunner -> AmsRestClient: createScheduledAudienceInstance (per eligible SAD)
AmsRestClient -> AudienceManagementService: POST /createScheduledAudienceInstance
AudienceManagementService --> AmsRestClient: SAI created
AmsRestClient --> SadMaterializationRunner: Success
SadMaterializationRunner --> cron4j: Job complete
```

## Related

- Architecture dynamic view: `dynamic-ams-scheduler-sad-amsScheduler_sadMaterialization`
- Related flows: [Scheduler Startup and Schedule Loading](scheduler-startup.md), [SAD Integrity Check](sad-integrity-check.md)

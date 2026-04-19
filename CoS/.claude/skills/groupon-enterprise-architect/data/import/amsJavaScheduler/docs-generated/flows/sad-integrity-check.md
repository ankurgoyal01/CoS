---
service: "amsJavaScheduler"
title: "SAD Integrity Check"
generated: "2026-03-03"
type: flow
flow_name: "sad-integrity-check"
flow_type: scheduled
trigger: "cron4j scheduler — nightly at 16:00 UTC (production) via SADIngegrityCheckAction"
participants:
  - "continuumAmsJavaScheduler"
  - "continuumAudienceManagementService"
architecture_ref: "components-continuum-ams-java-scheduler"
---

# SAD Integrity Check

## Summary

The SAD Integrity Check flow detects Scheduled Audience Definitions that have become stale — their next-materialized timestamps are overdue and have not been updated as expected by the normal SAD Materialization flow. For each stale SAD found, the runner calls the AMS REST API to reset the next-materialized timestamp, re-enabling the SAD for future materialization runs. This flow acts as a self-healing mechanism to prevent SADs from being permanently stuck.

## Trigger

- **Type**: schedule
- **Source**: `cron4j` scheduler fires the `SADIngegrityCheckAction` class (note: action class name contains a known typo: `Ingegrity`)
- **Frequency**: Nightly — NA and EMEA production at `16:00 UTC`; staging times vary by environment (e.g., `21:00 UTC` for NA staging sadintegrationcheck)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SAD Integrity Runner | Orchestrates stale SAD detection and timestamp reset | `amsScheduler_sadIntegrity` |
| AMS REST Client Adapter | Calls AMS APIs to find stale SADs and reset their materialization timestamps | `amsScheduler_amsRestClient` |
| Audience Management Service | Provides stale SAD search results and processes reset requests | `continuumAudienceManagementService` |

## Steps

1. **Cron Trigger**: `cron4j` fires the `SADIngegrityCheckAction` at the configured time (e.g., `00 16 * * *` in schedule-na.txt and schedule-emea.txt)
   - From: `amsScheduler_actionDispatchers`
   - To: `amsScheduler_sadIntegrity`
   - Protocol: Direct (in-process)

2. **Search for Stale SADs**: The AMS REST Client calls the AMS API to retrieve SADs whose next-materialized timestamp is overdue (i.e., the timestamp has passed without a materialization completing)
   - From: `amsScheduler_sadIntegrity` via `amsScheduler_amsRestClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP/JSON

3. **Evaluate Staleness**: The SAD Integrity Runner evaluates the list of returned SADs to confirm which ones qualify as stale based on configured criteria (timestamp age, SAD state)
   - From: `amsScheduler_sadIntegrity`
   - To: `amsScheduler_sadIntegrity` (in-process evaluation)
   - Protocol: Direct

4. **Reset Next Materialized Timestamp**: For each stale SAD, the AMS REST Client calls the AMS API to reset the `nextMaterializedAt` timestamp, bringing the SAD back into the active materialization window for the next scheduled SAD Materialization run
   - From: `amsScheduler_sadIntegrity` via `amsScheduler_amsRestClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP/JSON

5. **Job Complete**: The runner finishes processing all stale SADs; the pod exits normally
   - From: `amsScheduler_sadIntegrity`
   - To: Kubernetes CronJob controller (via pod exit code)
   - Protocol: Kubernetes pod lifecycle

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS stale SAD search API error | HTTP error logged; runner exits with failure | Pod fails; stale SADs remain stuck; next scheduled run retries the integrity check |
| AMS reset timestamp API error (one SAD) | Error logged per SAD; remaining SADs may still be reset | Partial reset possible; affected SAD remains stale until the next integrity check run |
| No stale SADs found | AMS returns empty list | Runner exits normally; this is a valid no-op state indicating the system is healthy |
| AMS completely unavailable | All API calls fail; runner exits with error | Pod fails; all stale SADs remain unresolved until AMS recovers and the next run executes |

## Sequence Diagram

```
cron4j -> SadIntegrityRunner: Fire SADIngegrityCheckAction
SadIntegrityRunner -> AmsRestClient: Search for stale SADs
AmsRestClient -> AudienceManagementService: GET stale SAD search
AudienceManagementService --> AmsRestClient: Stale SAD list
AmsRestClient --> SadIntegrityRunner: Stale SAD list
SadIntegrityRunner -> SadIntegrityRunner: Evaluate staleness criteria
SadIntegrityRunner -> AmsRestClient: Reset nextMaterializedAt (per stale SAD)
AmsRestClient -> AudienceManagementService: PUT/POST reset materialization timestamp
AudienceManagementService --> AmsRestClient: Reset confirmed
AmsRestClient --> SadIntegrityRunner: Success
SadIntegrityRunner --> cron4j: Job complete
```

## Related

- Architecture dynamic view: `components-continuum-ams-java-scheduler`
- Related flows: [Scheduler Startup and Schedule Loading](scheduler-startup.md), [SAD Materialization](sad-materialization.md)

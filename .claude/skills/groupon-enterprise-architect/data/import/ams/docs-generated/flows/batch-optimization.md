---
service: "ams"
title: "Batch Optimization"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "batch-optimization"
flow_type: batch
trigger: "Internal scheduler or queue manager evaluating pending audience job queue"
participants:
  - "ams_audienceOrchestration"
  - "ams_jobLaunchers"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
architecture_ref: "dynamic-ams-audience-calculation"
---

# Batch Optimization

## Summary

This flow optimizes the audience compute job queue by deduplicating pending compute requests and grouping compatible audience jobs before they are submitted to Livy Gateway. When multiple schedule triggers or API calls enqueue overlapping audience computation requests, the batch optimizer consolidates them to reduce unnecessary Spark job submissions and YARN resource consumption.

## Trigger

- **Type**: schedule (internal)
- **Source**: Internal Job Launchers queue manager, evaluated periodically before batch submission to Livy
- **Frequency**: Per batch submission cycle; runs ahead of Sourced Audience Calculation job dispatch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Orchestration | Coordinates batch queue evaluation lifecycle | `ams_audienceOrchestration` |
| Job Launchers | Owns the compute queue; performs deduplication and grouping | `ams_jobLaunchers` |
| Persistence Layer | Reads and updates pending job queue records | `ams_persistenceLayer` |
| Audience Management Database | Stores pending job queue and execution state | `continuumAudienceManagementDatabase` |

## Steps

1. **Trigger batch optimization cycle**: Job Launchers' queue manager fires on its configured interval to evaluate the pending job queue.
   - From: `ams_jobLaunchers` (internal scheduler)
   - To: `ams_persistenceLayer`
   - Protocol: In-process

2. **Load pending job queue**: Persistence Layer retrieves all pending audience compute requests from `continuumAudienceManagementDatabase`.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

3. **Deduplicate pending requests**: Job Launchers identifies duplicate compute requests for the same audience (e.g., from overlapping schedule triggers and API calls) and retains only the most recent or highest-priority request.
   - From: `ams_jobLaunchers`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

4. **Group compatible jobs**: Job Launchers groups compatible audience jobs that share input data sources or criteria, enabling combined Spark job submission where feasible.
   - From: `ams_jobLaunchers`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

5. **Update cancelled/merged queue entries**: Persistence Layer marks deduplicated or merged queue entries as cancelled in `continuumAudienceManagementDatabase` and writes the audit record.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

6. **Dispatch optimized job batch**: Job Launchers hands the optimized set of audience compute requests to Audience Orchestration for submission via the Sourced Audience Calculation flow.
   - From: `ams_jobLaunchers`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Queue read failure | Exception logged; optimization cycle skipped | Pending queue not processed this cycle; retried on next tick |
| Deduplication logic error | Exception isolated to job launcher | Unoptimized batch may be submitted; no data loss |
| Database update failure on cancellation | Exception logged; partial cancellation | Duplicate jobs may be submitted; detected and cleaned up on next cycle |

## Sequence Diagram

```
ams_jobLaunchers -> ams_persistenceLayer: load pending job queue
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT pending jobs
continuumAudienceManagementDatabase --> ams_persistenceLayer: pending job records
ams_persistenceLayer --> ams_jobLaunchers: job list
ams_jobLaunchers -> ams_jobLaunchers: deduplicate and group
ams_jobLaunchers -> ams_persistenceLayer: cancel merged/duplicate entries
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE status = cancelled + audit
ams_jobLaunchers -> ams_audienceOrchestration: dispatch optimized batch
ams_audienceOrchestration -> [Sourced Audience Calculation flow]: submit jobs
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Audience Schedule Execution](audience-schedule-execution.md), [Sourced Audience Calculation](sourced-audience-calculation.md)

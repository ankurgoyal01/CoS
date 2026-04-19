---
service: "ams"
title: "Audience Schedule Execution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "audience-schedule-execution"
flow_type: scheduled
trigger: "Cron schedule — configured per audience via /schedule/* endpoints"
participants:
  - "ams_audienceOrchestration"
  - "ams_persistenceLayer"
  - "ams_jobLaunchers"
  - "continuumAudienceManagementDatabase"
architecture_ref: "dynamic-ams-audience-calculation"
---

# Audience Schedule Execution

## Summary

This flow manages the scheduled triggering of audience compute jobs based on persisted schedule definitions. AMS runs an internal scheduler that evaluates due schedules against the MySQL schedule table, identifies audiences requiring recalculation, and dispatches them into the audience computation pipeline. This is the primary mechanism by which recurring audience refreshes are executed without manual intervention.

## Trigger

- **Type**: schedule
- **Source**: Internal Dropwizard/JTier scheduler evaluating schedule records in `continuumAudienceManagementDatabase`
- **Frequency**: Per cron expression on each schedule definition; typically hourly or daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Orchestration | Drives schedule evaluation and dispatches compute jobs | `ams_audienceOrchestration` |
| Persistence Layer | Reads due schedules and updates last-run timestamps | `ams_persistenceLayer` |
| Job Launchers | Receives dispatched audience IDs and initiates compute | `ams_jobLaunchers` |
| Audience Management Database | Source of schedule definitions and compute state | `continuumAudienceManagementDatabase` |

## Steps

1. **Evaluate due schedules**: Audience Orchestration's internal scheduler fires on its configured interval and instructs the Persistence Layer to fetch all schedule records due for execution.
   - From: `ams_audienceOrchestration` (internal scheduler)
   - To: `ams_persistenceLayer`
   - Protocol: In-process

2. **Query due schedule records**: Persistence Layer queries `continuumAudienceManagementDatabase` for schedule records where the next-run time is past due.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

3. **Lock due schedules**: Persistence Layer marks identified schedule records as in-progress to prevent concurrent duplicate triggering.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

4. **Dispatch audience compute jobs**: Audience Orchestration iterates due schedules and dispatches each associated audience ID to Job Launchers.
   - From: `ams_audienceOrchestration`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

5. **Initiate Sourced Audience Calculation**: Job Launchers initiates the Sourced Audience Calculation flow for each dispatched audience.
   - From: `ams_jobLaunchers`
   - To: (see [Sourced Audience Calculation](sourced-audience-calculation.md))
   - Protocol: In-process

6. **Update schedule last-run timestamp**: Persistence Layer updates the schedule record with the current execution timestamp and calculates the next-run time.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Scheduler fires but no due schedules found | No-op; normal operation | No jobs dispatched |
| Schedule lock fails (concurrent execution) | Lock acquisition skipped | Duplicate execution prevented; schedule processed on next cycle |
| Audience compute dispatch fails | Exception logged; schedule record unlocked | Audience not computed this cycle; retried on next schedule evaluation |
| Database unavailable during schedule query | Exception propagated; scheduler cycle fails | All schedules skipped for this cycle; retried on next scheduler tick |

## Sequence Diagram

```
ams_audienceOrchestration -> ams_persistenceLayer: fetch due schedules
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT due schedules
continuumAudienceManagementDatabase --> ams_persistenceLayer: due schedule records
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE state = in-progress
ams_persistenceLayer --> ams_audienceOrchestration: schedule list
ams_audienceOrchestration -> ams_jobLaunchers: dispatch audience IDs
ams_jobLaunchers -> [Sourced Audience Calculation flow]: initiate compute
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE last-run + next-run
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Sourced Audience Calculation](sourced-audience-calculation.md), [Batch Optimization](batch-optimization.md)

---
service: "proximity-notification-service"
title: "Hotzone Batch Generation Flow"
generated: "2026-03-03"
type: flow
flow_name: "hotzone-batch-generation-flow"
flow_type: scheduled
trigger: "Quartz job scheduler fires HotzoneGeneratorJob on a configured schedule"
participants:
  - "continuumProximityNotificationService"
  - "continuumProximityNotificationPostgres"
architecture_ref: "dynamic-hotzone_batch_generation_flow"
---

# Hotzone Batch Generation Flow

## Summary

On a recurring schedule managed by Quartz, the `HotzoneGeneratorJob` executes the HotzoneGenerator batch process to produce or refresh Hotzone deal records in PostgreSQL. This flow keeps the active Hotzone deal inventory current by generating new deals from configured category campaigns and cleaning up expired entries. The batch job can also be triggered manually via the `POST /v1/proximity/location/hotzone/execute-batch-job` endpoint.

## Trigger

- **Type**: schedule (and manual trigger via API)
- **Source**: Quartz scheduler (`jtier-quartz-bundle`), backed by PostgreSQL (`jtier-quartz-postgres-migrations`)
- **Frequency**: Scheduled interval configured in the `quartz` section of the YAML config

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotzone Job Scheduler | Triggers the job on schedule | `continuumProximityNotificationService` / `hotzoneJobScheduler` component |
| Hotzone Workflow | Executes hotzone generation and cleanup logic | `continuumProximityNotificationService` / `hotzoneWorkflow` component |
| HotzoneGenerator library | Generates geospatial hotzone deal data from campaign configs | `com.groupon.utility.HotzoneGenerator` 1.25 (embedded library) |
| PostgreSQL | Reads campaign configurations; writes new hotzone deal records | `continuumProximityNotificationPostgres` |

## Steps

1. **Triggers batch job**: Quartz scheduler fires `HotzoneGeneratorJob` according to its cron schedule.
   - From: Quartz scheduler
   - To: `continuumProximityNotificationService` / Hotzone Job Scheduler
   - Protocol: in-process (Quartz thread pool)

2. **Reads campaign configurations**: The Hotzone Workflow loads active category campaigns from PostgreSQL to determine which hotzone deals to generate (categories, radii, audience targets, country codes).
   - From: Hotzone Workflow
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

3. **Executes HotzoneGenerator**: Invokes the `HotzoneGenerator` library (v1.25) with the campaign parameters to compute geospatial hotzone deal data.
   - From: Hotzone Workflow
   - To: HotzoneGenerator library (in-process)
   - Protocol: in-process / direct library call

4. **Writes new hotzone deals**: Persists the generated hotzone deal records (POI data, deal type, radius, audience, expiry) to PostgreSQL via the Persistence Layer.
   - From: Hotzone Workflow
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

5. **Deletes expired hotzones**: As part of the batch run (or via the `POST /v1/proximity/location/hotzone/delete-expired` endpoint), removes all hotzone deals whose `expires` timestamp has passed.
   - From: Hotzone Workflow
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

6. **Deletes auto campaigns (optional)**: If triggered via `POST /v1/proximity/location/hotzone/campaign/delete-auto`, removes all auto-generated campaigns before re-generating.
   - From: Hotzone Workflow
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HotzoneGenerator failure | Logged; job does not write partial data | Existing hotzone records remain unchanged |
| PostgreSQL write failure | JDBI exception propagated; logged | Batch partially applied; next run will retry |
| Quartz job scheduling error | Logged by Quartz framework | Job retried per Quartz misfire policy |

## Sequence Diagram

```
QuartzScheduler       -> HotzoneJobScheduler: fire HotzoneGeneratorJob
HotzoneJobScheduler   -> HotzoneWorkflow: execute batch generation
HotzoneWorkflow       -> PostgreSQL: read active campaigns
PostgreSQL            --> HotzoneWorkflow: campaign configurations
HotzoneWorkflow       -> HotzoneGeneratorLib: generate hotzone deals
HotzoneGeneratorLib   --> HotzoneWorkflow: generated hotzone deal set
HotzoneWorkflow       -> PostgreSQL: write new hotzone deals
HotzoneWorkflow       -> PostgreSQL: delete expired hotzone deals
```

## Related

- Architecture component: `hotzoneJobScheduler` within `continuumProximityNotificationService`
- Related flows: [Hotzone Management Flow](hotzone-management-flow.md)
- Manual trigger: `POST /v1/proximity/location/hotzone/execute-batch-job`
- HotzoneGenerator JAR check: `GET /v1/proximity/location/hotzone/check-hot-zone-jar`

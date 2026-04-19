---
service: "aes-service"
title: "Scheduled Audience Creation"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-audience-creation"
flow_type: synchronous
trigger: "POST /api/v1/scheduledAudiences REST call"
participants:
  - "aesApiResources"
  - "aesSchedulingEngine"
  - "aesDataAccessLayer"
  - "aesIntegrationClients"
  - "continuumAudienceExportPostgres"
  - "continuumCIAService"
architecture_ref: "components-continuumAudienceExportService"
---

# Scheduled Audience Creation

## Summary

When a marketing operator (via Display Wizard UI) or an internal system calls `POST /api/v1/scheduledAudiences`, AES creates a new audience record in its Postgres database, registers the audience with CIA (which owns the scheduling and segment definition), and schedules a Quartz cron trigger for the daily export job. The response returns the fully-populated `AESAudience` object with assigned ID, job status, and target list.

## Trigger

- **Type**: api-call
- **Source**: Display Wizard UI or internal automation calling `POST /api/v1/scheduledAudiences`
- **Frequency**: On demand (per new audience request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates the creation request | `aesApiResources` |
| Integration Clients | Calls CIA to create/retrieve the corresponding audience schedule | `aesIntegrationClients` |
| Scheduling Engine | Registers the Quartz cron trigger for the new audience | `aesSchedulingEngine` |
| Data Access Layer | Persists the new audience record to Postgres | `aesDataAccessLayer` |
| AES Postgres | Stores the new audience metadata row | `continuumAudienceExportPostgres` |
| CIA | Creates or retrieves the scheduled audience definition on the CIA side | `continuumCIAService` |

## Steps

1. **Receive creation request**: API receives `POST /api/v1/scheduledAudiences` with `AudienceRequestScheduled` body (name, ciaId, audienceType, targets, country, attributes).
   - From: Caller (Display Wizard / internal)
   - To: `aesApiResources`
   - Protocol: HTTPS/REST

2. **Register with CIA**: Calls CIA API to create or retrieve the corresponding `AMSScheduledAudience` (returns schedule timing, recurrence rule, cron expression, and Hive table reference).
   - From: `aesIntegrationClients`
   - To: `continuumCIAService`
   - Protocol: HTTPS/REST

3. **Persist audience record**: Inserts a new row in `aes_service.aes_metadata` with `jobStatus=IN_PROGRESS` (initial), `scheduleType=SCHEDULED`, and all resolved attributes.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

4. **Schedule Quartz job**: If `createJob=true` (default), registers a Quartz cron trigger using the cron expression resolved from CIA, associated with the new audience ID.
   - From: `aesSchedulingEngine`
   - To: Quartz scheduler (internal)
   - Protocol: internal

5. **Return audience record**: API responds with the created `AESAudience` JSON object including the assigned `id`, `jobStatus`, `scheduleType`, `targets`, and CIA-resolved metadata.
   - From: `aesApiResources`
   - To: Caller
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CIA API failure during registration | AES returns error; audience not created | Error logged as "Failed to create or update the scheduled audience in CIA"; caller retries |
| Postgres insert failure after CIA success | AES returns error; CIA audience record may be orphaned | Error logged as "Failed to create Scheduled Audience in AES"; manual DB insert required (see Runbook) |
| Quartz job creation failure after DB insert | Error logged as "Failed to create job for scheduled audience" | Audience exists in DB without a trigger; trigger can be recovered via `GET /api/v1/scheduledAudiences/recoverTriggers` |

## Sequence Diagram

```
Caller -> aesApiResources: POST /api/v1/scheduledAudiences {name, ciaId, audienceType, targets, ...}
aesApiResources -> aesIntegrationClients: Register audience with CIA
aesIntegrationClients -> continuumCIAService: Create/retrieve scheduled audience
continuumCIAService --> aesIntegrationClients: AMSScheduledAudience (cronExpression, hiveTable, ...)
aesIntegrationClients -> aesDataAccessLayer: Persist new AES audience record
aesDataAccessLayer -> continuumAudienceExportPostgres: INSERT aes_metadata row
aesApiResources -> aesSchedulingEngine: Schedule Quartz cron trigger
aesSchedulingEngine --> aesApiResources: Trigger registered
aesApiResources --> Caller: 200 AESAudience {id, jobStatus, scheduleType, ...}
```

## Related

- Related flows: [Scheduled Audience Export](scheduled-audience-export.md), [Audience Pause and Resume](audience-pause-resume.md)
- API reference: [API Surface](../api-surface.md)

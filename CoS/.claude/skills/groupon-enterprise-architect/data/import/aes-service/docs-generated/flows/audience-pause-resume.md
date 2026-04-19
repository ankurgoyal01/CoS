---
service: "aes-service"
title: "Audience Pause and Resume"
generated: "2026-03-03"
type: flow
flow_name: "audience-pause-resume"
flow_type: synchronous
trigger: "PUT /api/v1/scheduledAudiences/{id}/pause or /resume REST call"
participants:
  - "aesApiResources"
  - "aesSchedulingEngine"
  - "aesDataAccessLayer"
  - "aesIntegrationClients"
  - "continuumAudienceExportPostgres"
  - "continuumCIAService"
architecture_ref: "components-continuumAudienceExportService"
---

# Audience Pause and Resume

## Summary

Operators can suspend a scheduled audience to stop it from exporting to ad-network partners without deleting it, and later resume it to restart daily exports. On pause, AES deactivates the audience in CIA, pauses the Quartz trigger, and records the transition through the `PAUSING` → `PAUSED` job sub-status lifecycle. Resume reverses the process through `RESUMING` → active states, re-enabling the Quartz trigger and reactivating the CIA audience. An optional `target` query parameter restricts the action to a specific ad-network partner.

## Trigger

- **Type**: api-call
- **Source**: Display Wizard UI or internal operator calling `PUT /api/v1/scheduledAudiences/{id}/pause` or `PUT /api/v1/scheduledAudiences/{id}/resume`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives pause/resume request and orchestrates the lifecycle change | `aesApiResources` |
| Scheduling Engine | Pauses or resumes the Quartz cron trigger | `aesSchedulingEngine` |
| Integration Clients | Deactivates or reactivates the audience in CIA | `aesIntegrationClients` |
| Data Access Layer | Reads and writes audience `jobStatus` / `jobSubStatus` transitions | `aesDataAccessLayer` |
| AES Postgres | Stores audience lifecycle state | `continuumAudienceExportPostgres` |
| CIA | Receives deactivation/activation signal for the audience schedule | `continuumCIAService` |

## Steps — Pause

1. **Receive pause request**: API receives `PUT /api/v1/scheduledAudiences/{id}/pause` with optional `target` query parameter.
   - From: Caller
   - To: `aesApiResources`
   - Protocol: HTTPS/REST

2. **Update status to PAUSING**: Sets `jobSubStatus=PAUSING` in AES Postgres.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

3. **Deactivate audience in CIA**: Calls CIA to deactivate the corresponding scheduled audience, preventing CIA from generating new export triggers.
   - From: `aesIntegrationClients`
   - To: `continuumCIAService`
   - Protocol: HTTPS/REST

4. **Pause Quartz trigger**: Suspends the Quartz cron trigger associated with this audience ID.
   - From: `aesSchedulingEngine`
   - To: Quartz scheduler (internal)
   - Protocol: internal

5. **Copy paused table state**: Snapshots current audience table references (`COPY_PAUSED_TABLE` sub-status).
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

6. **Set status to PAUSED**: Sets `jobStatus=PAUSED`, `jobSubStatus=PAUSED`; sets `active=false`.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

7. **Return updated audience**: Responds with the updated `AESAudience` object.
   - From: `aesApiResources`
   - To: Caller
   - Protocol: HTTPS/REST

## Steps — Resume

1. **Receive resume request**: API receives `PUT /api/v1/scheduledAudiences/{id}/resume` with optional `target` query parameter.
   - From: Caller
   - To: `aesApiResources`
   - Protocol: HTTPS/REST

2. **Update status to RESUMING**: Sets `jobSubStatus=RESUMING` in AES Postgres.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

3. **Reactivate audience in CIA**: Calls CIA to reactivate the scheduled audience.
   - From: `aesIntegrationClients`
   - To: `continuumCIAService`
   - Protocol: HTTPS/REST

4. **Resume Quartz trigger**: Re-enables the Quartz cron trigger to resume daily firing.
   - From: `aesSchedulingEngine`
   - To: Quartz scheduler (internal)
   - Protocol: internal

5. **Set status to active**: Updates `jobStatus=SUCCESS`, `jobSubStatus=COMPLETED`; sets `active=true`.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

6. **Return updated audience**: Responds with the updated `AESAudience` object.
   - From: `aesApiResources`
   - To: Caller
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CIA deactivation fails during pause | Error logged as "Failed to pause the job for Scheduled Audience" | Audience not fully paused; Quartz trigger may still be active; retry API call |
| Quartz trigger pause fails | Error logged | Audience may continue to fire; recover via `GET /api/v1/scheduledAudiences/recoverTriggers` |
| CIA reactivation fails during resume | Error logged as "Failed to resume the job for Scheduled Audience" | Audience remains paused; retry API call |

## Sequence Diagram

```
Caller -> aesApiResources: PUT /api/v1/scheduledAudiences/{id}/pause
aesApiResources -> aesDataAccessLayer: Set jobSubStatus=PAUSING
aesDataAccessLayer -> continuumAudienceExportPostgres: UPDATE status
aesApiResources -> aesIntegrationClients: Deactivate audience in CIA
aesIntegrationClients -> continuumCIAService: Deactivate scheduled audience
aesApiResources -> aesSchedulingEngine: Pause Quartz trigger
aesApiResources -> aesDataAccessLayer: Set jobStatus=PAUSED, active=false
aesDataAccessLayer -> continuumAudienceExportPostgres: UPDATE final state
aesApiResources --> Caller: 200 AESAudience {jobStatus=PAUSED}
```

## Related

- Related flows: [Scheduled Audience Creation](scheduled-audience-creation.md), [Scheduled Audience Export](scheduled-audience-export.md)
- API reference: [API Surface](../api-surface.md)
- Runbook: [Runbook](../runbook.md)

---
service: "email_campaign_management"
title: "Campaign Archival and Audit"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "campaign-archival-audit"
flow_type: synchronous
trigger: "API call — DELETE /campaigns/:id or DELETE /programs/:id"
participants:
  - "continuumCampaignManagementService"
  - "cmApiRouter"
  - "cmCampaignOrchestration"
  - "cmProgramManagement"
  - "cmPersistenceAdapters"
  - "cmIntegrationClients"
  - "continuumCampaignManagementPostgres"
  - "expyExperimentationService"
architecture_ref: "components-continuum-campaign-cmProgramManagement"
---

# Campaign Archival and Audit

## Summary

This flow archives a campaign or program, transitioning it to an inactive state and preventing future sends. When a campaign is archived, the service updates its status in PostgreSQL and archives the associated Expy experiment to stop active A/B testing. Program archival similarly updates the program's status. Both operations are soft-deletes — records are retained in PostgreSQL for audit and reporting purposes.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator or tooling client calling `DELETE /campaigns/:id` (campaign archival) or `DELETE /programs/:id` (program archival)
- **Frequency**: On-demand (at campaign/program end-of-life)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates archival request | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound DELETE request | `cmApiRouter` |
| Campaign Orchestration | Executes campaign archival business logic | `cmCampaignOrchestration` |
| Program Orchestration | Executes program archival business logic | `cmProgramManagement` |
| Persistence Adapters | Reads entity state; writes archived status | `cmPersistenceAdapters` |
| External Integration Clients | Calls Expy to archive the associated experiment | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Persists archived status for audit record retention | `continuumCampaignManagementPostgres` |
| Expy Experimentation | Archives the A/B experiment tied to the campaign | `expyExperimentationService` (stub) |

## Steps

1. **Receives archival request**: Internal client submits `DELETE /campaigns/:id` or `DELETE /programs/:id`.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Routes to appropriate orchestration**: `cmApiRouter` routes campaign archival to `cmCampaignOrchestration` and program archival to `cmProgramManagement`.
   - From: `cmApiRouter`
   - To: `cmCampaignOrchestration` or `cmProgramManagement`
   - Protocol: in-process

3. **Reads current entity state**: The orchestration component reads the current campaign or program record from PostgreSQL to validate it exists and is in an archivable state (e.g., not already archived).
   - From: `cmCampaignOrchestration` or `cmProgramManagement` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

4. **Archives Expy experiment (campaign archival only)**: `cmCampaignOrchestration` calls Expy via `cmIntegrationClients` to archive the associated experiment, stopping any active A/B test assignment.
   - From: `cmIntegrationClients`
   - To: `expyExperimentationService`
   - Protocol: REST/HTTPS + `@grpn/expy.js` SDK

5. **Updates entity status to archived**: `cmPersistenceAdapters` performs a soft-delete by updating the campaign or program status to `archived` in PostgreSQL. The original record is retained.
   - From: `cmCampaignOrchestration` or `cmProgramManagement` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

6. **Returns archival confirmation**: `cmApiRouter` returns a success response to the caller confirming the archival.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign or program not found | `cmPersistenceAdapters` returns null; orchestration returns 404 | Archival rejected |
| Entity already archived | `cmCampaignOrchestration` or `cmProgramManagement` returns 409 Conflict | Archival rejected; idempotent behavior expected by caller |
| Expy archival failure | `cmIntegrationClients` returns error; PostgreSQL update may still proceed | Campaign marked archived in DB; Expy experiment may remain active — requires manual follow-up |
| PostgreSQL update failure | `cmPersistenceAdapters` propagates error | 500 returned; entity status not updated |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: DELETE /campaigns/:id
cmApiRouter -> cmCampaignOrchestration: route campaign archival
cmCampaignOrchestration -> cmPersistenceAdapters: read campaign record
cmPersistenceAdapters -> continuumCampaignManagementPostgres: SELECT * FROM campaigns WHERE id=:id
continuumCampaignManagementPostgres --> cmPersistenceAdapters: campaign record {status: active}
cmCampaignOrchestration -> cmIntegrationClients: archive Expy experiment
cmIntegrationClients -> expyExperimentationService: DELETE /experiments/{experiment_id}
expyExperimentationService --> cmIntegrationClients: {status: archived}
cmCampaignOrchestration -> cmPersistenceAdapters: soft-delete campaign
cmPersistenceAdapters -> continuumCampaignManagementPostgres: UPDATE campaigns SET status='archived' WHERE id=:id
continuumCampaignManagementPostgres --> cmPersistenceAdapters: ok
cmApiRouter --> campaignApiClients: 200 OK {campaign_id, status: archived}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Related flows: [Campaign Creation and Publish](campaign-creation-publish.md), [Campaign Update and Treatment Rollout](campaign-update-rollout.md), [Program Management](program-management.md)

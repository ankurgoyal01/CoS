---
service: "email_campaign_management"
title: "Campaign Creation and Publish"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "campaign-creation-publish"
flow_type: synchronous
trigger: "API call — POST /campaigns"
participants:
  - "continuumCampaignManagementService"
  - "cmApiRouter"
  - "cmCampaignOrchestration"
  - "cmPersistenceAdapters"
  - "cmIntegrationClients"
  - "continuumCampaignManagementPostgres"
  - "expyExperimentationService"
  - "gconfigService"
architecture_ref: "components-continuum-campaign-cmProgramManagement"
---

# Campaign Creation and Publish

## Summary

This flow creates a new campaign in CampaignManagement. An internal caller submits campaign metadata via `POST /campaigns`; the service validates the payload, resolves runtime configuration from GConfig, persists the campaign to PostgreSQL, and optionally registers an Expy experiment if the campaign includes A/B treatment variants. On success, the campaign is available for deal query association and send scheduling.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator or tooling client calling `POST /campaigns`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates campaign creation request | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound POST request | `cmApiRouter` |
| Campaign Orchestration | Executes campaign creation business logic | `cmCampaignOrchestration` |
| Persistence Adapters | Writes the new campaign record to PostgreSQL | `cmPersistenceAdapters` |
| External Integration Clients | Calls GConfig and Expy | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Persists campaign entity | `continuumCampaignManagementPostgres` |
| GConfig Service | Resolves runtime campaign configuration | `gconfigService` (stub) |
| Expy Experimentation | Registers A/B experiment for treatment variants | `expyExperimentationService` (stub) |

## Steps

1. **Receives campaign creation request**: Internal client submits `POST /campaigns` with campaign name, program association, business group, template, and optional treatment configuration.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Validates request payload**: `cmApiRouter` validates required fields and routes the request to `cmCampaignOrchestration`.
   - From: `cmApiRouter`
   - To: `cmCampaignOrchestration`
   - Protocol: in-process

3. **Resolves runtime configuration**: `cmCampaignOrchestration` calls GConfig via `cmIntegrationClients` to retrieve any runtime configuration values relevant to campaign creation (e.g., send limits, feature toggles).
   - From: `cmIntegrationClients`
   - To: `gconfigService`
   - Protocol: REST/HTTPS

4. **Persists campaign entity**: `cmCampaignOrchestration` directs `cmPersistenceAdapters` to write the new campaign record to PostgreSQL with status `draft` or `active`.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

5. **Registers Expy experiment (conditional)**: If the campaign includes A/B treatment configuration, `cmCampaignOrchestration` calls Expy via `cmIntegrationClients` to create the experiment and receive an experiment ID.
   - From: `cmIntegrationClients`
   - To: `expyExperimentationService`
   - Protocol: REST/HTTPS + `@grpn/expy.js` SDK

6. **Updates campaign with experiment ID (conditional)**: If Expy registration succeeded, `cmPersistenceAdapters` updates the campaign record in PostgreSQL with the experiment ID.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

7. **Returns campaign response**: `cmApiRouter` returns the created campaign payload (including ID and status) to the caller.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request payload | `cmApiRouter` returns 400 Bad Request | Campaign not created; caller receives validation error |
| GConfig unavailable | `cmIntegrationClients` returns error; defaults applied or request fails | Campaign creation may proceed with defaults or be blocked depending on config criticality |
| PostgreSQL write failure | `cmPersistenceAdapters` propagates error to `cmCampaignOrchestration` | 500 returned to caller; campaign not persisted |
| Expy registration failure | `cmIntegrationClients` returns error; campaign persisted without experiment ID | Campaign created but A/B treatment not activated; caller may retry treatment rollout via `POST /campaigns/:id/rolloutTemplateTreatment` |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: POST /campaigns {name, program_id, template, treatments}
cmApiRouter -> cmCampaignOrchestration: route campaign creation request
cmCampaignOrchestration -> cmIntegrationClients: resolve GConfig runtime values
cmIntegrationClients -> gconfigService: GET /config?keys=campaign.*
gconfigService --> cmIntegrationClients: {send_limit, feature_flags}
cmIntegrationClients --> cmCampaignOrchestration: resolved config
cmCampaignOrchestration -> cmPersistenceAdapters: write campaign record
cmPersistenceAdapters -> continuumCampaignManagementPostgres: INSERT INTO campaigns
continuumCampaignManagementPostgres --> cmPersistenceAdapters: campaign_id
cmCampaignOrchestration -> cmIntegrationClients: register Expy experiment (if treatments present)
cmIntegrationClients -> expyExperimentationService: POST /experiments {campaign_id, variants}
expyExperimentationService --> cmIntegrationClients: {experiment_id}
cmCampaignOrchestration -> cmPersistenceAdapters: update campaign with experiment_id
cmPersistenceAdapters -> continuumCampaignManagementPostgres: UPDATE campaigns SET experiment_id
continuumCampaignManagementPostgres --> cmPersistenceAdapters: ok
cmApiRouter --> campaignApiClients: 201 Created {campaign_id, status, experiment_id}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Related flows: [Campaign Update and Treatment Rollout](campaign-update-rollout.md), [Campaign Archival and Audit](campaign-archival-audit.md), [Campaign Send Execution](campaign-send-execution.md)

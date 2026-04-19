---
service: "email_campaign_management"
title: "Campaign Update and Treatment Rollout"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "campaign-update-rollout"
flow_type: synchronous
trigger: "API call — PUT /campaigns/:id or POST /campaigns/:id/rolloutTemplateTreatment"
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

# Campaign Update and Treatment Rollout

## Summary

This flow handles two closely related operations: updating an existing campaign's metadata and rolling out an A/B treatment variant. A standard update (`PUT /campaigns/:id`) modifies campaign configuration and persists changes to PostgreSQL. A treatment rollout (`POST /campaigns/:id/rolloutTemplateTreatment`) additionally updates the campaign template variant and registers or updates the associated experiment in Expy, enabling A/B testing at send time.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator or tooling client calling `PUT /campaigns/:id` (general update) or `POST /campaigns/:id/rolloutTemplateTreatment` (treatment rollout)
- **Frequency**: On-demand (at campaign configuration or optimization time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates campaign update or rollout request | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound request | `cmApiRouter` |
| Campaign Orchestration | Executes update/rollout business logic | `cmCampaignOrchestration` |
| Persistence Adapters | Reads existing campaign; writes updated record | `cmPersistenceAdapters` |
| External Integration Clients | Calls GConfig and Expy | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Stores updated campaign entity | `continuumCampaignManagementPostgres` |
| GConfig Service | Resolves runtime configuration for update validation | `gconfigService` (stub) |
| Expy Experimentation | Creates or updates A/B experiment for treatment variant | `expyExperimentationService` (stub) |

## Steps

1. **Receives update or rollout request**: Internal client submits `PUT /campaigns/:id` with updated metadata, or `POST /campaigns/:id/rolloutTemplateTreatment` with the new treatment variant definition.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Routes to campaign orchestration**: `cmApiRouter` validates the campaign ID, checks the request path, and routes to `cmCampaignOrchestration`.
   - From: `cmApiRouter`
   - To: `cmCampaignOrchestration`
   - Protocol: in-process

3. **Reads existing campaign state**: `cmCampaignOrchestration` reads the current campaign record from PostgreSQL via `cmPersistenceAdapters` to validate state transitions (e.g., cannot update an archived campaign).
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

4. **Resolves runtime configuration**: `cmCampaignOrchestration` calls GConfig via `cmIntegrationClients` to retrieve any runtime configuration values relevant to the update or rollout.
   - From: `cmIntegrationClients`
   - To: `gconfigService`
   - Protocol: REST/HTTPS

5. **Updates or creates Expy experiment (treatment rollout only)**: For `rolloutTemplateTreatment` requests, `cmCampaignOrchestration` calls Expy via `cmIntegrationClients` to create a new experiment (if none exists) or update the existing experiment with the new treatment variant definition.
   - From: `cmIntegrationClients`
   - To: `expyExperimentationService`
   - Protocol: REST/HTTPS + `@grpn/expy.js` SDK

6. **Persists updated campaign**: `cmPersistenceAdapters` writes the updated campaign record to PostgreSQL, including any new experiment ID and updated template variant.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

7. **Returns updated campaign response**: `cmApiRouter` returns the updated campaign payload to the caller.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign not found | `cmPersistenceAdapters` returns null; `cmCampaignOrchestration` returns 404 | Update rejected |
| Invalid state transition (e.g., updating archived campaign) | `cmCampaignOrchestration` returns 409 Conflict | Update rejected; caller must check campaign status |
| GConfig unavailable | Defaults applied or request fails | Update may proceed with defaults or be blocked |
| Expy update failure | `cmIntegrationClients` returns error | Treatment variant not activated in Expy; campaign metadata update may still be persisted |
| PostgreSQL write failure | `cmPersistenceAdapters` propagates error | 500 returned; campaign not updated |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: PUT /campaigns/:id {updated_fields} OR POST /campaigns/:id/rolloutTemplateTreatment {variant}
cmApiRouter -> cmCampaignOrchestration: route update/rollout request
cmCampaignOrchestration -> cmPersistenceAdapters: read current campaign state
cmPersistenceAdapters -> continuumCampaignManagementPostgres: SELECT * FROM campaigns WHERE id=:id
continuumCampaignManagementPostgres --> cmPersistenceAdapters: campaign record
cmCampaignOrchestration -> cmIntegrationClients: resolve GConfig values
cmIntegrationClients -> gconfigService: GET /config?keys=campaign.*
gconfigService --> cmIntegrationClients: {config values}
cmCampaignOrchestration -> cmIntegrationClients: create/update Expy experiment (rollout only)
cmIntegrationClients -> expyExperimentationService: PUT /experiments/{experiment_id} {variant_definition}
expyExperimentationService --> cmIntegrationClients: {experiment_id, status}
cmCampaignOrchestration -> cmPersistenceAdapters: write updated campaign
cmPersistenceAdapters -> continuumCampaignManagementPostgres: UPDATE campaigns SET ... WHERE id=:id
continuumCampaignManagementPostgres --> cmPersistenceAdapters: ok
cmApiRouter --> campaignApiClients: 200 OK {campaign_id, updated_fields, experiment_id}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Related flows: [Campaign Creation and Publish](campaign-creation-publish.md), [Campaign Archival and Audit](campaign-archival-audit.md)

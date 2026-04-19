---
service: "email_campaign_management"
title: "Program Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "program-management"
flow_type: synchronous
trigger: "API call — POST /programs or PUT /programs/:id"
participants:
  - "continuumCampaignManagementService"
  - "cmApiRouter"
  - "cmProgramManagement"
  - "cmPersistenceAdapters"
  - "cmIntegrationClients"
  - "continuumCampaignManagementPostgres"
  - "gconfigService"
  - "expyExperimentationService"
architecture_ref: "components-continuum-campaign-cmProgramManagement"
---

# Program Management

## Summary

Programs are logical groupings of campaigns used for send routing and priority ordering. This flow creates or updates a program, resolves any relevant runtime configuration from GConfig, manages priority ordering among programs within a business group, and optionally registers experimentation configuration via Expy. Program state is persisted to PostgreSQL and governs how campaigns are selected and sequenced during the send execution flow.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator or tooling client calling `POST /programs` (create) or `PUT /programs/:id` (update)
- **Frequency**: On-demand (at program setup or reconfiguration time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates program create or update request | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound request | `cmApiRouter` |
| Program Orchestration | Executes program lifecycle business logic and priority management | `cmProgramManagement` |
| Persistence Adapters | Reads/writes program entities and priority orderings | `cmPersistenceAdapters` |
| External Integration Clients | Calls GConfig and Expy | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Persists program entity and priority state | `continuumCampaignManagementPostgres` |
| GConfig Service | Resolves runtime program configuration values | `gconfigService` (stub) |
| Expy Experimentation | Registers or updates experimentation config for program-level A/B tests | `expyExperimentationService` (stub) |

## Steps

1. **Receives program creation or update request**: Internal client submits `POST /programs` with program name, business group association, and priority, or `PUT /programs/:id` with updated fields.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Routes to program orchestration**: `cmApiRouter` validates the request and routes to `cmProgramManagement`.
   - From: `cmApiRouter`
   - To: `cmProgramManagement`
   - Protocol: in-process

3. **Reads existing program state (update only)**: For updates, `cmProgramManagement` reads the current program record from PostgreSQL via `cmPersistenceAdapters` to validate the state transition.
   - From: `cmProgramManagement` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

4. **Resolves runtime configuration**: `cmProgramManagement` calls GConfig via `cmIntegrationClients` to retrieve runtime configuration values relevant to program operation (e.g., send frequency limits, eligibility rules).
   - From: `cmIntegrationClients`
   - To: `gconfigService`
   - Protocol: REST/HTTPS

5. **Manages priority ordering**: `cmProgramManagement` reads the current priority ordering for programs in the same business group from PostgreSQL and applies any priority adjustments required by the create or update operation.
   - From: `cmProgramManagement` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

6. **Registers or updates Expy experiment (conditional)**: If the program includes experimentation configuration, `cmProgramManagement` calls Expy via `cmIntegrationClients` to register or update the associated experiment.
   - From: `cmIntegrationClients`
   - To: `expyExperimentationService`
   - Protocol: REST/HTTPS + `@grpn/expy.js` SDK

7. **Persists program entity**: `cmPersistenceAdapters` writes the new or updated program record to PostgreSQL, including priority, business group association, and experiment ID if applicable.
   - From: `cmProgramManagement` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

8. **Returns program response**: `cmApiRouter` returns the created or updated program payload to the caller.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request payload | `cmApiRouter` or `cmProgramManagement` returns 400 | Program not created or updated |
| Program not found (update) | `cmPersistenceAdapters` returns null; `cmProgramManagement` returns 404 | Update rejected |
| GConfig unavailable | Defaults applied or request fails | Program creation may proceed with defaults or be blocked |
| Priority conflict | `cmProgramManagement` reorders priorities; returns updated priority list | Program created/updated with resolved priority |
| Expy registration failure | `cmIntegrationClients` returns error; program still persisted | Program created without experiment; experimentation not active |
| PostgreSQL write failure | `cmPersistenceAdapters` propagates error | 500 returned; program not persisted |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: POST /programs {name, business_group_id, priority}
cmApiRouter -> cmProgramManagement: route program creation request
cmProgramManagement -> cmPersistenceAdapters: read current programs in business group
cmPersistenceAdapters -> continuumCampaignManagementPostgres: SELECT programs WHERE business_group_id=:id ORDER BY priority
continuumCampaignManagementPostgres --> cmPersistenceAdapters: [{program_id, priority}]
cmProgramManagement -> cmIntegrationClients: resolve GConfig values
cmIntegrationClients -> gconfigService: GET /config?keys=program.*
gconfigService --> cmIntegrationClients: {send_frequency_limit, eligibility_rules}
cmProgramManagement -> cmIntegrationClients: register Expy experiment (if applicable)
cmIntegrationClients -> expyExperimentationService: POST /experiments {program_id, variants}
expyExperimentationService --> cmIntegrationClients: {experiment_id}
cmProgramManagement -> cmPersistenceAdapters: write program record with resolved priority
cmPersistenceAdapters -> continuumCampaignManagementPostgres: INSERT INTO programs {name, business_group_id, priority, experiment_id}
continuumCampaignManagementPostgres --> cmPersistenceAdapters: program_id
cmApiRouter --> campaignApiClients: 201 Created {program_id, priority, experiment_id}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Related flows: [Campaign Creation and Publish](campaign-creation-publish.md), [Campaign Archival and Audit](campaign-archival-audit.md), [Campaign Send Execution](campaign-send-execution.md)

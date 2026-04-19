---
service: "message-service"
title: "Campaign Creation and Approval"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-creation-and-approval"
flow_type: synchronous
trigger: "Campaign manager submits a new campaign via the admin UI or POST /api/message/add"
participants:
  - "messagingUiControllers"
  - "messagingApiControllers"
  - "messagingCampaignOrchestration"
  - "messagingIntegrationClients"
  - "messagingPersistenceAdapters"
  - "messagingEventPublishers"
  - "continuumAudienceManagementService"
  - "continuumTaxonomyService"
  - "gims"
  - "continuumMessagingMySql"
  - "messageBus"
architecture_ref: "dynamic-campaign-creation"
---

# Campaign Creation and Approval

## Summary

This flow covers the end-to-end lifecycle of creating a new messaging campaign: a campaign manager provides content, targeting rules, and audience configuration through the admin UI or the API; the service validates all inputs against upstream enrichment services; persists the campaign record; and on approval publishes a `CampaignMetaData` event to MBus for downstream consumers including EDW.

## Trigger

- **Type**: user-action / api-call
- **Source**: Campaign manager via `/campaign/*` UI (backed by `messagingUiControllers`) or directly via `POST /api/message/add` (`messagingApiControllers`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Manager (person) | Initiates campaign creation | — |
| UI Controllers | Receives UI form submission and routes to orchestration | `messagingUiControllers` |
| API Controllers | Receives API request and routes to orchestration | `messagingApiControllers` |
| Campaign Orchestration | Coordinates validation, enrichment, persistence, and publishing | `messagingCampaignOrchestration` |
| Integration Clients | Makes outbound calls to AMS, Taxonomy, GIMS | `messagingIntegrationClients` |
| Persistence Adapters | Writes campaign record to MySQL | `messagingPersistenceAdapters` |
| Event Publishers | Publishes CampaignMetaData to MBus on approval | `messagingEventPublishers` |
| AMS | Validates audience definition | `continuumAudienceManagementService` |
| Taxonomy Service | Provides taxonomy category references for targeting | `continuumTaxonomyService` |
| GIMS | Resolves and stores campaign image assets | `gims` |
| Messaging MySQL | Persists campaign record | `continuumMessagingMySql` |
| MBus | Receives published CampaignMetaData event | `messageBus` |

## Steps

1. **Receive creation request**: Campaign manager submits campaign details (content, targeting rules, audience ID, image assets, schedule).
   - From: Campaign Manager
   - To: `messagingUiControllers` or `messagingApiControllers`
   - Protocol: HTTP (Play Framework)

2. **Route to orchestration**: Controller passes the request payload to Campaign Orchestration for business logic processing.
   - From: `messagingUiControllers` / `messagingApiControllers`
   - To: `messagingCampaignOrchestration`
   - Protocol: Direct (in-process)

3. **Validate audience**: Campaign Orchestration calls AMS via Integration Clients to confirm the referenced audience definition is valid and exists.
   - From: `messagingCampaignOrchestration` -> `messagingIntegrationClients`
   - To: `continuumAudienceManagementService`
   - Protocol: REST

4. **Fetch taxonomy references**: Integration Clients retrieves taxonomy category data to validate targeting constraints.
   - From: `messagingIntegrationClients`
   - To: `continuumTaxonomyService`
   - Protocol: REST

5. **Resolve image assets**: If the campaign includes image content, Integration Clients uploads or resolves assets with GIMS.
   - From: `messagingIntegrationClients`
   - To: `gims`
   - Protocol: REST

6. **Persist campaign record**: Persistence Adapters writes the new campaign entity (status: DRAFT or PENDING_APPROVAL) to MySQL.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingMySql`
   - Protocol: JDBC

7. **Approval step**: An approver reviews the campaign via the admin UI. On approval, a separate request updates campaign status to APPROVED.
   - From: Approver (via `messagingUiControllers`)
   - To: `messagingCampaignOrchestration`
   - Protocol: HTTP

8. **Update campaign status**: Persistence Adapters writes the approved status to MySQL.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingMySql`
   - Protocol: JDBC

9. **Publish CampaignMetaData**: Event Publishers sends a `CampaignMetaData` event to MBus, notifying downstream consumers (including EDW) of the approved campaign.
   - From: `messagingEventPublishers` via `messagingIntegrationClients`
   - To: `messageBus`
   - Protocol: MBus

10. **Invalidate cache**: Persistence Adapters invalidates any Redis cache entries for the affected campaign or templates.
    - From: `messagingPersistenceAdapters`
    - To: `continuumMessagingRedis`
    - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS validation failure (audience not found) | Campaign Orchestration returns error to caller | Campaign not created; error response returned to manager |
| Taxonomy service unavailable | Integration Clients returns error; orchestration aborts | Campaign creation fails; retry required |
| GIMS upload failure | Image resolution fails; campaign creation may fail or proceed without image | Depends on whether image is required field |
| MySQL write failure | Persistence adapter exception propagates | Campaign not persisted; error returned to caller |
| MBus publish failure (post-approval) | Event publisher failure; campaign is already approved in MySQL | Campaign is live but downstream consumers (EDW) may not receive the event; retry or replay required |

## Sequence Diagram

```
CampaignManager -> messagingUiControllers: Submit campaign form
messagingUiControllers -> messagingCampaignOrchestration: Create campaign request
messagingCampaignOrchestration -> messagingIntegrationClients: Validate audience
messagingIntegrationClients -> continuumAudienceManagementService: GET audience/:id
continuumAudienceManagementService --> messagingIntegrationClients: Audience valid
messagingIntegrationClients -> continuumTaxonomyService: GET taxonomy refs
continuumTaxonomyService --> messagingIntegrationClients: Taxonomy data
messagingIntegrationClients -> gims: Upload image assets
gims --> messagingIntegrationClients: Image URLs resolved
messagingCampaignOrchestration -> messagingPersistenceAdapters: Write campaign (DRAFT)
messagingPersistenceAdapters -> continuumMessagingMySql: INSERT campaign
continuumMessagingMySql --> messagingPersistenceAdapters: OK
messagingCampaignOrchestration --> messagingUiControllers: Campaign created
messagingUiControllers --> CampaignManager: Success response

CampaignManager -> messagingUiControllers: Approve campaign
messagingUiControllers -> messagingCampaignOrchestration: Approve campaign request
messagingCampaignOrchestration -> messagingPersistenceAdapters: Write campaign (APPROVED)
messagingPersistenceAdapters -> continuumMessagingMySql: UPDATE campaign status
messagingCampaignOrchestration -> messagingEventPublishers: Publish CampaignMetaData
messagingEventPublishers -> messageBus: CampaignMetaData event
messagingCampaignOrchestration -> messagingPersistenceAdapters: Invalidate Redis cache
messagingPersistenceAdapters -> continuumMessagingRedis: DEL campaign keys
messagingCampaignOrchestration --> messagingUiControllers: Approved
messagingUiControllers --> CampaignManager: Approval confirmed
```

## Related

- Architecture dynamic view: `dynamic-campaign-creation`
- Related flows: [Cache Invalidation](cache-invalidation.md), [Audience Assignment Batch](audience-assignment-batch.md)
- Events published: see [Events](../events.md)

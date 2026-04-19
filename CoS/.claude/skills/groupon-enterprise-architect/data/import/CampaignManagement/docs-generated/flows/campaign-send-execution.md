---
service: "email_campaign_management"
title: "Campaign Send Execution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "campaign-send-execution"
flow_type: synchronous
trigger: "API call — POST /campaignsends"
participants:
  - "continuumCampaignManagementService"
  - "cmApiRouter"
  - "cmAudienceResolution"
  - "cmCampaignOrchestration"
  - "cmPersistenceAdapters"
  - "cmIntegrationClients"
  - "continuumCampaignManagementPostgres"
  - "continuumCampaignManagementRedis"
  - "rocketmanMessagingService"
  - "rtamsAudienceService"
  - "tokenService"
  - "googleCloudStorage"
architecture_ref: "components-continuum-campaign-cmProgramManagement"
---

# Campaign Send Execution

## Summary

This is the core high-volume flow in CampaignManagement, operating at 70M+ send scale. An internal orchestrator triggers a campaign send via `POST /campaignsends`; the service validates the request with a Rocketman preflight check, downloads deal assignment files from GCS, resolves the eligible audience via RTAMS, retrieves user device tokens, records the send in PostgreSQL, and returns the send record to the caller. The caller is responsible for handing off the resolved payload to Rocketman for actual message delivery.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator calling `POST /campaignsends`
- **Frequency**: On-demand (at send scheduling time); high-volume at campaign dispatch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates campaign send request | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound request | `cmApiRouter` |
| Audience and Send Resolution | Orchestrates audience resolution and send record creation | `cmAudienceResolution` |
| Campaign Orchestration | Validates campaign state and coordinates preflight | `cmCampaignOrchestration` |
| Persistence Adapters | Reads deal query state; writes send records | `cmPersistenceAdapters` |
| External Integration Clients | Calls Rocketman, RTAMS, Token Service, GCS | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Stores send records and campaign/deal-query state | `continuumCampaignManagementPostgres` |
| CampaignManagement Redis Cache | Serves cached deal query metadata | `continuumCampaignManagementRedis` |
| Rocketman Messaging Service | Validates send payload (preflight) | `rocketmanMessagingService` (stub) |
| RTAMS Audience Service | Resolves eligible audience members | `rtamsAudienceService` (stub) |
| Token Service | Retrieves user device token preferences | `tokenService` (stub) |
| Google Cloud Storage | Provides deal assignment files | `googleCloudStorage` (stub) |

## Steps

1. **Receives campaign send request**: Internal orchestrator submits `POST /campaignsends` with campaign ID, send type, and scheduling metadata.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Validates campaign state**: `cmApiRouter` routes to `cmCampaignOrchestration`, which reads campaign and deal query state from PostgreSQL (via `cmPersistenceAdapters`) to verify the campaign is in a sendable state.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

3. **Reads deal query metadata from cache**: `cmAudienceResolution` attempts to read deal query metadata from Redis. On cache hit, skips PostgreSQL read.
   - From: `cmAudienceResolution` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementRedis`
   - Protocol: Redis

4. **Runs preflight validation**: `cmCampaignOrchestration` calls `GET /preflight` against Rocketman via `cmIntegrationClients` to validate the send payload before committing.
   - From: `cmIntegrationClients`
   - To: `rocketmanMessagingService`
   - Protocol: REST/HTTPS

5. **Downloads deal assignment files**: `cmIntegrationClients` downloads deal assignment files from the GCS bucket (keyed by campaign ID and send date) to resolve the deal-to-audience mapping.
   - From: `cmIntegrationClients`
   - To: `googleCloudStorage`
   - Protocol: GCS API (HTTPS)

6. **Resolves audience via RTAMS**: `cmAudienceResolution` calls RTAMS via `cmIntegrationClients` with deal query parameters and deal assignment data to retrieve eligible audience members and their attributes.
   - From: `cmIntegrationClients`
   - To: `rtamsAudienceService`
   - Protocol: REST/HTTPS

7. **Retrieves device token preferences**: `cmAudienceResolution` calls Token Service via `cmIntegrationClients` for each resolved user to retrieve device token preferences for push targeting.
   - From: `cmIntegrationClients`
   - To: `tokenService`
   - Protocol: REST/HTTPS

8. **Records campaign send**: `cmPersistenceAdapters` writes the campaign send record to PostgreSQL with status, audience size, and send metadata.
   - From: `cmAudienceResolution` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

9. **Returns send record**: `cmApiRouter` returns the created send record (including send ID, audience size, and status) to the caller for delivery handoff to Rocketman.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign not in sendable state | `cmCampaignOrchestration` returns 409 Conflict | Send rejected; caller must resolve campaign state |
| Preflight validation fails | Rocketman returns error; send blocked | 502/400 returned to caller; no send record created |
| GCS file not found | `cmIntegrationClients` returns error | Send blocked; deal assignment unavailable |
| RTAMS unavailable | `cmIntegrationClients` returns error | Audience resolution fails; send blocked |
| Token Service unavailable | `cmIntegrationClients` returns error | Push token resolution fails; send may proceed for email-only or be blocked |
| Redis cache miss | `cmPersistenceAdapters` falls through to PostgreSQL | Slight latency increase; send proceeds normally |
| PostgreSQL write failure on send record | `cmPersistenceAdapters` propagates error | 500 returned; send record not persisted; caller must retry |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: POST /campaignsends {campaign_id, send_type}
cmApiRouter -> cmCampaignOrchestration: route send request
cmCampaignOrchestration -> cmPersistenceAdapters: read campaign + deal query state
cmPersistenceAdapters -> continuumCampaignManagementRedis: GET deal_query:{id}
continuumCampaignManagementRedis --> cmPersistenceAdapters: {cached metadata} (or miss)
cmPersistenceAdapters -> continuumCampaignManagementPostgres: SELECT campaign, deal_query (on miss)
continuumCampaignManagementPostgres --> cmPersistenceAdapters: campaign + deal_query records
cmCampaignOrchestration -> cmIntegrationClients: run preflight
cmIntegrationClients -> rocketmanMessagingService: GET /preflight {campaign_id, payload}
rocketmanMessagingService --> cmIntegrationClients: {valid: true}
cmAudienceResolution -> cmIntegrationClients: download deal assignment files
cmIntegrationClients -> googleCloudStorage: GET /bucket/campaign_{id}/deals.csv
googleCloudStorage --> cmIntegrationClients: deal assignment file
cmAudienceResolution -> cmIntegrationClients: resolve audience
cmIntegrationClients -> rtamsAudienceService: POST /audience {deal_query, deals}
rtamsAudienceService --> cmIntegrationClients: [{user_id, attributes}]
cmAudienceResolution -> cmIntegrationClients: retrieve device tokens
cmIntegrationClients -> tokenService: POST /tokens {user_ids}
tokenService --> cmIntegrationClients: [{user_id, token_preferences}]
cmAudienceResolution -> cmPersistenceAdapters: write campaign send record
cmPersistenceAdapters -> continuumCampaignManagementPostgres: INSERT INTO campaign_sends
continuumCampaignManagementPostgres --> cmPersistenceAdapters: send_id
cmApiRouter --> campaignApiClients: 201 Created {send_id, audience_size, status}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Note: Dynamic view `CampaignSendResolutionFlow` was omitted from the DSL because most participants (RTAMS, Token Service, Campaign API Clients) are stub-only in the federated workspace.
- Related flows: [Audience Targeting and Deal Query](audience-targeting-deal-query.md), [Campaign Creation and Publish](campaign-creation-publish.md)

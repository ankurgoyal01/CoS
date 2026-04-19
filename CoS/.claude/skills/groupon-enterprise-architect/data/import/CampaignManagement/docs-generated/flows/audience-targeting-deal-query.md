---
service: "email_campaign_management"
title: "Audience Targeting and Deal Query"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "audience-targeting-deal-query"
flow_type: synchronous
trigger: "API call — POST /dealqueries or PUT /dealqueries/:id"
participants:
  - "continuumCampaignManagementService"
  - "cmApiRouter"
  - "cmCampaignOrchestration"
  - "cmAudienceResolution"
  - "cmPersistenceAdapters"
  - "cmIntegrationClients"
  - "continuumCampaignManagementPostgres"
  - "continuumCampaignManagementRedis"
  - "continuumGeoPlacesService"
architecture_ref: "components-continuum-campaign-cmProgramManagement"
---

# Audience Targeting and Deal Query

## Summary

This flow creates or updates a deal query — the audience targeting rule set that determines which users and deals are eligible for a given campaign. The service receives a targeting definition, loads division metadata from GeoPlaces to resolve geographic scoping, persists the deal query to PostgreSQL, and caches the resolved deal query metadata in Redis to accelerate future audience resolution requests.

## Trigger

- **Type**: api-call
- **Source**: Internal campaign orchestrator calling `POST /dealqueries` (create) or `PUT /dealqueries/:id` (update)
- **Frequency**: On-demand (at campaign configuration time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign API Client | Initiates deal query creation/update | `campaignApiClients` (stub) |
| API Router and Handlers | Receives and routes the inbound request | `cmApiRouter` |
| Campaign Orchestration | Orchestrates deal query construction and validation | `cmCampaignOrchestration` |
| Audience and Send Resolution | Resolves audience metadata and deal query state | `cmAudienceResolution` |
| Persistence Adapters | Reads/writes deal query entities to PostgreSQL and Redis | `cmPersistenceAdapters` |
| External Integration Clients | Calls GeoPlaces for division metadata | `cmIntegrationClients` |
| CampaignManagement PostgreSQL | Persists deal query entity | `continuumCampaignManagementPostgres` |
| CampaignManagement Redis Cache | Caches resolved deal query metadata | `continuumCampaignManagementRedis` |
| GeoPlaces Service | Provides division and geographic metadata | `continuumGeoPlacesService` |

## Steps

1. **Receives deal query request**: Internal client submits `POST /dealqueries` or `PUT /dealqueries/:id` with targeting definition including deal types, division codes, and audience filters.
   - From: `campaignApiClients`
   - To: `continuumCampaignManagementService` (`cmApiRouter`)
   - Protocol: REST/HTTPS

2. **Routes to campaign orchestration**: `cmApiRouter` validates the request and routes to `cmCampaignOrchestration` for deal query handling.
   - From: `cmApiRouter`
   - To: `cmCampaignOrchestration`
   - Protocol: in-process

3. **Loads division metadata**: `cmCampaignOrchestration` calls GeoPlaces via `cmIntegrationClients` to retrieve division (geographic market) metadata for each division code referenced in the deal query.
   - From: `cmIntegrationClients`
   - To: `continuumGeoPlacesService`
   - Protocol: REST/HTTPS

4. **Validates and constructs deal query**: `cmCampaignOrchestration` merges the inbound targeting definition with the resolved division metadata to build the complete deal query record.
   - From: `cmCampaignOrchestration`
   - To: `cmCampaignOrchestration` (internal)
   - Protocol: in-process

5. **Persists deal query to PostgreSQL**: `cmPersistenceAdapters` writes the deal query record to `continuumCampaignManagementPostgres`.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementPostgres`
   - Protocol: PostgreSQL

6. **Caches resolved metadata in Redis**: `cmPersistenceAdapters` writes the resolved deal query metadata (including division data) to `continuumCampaignManagementRedis` for use by future audience resolution requests.
   - From: `cmCampaignOrchestration` -> `cmPersistenceAdapters`
   - To: `continuumCampaignManagementRedis`
   - Protocol: Redis

7. **Returns deal query response**: `cmApiRouter` returns the persisted deal query payload to the caller.
   - From: `continuumCampaignManagementService`
   - To: `campaignApiClients`
   - Protocol: REST/HTTPS JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid targeting definition | `cmApiRouter` or `cmCampaignOrchestration` returns 400 | Deal query not created; caller receives validation error |
| GeoPlaces unavailable | `cmIntegrationClients` returns error; division metadata unresolved | Deal query creation blocked; 502/503 returned to caller |
| PostgreSQL write failure | `cmPersistenceAdapters` propagates error | 500 returned to caller; deal query not persisted |
| Redis write failure | Cache write skipped; deal query still persisted | Deal query created; cache miss on next read (falls through to PostgreSQL) |

## Sequence Diagram

```
campaignApiClients -> cmApiRouter: POST /dealqueries {campaign_id, deal_types, divisions}
cmApiRouter -> cmCampaignOrchestration: route deal query request
cmCampaignOrchestration -> cmIntegrationClients: load division metadata
cmIntegrationClients -> continuumGeoPlacesService: GET /divisions?codes=[div1,div2]
continuumGeoPlacesService --> cmIntegrationClients: [{division_id, name, geo_bounds}]
cmIntegrationClients --> cmCampaignOrchestration: resolved division metadata
cmCampaignOrchestration -> cmPersistenceAdapters: write deal query record
cmPersistenceAdapters -> continuumCampaignManagementPostgres: INSERT INTO deal_queries
continuumCampaignManagementPostgres --> cmPersistenceAdapters: deal_query_id
cmCampaignOrchestration -> cmPersistenceAdapters: cache resolved metadata
cmPersistenceAdapters -> continuumCampaignManagementRedis: SET deal_query:{id} {resolved_metadata}
continuumCampaignManagementRedis --> cmPersistenceAdapters: ok
cmApiRouter --> campaignApiClients: 201 Created {deal_query_id, status}
```

## Related

- Architecture dynamic view: `components-continuum-campaign-cmProgramManagement`
- Related flows: [Campaign Creation and Publish](campaign-creation-publish.md), [Campaign Send Execution](campaign-send-execution.md)

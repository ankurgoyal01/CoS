---
service: "message-service"
title: "Cache Invalidation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cache-invalidation"
flow_type: synchronous
trigger: "Campaign state change (create, update, or approval) committed to MySQL"
participants:
  - "messagingCampaignOrchestration"
  - "messagingPersistenceAdapters"
  - "continuumMessagingMySql"
  - "continuumMessagingRedis"
architecture_ref: "dynamic-cache-invalidation"
---

# Cache Invalidation

## Summary

The Cache Invalidation flow ensures that the Redis cache for campaign and template data stays consistent with the MySQL system of record. Whenever a campaign is created, updated, or approved, Campaign Orchestration instructs the Persistence Adapters to delete the affected cache keys in `continuumMessagingRedis` after the MySQL write completes. On the next `/api/getmessages` or `/api/getemailmessages` request, the Persistence Adapters repopulate the cache from MySQL.

## Trigger

- **Type**: internal event (post-write side effect)
- **Source**: Completion of any campaign mutation operation — creation (`POST /api/message/add`), update (`POST /api/campaign/:id`), or approval (UI action)
- **Frequency**: Per campaign mutation; relatively low frequency compared to read traffic

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Orchestration | Orchestrates the write and triggers cache invalidation | `messagingCampaignOrchestration` |
| Persistence Adapters | Executes the MySQL write and the Redis cache key deletion | `messagingPersistenceAdapters` |
| Messaging MySQL | System of record for campaign data | `continuumMessagingMySql` |
| Messaging Redis Cache | Caches campaign and template data; entries invalidated here | `continuumMessagingRedis` |

## Steps

1. **Commit campaign change to MySQL**: Persistence Adapters writes the campaign update (new state, content, or approval status) to `continuumMessagingMySql`.
   - From: `messagingCampaignOrchestration` -> `messagingPersistenceAdapters`
   - To: `continuumMessagingMySql`
   - Protocol: JDBC

2. **Identify affected cache keys**: Campaign Orchestration determines which Redis cache keys are stale based on the campaign ID and type of change (campaign record, template, notification config).
   - From: `messagingCampaignOrchestration`
   - To: `messagingPersistenceAdapters`
   - Protocol: Direct (in-process)

3. **Delete stale cache entries**: Persistence Adapters issues DEL (or pattern-based expiry) commands to `continuumMessagingRedis` for the affected campaign and template keys.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingRedis`
   - Protocol: Redis protocol

4. **Cache repopulated on next read** (deferred): The next call to `GET /api/getmessages` or `GET /api/getemailmessages` triggers a cache miss, causing Persistence Adapters to reload fresh data from MySQL and populate the cache for subsequent requests.
   - From: `messagingPersistenceAdapters` (triggered by next read request)
   - To: `continuumMessagingMySql` then `continuumMessagingRedis`
   - Protocol: JDBC, then Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis DEL fails (Redis unavailable) | Cache invalidation silently fails; MySQL is still the source of truth | Stale data may be served until Redis recovers or TTL expires |
| MySQL write succeeds but Redis DEL fails | Inconsistency window between MySQL and Redis | Stale cached data served to clients; resolves on next TTL expiry or Redis recovery |
| MySQL write fails | Campaign Orchestration does not proceed to invalidation | No cache invalidation needed; no inconsistency introduced |

## Sequence Diagram

```
messagingCampaignOrchestration -> messagingPersistenceAdapters: writeCampaign(campaignId, newState)
messagingPersistenceAdapters -> continuumMessagingMySql: UPDATE/INSERT campaign
continuumMessagingMySql --> messagingPersistenceAdapters: OK
messagingCampaignOrchestration -> messagingPersistenceAdapters: invalidateCache(campaignId)
messagingPersistenceAdapters -> continuumMessagingRedis: DEL campaign:{campaignId}
continuumMessagingRedis --> messagingPersistenceAdapters: OK
messagingCampaignOrchestration --> caller: campaign written and cache invalidated

Note over messagingPersistenceAdapters: On next read: cache miss -> reload from MySQL -> repopulate Redis
```

## Related

- Architecture dynamic view: `dynamic-cache-invalidation`
- Related flows: [Campaign Creation and Approval](campaign-creation-and-approval.md), [Message Delivery — getmessages](message-delivery-getmessages.md)
- Data stores: see [Data Stores](../data-stores.md)

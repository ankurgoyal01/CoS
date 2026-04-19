---
service: "message-service"
title: "Message Delivery — getmessages"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-delivery-getmessages"
flow_type: synchronous
trigger: "Consumer client calls GET /api/getmessages with user context"
participants:
  - "messagingApiControllers"
  - "messagingCampaignOrchestration"
  - "messagingMessageDeliveryEngine"
  - "messagingPersistenceAdapters"
  - "continuumMessagingRedis"
  - "continuumMessagingBigtable"
  - "continuumMessagingCassandra"
  - "continuumMessagingMySql"
architecture_ref: "dynamic-message-delivery-getmessages"
---

# Message Delivery — getmessages

## Summary

This is the primary high-frequency read path of the CRM Message Service. A web or mobile client sends a request with user context; the Message Delivery Engine evaluates active campaigns against the user's assignments and targeting constraints; and the service returns a list of eligible message records (banners, notifications, inbox items) for the client to render. Redis caching reduces database load on this hot path.

## Trigger

- **Type**: api-call
- **Source**: Web frontend or mobile app client calling `GET /api/getmessages`
- **Frequency**: Per page load / per app session; high-frequency production traffic

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web/Mobile Client | Initiates message retrieval request | — |
| API Controllers | Receives and validates the inbound request | `messagingApiControllers` |
| Campaign Orchestration | Routes request to the delivery engine | `messagingCampaignOrchestration` |
| Message Delivery Engine | Evaluates constraints; selects eligible messages | `messagingMessageDeliveryEngine` |
| Persistence Adapters | Loads campaign data and user assignments | `messagingPersistenceAdapters` |
| Messaging Redis Cache | Serves cached campaign/template data on cache hit | `continuumMessagingRedis` |
| Messaging Bigtable | Primary source for user-campaign assignments (cloud) | `continuumMessagingBigtable` |
| Messaging Cassandra | Legacy source for user-campaign assignments | `continuumMessagingCassandra` |
| Messaging MySQL | Fallback / source of truth for campaign metadata | `continuumMessagingMySql` |

## Steps

1. **Receive message request**: Client sends `GET /api/getmessages` with user identifier and context parameters (division, channel, locale, etc.).
   - From: Web/Mobile Client
   - To: `messagingApiControllers`
   - Protocol: REST / HTTP

2. **Route to orchestration**: API Controllers delegates the retrieval request to Campaign Orchestration.
   - From: `messagingApiControllers`
   - To: `messagingCampaignOrchestration`
   - Protocol: Direct (in-process)

3. **Load active campaign list**: Persistence Adapters checks Redis for cached active campaign metadata.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingRedis`
   - Protocol: Redis protocol
   - Note: On cache hit, skips step 4; on cache miss, falls through to MySQL

4. **Fetch campaign metadata from MySQL** (cache miss path): Persistence Adapters reads active campaign records from MySQL and repopulates the Redis cache.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingMySql`
   - Protocol: JDBC

5. **Load user-campaign assignments**: Persistence Adapters reads the user's campaign assignments from Bigtable (primary) or Cassandra (legacy).
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingBigtable` / `continuumMessagingCassandra`
   - Protocol: GCP Bigtable API / CQL

6. **Evaluate targeting constraints**: Message Delivery Engine applies constraint rules (geo, taxonomy, scheduling, channel eligibility, experiment flags) against the loaded campaign and assignment data to determine eligible messages.
   - From: `messagingMessageDeliveryEngine`
   - To: `messagingPersistenceAdapters` (reads)
   - Protocol: Direct (in-process)

7. **Assemble response**: Campaign Orchestration collects the list of eligible messages and assembles the API response payload.
   - From: `messagingCampaignOrchestration`
   - To: `messagingApiControllers`
   - Protocol: Direct (in-process)

8. **Return messages to client**: API Controllers returns the JSON response with the eligible message list.
   - From: `messagingApiControllers`
   - To: Web/Mobile Client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Persistence Adapters falls back to MySQL for campaign data | Increased latency; service continues |
| Bigtable read failure (cloud) | Persistence Adapters may fall back to Cassandra if configured | Assignment data may be unavailable; empty message list returned |
| MySQL unavailable | Campaign metadata cannot be loaded | `/api/getmessages` returns empty or error response |
| No eligible messages | All active campaigns filtered out by constraint evaluation | Empty list returned (200 OK with empty payload) |

## Sequence Diagram

```
Client -> messagingApiControllers: GET /api/getmessages?userId=X&division=Y
messagingApiControllers -> messagingCampaignOrchestration: retrieveMessages(userId, context)
messagingCampaignOrchestration -> messagingMessageDeliveryEngine: evaluate(userId, context)
messagingMessageDeliveryEngine -> messagingPersistenceAdapters: loadActiveCampaigns()
messagingPersistenceAdapters -> continuumMessagingRedis: GET campaign:active
continuumMessagingRedis --> messagingPersistenceAdapters: [cache hit] campaign list
messagingPersistenceAdapters --> messagingMessageDeliveryEngine: campaign list
messagingMessageDeliveryEngine -> messagingPersistenceAdapters: loadUserAssignments(userId)
messagingPersistenceAdapters -> continuumMessagingBigtable: GET assignments/userId
continuumMessagingBigtable --> messagingPersistenceAdapters: assignment rows
messagingPersistenceAdapters --> messagingMessageDeliveryEngine: assignments
messagingMessageDeliveryEngine --> messagingCampaignOrchestration: eligible messages
messagingCampaignOrchestration --> messagingApiControllers: message list
messagingApiControllers --> Client: 200 OK { messages: [...] }
```

## Related

- Architecture dynamic view: `dynamic-message-delivery-getmessages`
- Related flows: [Email Campaign Execution](email-campaign-execution.md), [Cache Invalidation](cache-invalidation.md), [Audience Assignment Batch](audience-assignment-batch.md)

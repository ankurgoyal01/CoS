---
service: "message-service"
title: "Message Event Tracking"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-event-tracking"
flow_type: synchronous
trigger: "Consumer client calls POST /api/messageevent to record a user interaction"
participants:
  - "messagingApiControllers"
  - "messagingCampaignOrchestration"
  - "messagingPersistenceAdapters"
  - "continuumMessagingMySql"
  - "continuumMessagingBigtable"
  - "continuumMessagingCassandra"
architecture_ref: "dynamic-message-event-tracking"
---

# Message Event Tracking

## Summary

This flow records a user's interaction with a delivered message. When a user views, clicks, or dismisses a banner or notification, the client posts an event to `/api/messageevent`. The service validates the event, associates it with the relevant campaign and message assignment, and persists the interaction record. This data supports campaign performance analytics and can influence downstream re-targeting or frequency-capping logic.

## Trigger

- **Type**: api-call
- **Source**: Web frontend or mobile app calling `POST /api/messageevent` immediately after a user interaction
- **Frequency**: Per user interaction event; high-frequency in proportion to message impression volume

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web/Mobile Client | Sends the interaction event payload | — |
| API Controllers | Receives and validates the event request | `messagingApiControllers` |
| Campaign Orchestration | Validates event context and routes to persistence | `messagingCampaignOrchestration` |
| Persistence Adapters | Writes the event record to the appropriate datastore | `messagingPersistenceAdapters` |
| Messaging MySQL | Stores campaign-level event counters or records | `continuumMessagingMySql` |
| Messaging Bigtable | Stores per-user event data (cloud deployments) | `continuumMessagingBigtable` |
| Messaging Cassandra | Stores per-user event data (legacy deployments) | `continuumMessagingCassandra` |

## Steps

1. **Receive event request**: Client sends `POST /api/messageevent` with user ID, message/campaign ID, event type (view, click, dismiss), and timestamp.
   - From: Web/Mobile Client
   - To: `messagingApiControllers`
   - Protocol: REST / HTTP

2. **Validate event payload**: API Controllers validates required fields and routes to Campaign Orchestration.
   - From: `messagingApiControllers`
   - To: `messagingCampaignOrchestration`
   - Protocol: Direct (in-process)

3. **Validate campaign and message context**: Campaign Orchestration confirms the referenced campaign and message assignment exist and are active.
   - From: `messagingCampaignOrchestration`
   - To: `messagingPersistenceAdapters`
   - Protocol: Direct (in-process)

4. **Persist event record**: Persistence Adapters writes the interaction event to the datastore (Bigtable for user-level event data; MySQL for campaign-level counters).
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingBigtable` / `continuumMessagingCassandra` and/or `continuumMessagingMySql`
   - Protocol: GCP Bigtable API / CQL / JDBC

5. **Return acknowledgement**: API Controllers returns a success response to the client.
   - From: `messagingApiControllers`
   - To: Web/Mobile Client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid event payload (missing fields) | API Controllers returns 400 Bad Request | Event not recorded; client should not retry |
| Campaign/message reference not found | Orchestration returns error response | Event not recorded; indicates stale client-side message data |
| Bigtable write failure | Persistence adapter exception | Event not recorded; client receives error; interaction data lost for this event |
| MySQL write failure | Persistence adapter exception | Campaign counter not updated; client receives error |

## Sequence Diagram

```
Client -> messagingApiControllers: POST /api/messageevent { userId, campaignId, eventType }
messagingApiControllers -> messagingCampaignOrchestration: recordEvent(userId, campaignId, eventType)
messagingCampaignOrchestration -> messagingPersistenceAdapters: validateCampaignExists(campaignId)
messagingPersistenceAdapters -> continuumMessagingMySql: SELECT campaign WHERE id=X
continuumMessagingMySql --> messagingPersistenceAdapters: campaign record
messagingCampaignOrchestration -> messagingPersistenceAdapters: writeEvent(userId, campaignId, eventType)
messagingPersistenceAdapters -> continuumMessagingBigtable: UPSERT event row
continuumMessagingBigtable --> messagingPersistenceAdapters: OK
messagingCampaignOrchestration --> messagingApiControllers: event recorded
messagingApiControllers --> Client: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-message-event-tracking`
- Related flows: [Message Delivery — getmessages](message-delivery-getmessages.md)

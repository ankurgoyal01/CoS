---
service: "message-service"
title: "Email Campaign Execution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "email-campaign-execution"
flow_type: synchronous
trigger: "Email pipeline calls GET /api/getemailmessages to retrieve eligible messages for the email channel"
participants:
  - "messagingApiControllers"
  - "messagingCampaignOrchestration"
  - "messagingMessageDeliveryEngine"
  - "messagingIntegrationClients"
  - "messagingPersistenceAdapters"
  - "continuumEmailService"
  - "continuumMessagingRedis"
  - "continuumMessagingBigtable"
  - "continuumMessagingCassandra"
  - "continuumMessagingMySql"
architecture_ref: "dynamic-email-campaign-execution"
---

# Email Campaign Execution

## Summary

The Email Campaign Execution flow serves the email delivery channel. An email pipeline component calls `GET /api/getemailmessages` with user and context parameters; the service retrieves email-specific campaign metadata from Email Campaign Management, evaluates channel-specific targeting constraints using the Message Delivery Engine, and returns eligible email message records. This flow parallels the web/mobile `getmessages` flow but enriches responses with email-channel business-group metadata.

## Trigger

- **Type**: api-call
- **Source**: Email pipeline or Email Campaign Management system calling `GET /api/getemailmessages`
- **Frequency**: Per email send job; batch-scale during email campaign dispatch windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Email Pipeline | Initiates the request for email-eligible messages | — |
| API Controllers | Receives and validates the inbound request | `messagingApiControllers` |
| Campaign Orchestration | Routes to delivery engine; coordinates email enrichment | `messagingCampaignOrchestration` |
| Message Delivery Engine | Evaluates email-channel constraints; selects eligible messages | `messagingMessageDeliveryEngine` |
| Integration Clients | Fetches email campaign and business-group metadata from Email Campaign Mgmt | `messagingIntegrationClients` |
| Email Campaign Management | Provides email campaign and business-group metadata | `continuumEmailService` |
| Persistence Adapters | Loads campaign data and user assignments | `messagingPersistenceAdapters` |
| Messaging Redis Cache | Serves cached campaign/template data | `continuumMessagingRedis` |
| Messaging Bigtable | User-campaign assignment source (cloud) | `continuumMessagingBigtable` |
| Messaging Cassandra | User-campaign assignment source (legacy) | `continuumMessagingCassandra` |
| Messaging MySQL | Campaign metadata store | `continuumMessagingMySql` |

## Steps

1. **Receive email message request**: Email pipeline sends `GET /api/getemailmessages` with user ID, email campaign context, and locale.
   - From: Email Pipeline
   - To: `messagingApiControllers`
   - Protocol: REST / HTTP

2. **Route to orchestration**: API Controllers delegates to Campaign Orchestration for email-channel message retrieval.
   - From: `messagingApiControllers`
   - To: `messagingCampaignOrchestration`
   - Protocol: Direct (in-process)

3. **Fetch email campaign metadata**: Campaign Orchestration calls Email Campaign Management via Integration Clients to retrieve email campaign definitions and business-group metadata applicable to the request context.
   - From: `messagingCampaignOrchestration` -> `messagingIntegrationClients`
   - To: `continuumEmailService`
   - Protocol: REST

4. **Load active email-eligible campaigns**: Persistence Adapters reads active campaigns flagged for the email channel from Redis (cache) or MySQL (cache miss).
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingRedis` / `continuumMessagingMySql`
   - Protocol: Redis protocol / JDBC

5. **Load user-campaign assignments**: Persistence Adapters reads user-campaign assignments for the requesting user from Bigtable or Cassandra.
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingBigtable` / `continuumMessagingCassandra`
   - Protocol: GCP Bigtable API / CQL

6. **Evaluate email-channel constraints**: Message Delivery Engine applies email-specific constraint rules (opt-in status, business-group eligibility, channel flag, geo, frequency cap) and selects eligible messages.
   - From: `messagingMessageDeliveryEngine`
   - To: `messagingPersistenceAdapters` (reads)
   - Protocol: Direct (in-process)

7. **Assemble email response**: Campaign Orchestration merges email campaign metadata with selected message records and assembles the response payload.
   - From: `messagingCampaignOrchestration`
   - To: `messagingApiControllers`
   - Protocol: Direct (in-process)

8. **Return email messages to pipeline**: API Controllers returns the email-eligible message list.
   - From: `messagingApiControllers`
   - To: Email Pipeline
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email Campaign Management unavailable | Integration client exception; orchestration may return partial data | Email messages returned without business-group enrichment, or empty response |
| No email-eligible campaigns | All campaigns filtered by email-channel constraint evaluation | Empty list returned (200 OK) |
| Bigtable/Cassandra read failure | Assignment data unavailable | Empty or degraded message list returned |
| Redis unavailable | Falls back to MySQL for campaign metadata | Increased latency; flow continues |

## Sequence Diagram

```
EmailPipeline -> messagingApiControllers: GET /api/getemailmessages?userId=X&locale=en-US
messagingApiControllers -> messagingCampaignOrchestration: retrieveEmailMessages(userId, context)
messagingCampaignOrchestration -> messagingIntegrationClients: getEmailCampaignMetadata(context)
messagingIntegrationClients -> continuumEmailService: GET /email-campaigns?businessGroup=Y
continuumEmailService --> messagingIntegrationClients: email campaign metadata
messagingCampaignOrchestration -> messagingMessageDeliveryEngine: evaluateEmailChannel(userId, context)
messagingMessageDeliveryEngine -> messagingPersistenceAdapters: loadActiveCampaigns(channel=email)
messagingPersistenceAdapters -> continuumMessagingRedis: GET campaign:email:active
continuumMessagingRedis --> messagingPersistenceAdapters: campaign list
messagingMessageDeliveryEngine -> messagingPersistenceAdapters: loadUserAssignments(userId)
messagingPersistenceAdapters -> continuumMessagingBigtable: GET assignments/userId
continuumMessagingBigtable --> messagingPersistenceAdapters: assignment rows
messagingMessageDeliveryEngine --> messagingCampaignOrchestration: eligible email messages
messagingCampaignOrchestration --> messagingApiControllers: email message list
messagingApiControllers --> EmailPipeline: 200 OK { messages: [...] }
```

## Related

- Architecture dynamic view: `dynamic-email-campaign-execution`
- Related flows: [Message Delivery — getmessages](message-delivery-getmessages.md), [Campaign Creation and Approval](campaign-creation-and-approval.md)
- Integrations: see [Integrations](../integrations.md)

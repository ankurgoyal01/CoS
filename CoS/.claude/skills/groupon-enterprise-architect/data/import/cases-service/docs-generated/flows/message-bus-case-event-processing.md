---
service: "cases-service"
title: "Message Bus Case Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "message-bus-case-event-processing"
flow_type: asynchronous
trigger: "Salesforce publishes a case lifecycle event to a JMS topic on the Groupon message bus"
participants:
  - "salesForce"
  - "messageBus"
  - "continuumMerchantCaseService"
  - "cases_notificationProcessing"
  - "cases_domainServices"
  - "cases_knowledgeAndCache"
  - "continuumMerchantCaseRedis"
  - "mxNotificationService"
architecture_ref: "dynamic-cases-case-flow"
---

# Message Bus Case Event Processing

## Summary

Salesforce publishes case lifecycle events to JMS topics on the Groupon message bus whenever a case is created, updated, or has a case event. MCS subscribes to six topics and processes these events asynchronously. On receiving a case create or update event, MCS refreshes the merchant's unread case count in Redis and dispatches a web notification to the merchant via the MX Notification Service. Certain notification types (`CASE_EVENT_REMINDER_1`, `CASE_EVENT_REMINDER_2`) are suppressed based on configuration. Account and opportunity update events are consumed for merchant context synchronization.

## Trigger

- **Type**: event
- **Source**: Salesforce publishes events to Groupon message bus JMS topics
- **Frequency**: Per case lifecycle event (real-time, event-driven)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Salesforce CRM | Publishes case events to the message bus | `salesForce` |
| Message Bus (JMS/STOMP) | Event transport layer; topics subscribed by MCS | `messageBus` |
| Notification Processing | JMS consumer; receives and dispatches events | `cases_notificationProcessing` |
| Case Domain Services | Processes event payload and determines notification actions | `cases_domainServices` |
| Knowledge and Cache Management | Refreshes Redis unread counts | `cases_knowledgeAndCache` |
| Merchant Cases Redis | Stores updated unread case counts | `continuumMerchantCaseRedis` |
| MX Notification Service | Delivers web/push notification to merchant | `mxNotificationService` |

## Steps

1. **Receive message bus event**: Notification Processing's JMS consumer receives a message from one of the six subscribed topics (e.g., `jms.topic.salesforce.case.create`).
   - From: `messageBus`
   - To: `cases_notificationProcessing`
   - Protocol: JMS/STOMP (port 61613)

2. **Log received message**: Notification Processing logs the raw message via `MessageConsumerReceivedMessageLogData`.
   - From: `cases_notificationProcessing`
   - To: Steno log
   - Protocol: direct

3. **Parse and validate event payload**: Notification Processing deserializes the message body and validates required fields. Null or invalid messages are logged via `MessageConsumerReceivedNullMessageLogData` and discarded.
   - From: `cases_notificationProcessing`
   - To: `cases_domainServices`
   - Protocol: direct (in-process)

4. **Check notification type filter**: For `jms.topic.salesforce.caseevent.create`, Domain Services checks whether the notification type is in `casesConfig.excludedWebNotificationTypes`. If it matches `CASE_EVENT_REMINDER_1` or `CASE_EVENT_REMINDER_2`, the event is dropped.
   - From: `cases_domainServices`
   - To: internal config
   - Protocol: direct

5. **Refresh unread count in Redis**: For case create and update events, Knowledge and Cache Management increments or recalculates the unread count for the relevant merchant in Redis.
   - From: `cases_knowledgeAndCache`
   - To: `continuumMerchantCaseRedis`
   - Protocol: Redis

6. **Dispatch merchant notification**: Domain Services calls MX Notification Service with an `EchoNotificationPayload` or `CaseEventNotificationPayload` to deliver a web/push notification to the merchant.
   - From: `cases_integrationClients`
   - To: `mxNotificationService`
   - Protocol: REST

7. **Log processing outcome**: Domain Services logs the notification dispatch result via `ProcessNotificationEventLogData` or `ProcessCaseEventNotificationLogData`.
   - From: `cases_domainServices`
   - To: Steno log
   - Protocol: direct

## Topics and Their Processing

| JMS Topic | Durable (prod) | Processing |
|-----------|---------------|-----------|
| `jms.topic.salesforce.case.create` | yes | Refresh Redis unread count + dispatch notification |
| `jms.topic.salesforce.case.update` | yes | Refresh Redis unread count + dispatch notification |
| `jms.topic.salesforce.caseevent.create` | yes | Filter by notification type + dispatch notification |
| `jms.topic.salesforce.opportunity.detailed_update` | no | Process opportunity state for merchant context |
| `jms.topic.salesforce.mcnotifications.create` | yes | Dispatch MC notification to merchant via Nots |
| `jms.topic.salesforce.account.update` | yes | Synchronize account state |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Null/invalid message payload | Log via `MessageConsumerReceivedNullMessageLogData` and discard | Event dropped; no side effects |
| Redis refresh fails | Logged via `RefreshCountErrorLogData` | Count temporarily stale; repopulated on next event |
| Nots call fails | Logged via `NotsErrorLogData` | Notification not delivered; case data unaffected |
| Unparseable message | Logged via `MessagesConsumerErrorLogData` | Event dropped |

## Sequence Diagram

```
Salesforce -> messageBus: publish to jms.topic.salesforce.case.create
messageBus -> cases_notificationProcessing: deliver JMS message
cases_notificationProcessing -> cases_domainServices: process case create event
cases_domainServices -> cases_knowledgeAndCache: refresh unread count
cases_knowledgeAndCache -> Redis: INCR unread:{merchantUuid}
Redis --> cases_knowledgeAndCache: OK
cases_domainServices -> cases_integrationClients: dispatch notification
cases_integrationClients -> MXNotificationService: POST notification {merchantUuid, caseNumber}
MXNotificationService --> cases_integrationClients: acknowledged
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Creation](case-creation.md), [Case Retrieval](case-retrieval.md)

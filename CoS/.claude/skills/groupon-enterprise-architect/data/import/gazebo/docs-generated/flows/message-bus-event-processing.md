---
service: "gazebo"
title: "Message Bus Event Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-bus-event-processing"
flow_type: asynchronous
trigger: "Incoming event arrives on a subscribed Message Bus topic"
participants:
  - "continuumGazeboMbusConsumer"
  - "continuumGazeboMysql"
  - "mbusSystem_18ea34"
architecture_ref: "dynamic-gazebo-message-bus-event-processing"
---

# Message Bus Event Processing

## Summary

The `continuumGazeboMbusConsumer` container maintains persistent subscriptions to multiple Message Bus topics. When events arrive, the Event Router inspects the topic and event type and dispatches the payload to the appropriate domain handler. Each handler updates the relevant MySQL records to keep Gazebo's local data synchronized with the rest of the Continuum platform.

## Trigger

- **Type**: event
- **Source**: Upstream Continuum services and Salesforce-derived pipelines publishing to `mbusSystem_18ea34`
- **Frequency**: continuous (the consumer runs as a long-lived process)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream event producers | Publish deal, task, and notification events | `mbusSystem_18ea34` |
| Message Bus | Routes events to subscribed consumers | `mbusSystem_18ea34` |
| Gazebo MBus Consumer | Receives events and routes to handlers | `continuumGazeboMbusConsumer` |
| Gazebo MySQL | Stores the processed event outcomes | `continuumGazeboMysql` |

## Steps

1. **Event published by upstream producer**: An upstream service publishes one of the subscribed event types (`deal.updated`, `opportunity.changed`, `goods_task`, `task_notification`, `contract_stage_notification`, `information_request_notification`) to Message Bus.
   - From: `Upstream producer`
   - To: `mbusSystem_18ea34`
   - Protocol: message-bus

2. **Message Bus delivers event**: The Message Bus delivers the event to the `continuumGazeboMbusConsumer` subscription.
   - From: `mbusSystem_18ea34`
   - To: `continuumGazeboMbusConsumer`
   - Protocol: message-bus

3. **Event Router inspects topic and type**: The Event Router component within the consumer reads the topic and event type to determine which handler to invoke.
   - From: `continuumGazeboMbusConsumer` (Event Router)
   - To: `continuumGazeboMbusConsumer` (handler selection)
   - Protocol: direct

4. **Handler processes event**: The appropriate handler processes the event payload:
   - `deal.updated` -> Deal Updated Handler: updates local deal record fields
   - `opportunity.changed` -> Opportunity Changed Handler: maps CRM opportunity changes to deal records
   - `goods_task` / `task_notification` -> Task Notification Handler: creates or updates task records
   - `contract_stage_notification` / `information_request_notification` -> Contract/Info Request Handler: updates contract and info request records
   - From: `continuumGazeboMbusConsumer` (handler)
   - To: `continuumGazeboMbusConsumer` (handler)
   - Protocol: direct

5. **MySQL record updated**: The handler writes the processed data to the relevant table(s) in MySQL (`deals`, `tasks`, `outbound_messages`, or related tables).
   - From: `continuumGazeboMbusConsumer`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

6. **Acknowledgement returned to broker**: The consumer acknowledges the event to the Message Bus, advancing the subscription offset.
   - From: `continuumGazeboMbusConsumer`
   - To: `mbusSystem_18ea34`
   - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unrecognized event type | Event Router logs a warning and discards the event | Event not processed; no MySQL writes |
| Handler throws exception | Exception caught at consumer level; event may be nacked | Event may be redelivered by broker (at-least-once); handler should be idempotent |
| MySQL connection failure | Database exception raised; event nacked | Event redelivered after broker timeout; MySQL backlog accumulates until connection restores |
| Malformed payload (schema mismatch) | Handler logs error and skips processing | Event discarded; no side effects |
| Duplicate event delivery | Handlers apply update-on-receipt; no explicit dedup key | Duplicate writes are benign for idempotent UPDATE operations; INSERT operations may create duplicates |

## Sequence Diagram

```
UpstreamProducer -> mbusSystem_18ea34: publish event (deal.updated / opportunity.changed / goods_task / task_notification / contract_stage_notification / information_request_notification)
mbusSystem_18ea34 -> continuumGazeboMbusConsumer: deliver event
continuumGazeboMbusConsumer -> continuumGazeboMbusConsumer: Event Router inspects topic + type
continuumGazeboMbusConsumer -> continuumGazeboMbusConsumer: dispatch to handler (Deal / Opportunity / Task / Contract)
continuumGazeboMbusConsumer -> continuumGazeboMysql: write updated record (deals / tasks / info_requests / etc.)
continuumGazeboMysql --> continuumGazeboMbusConsumer: write confirmation
continuumGazeboMbusConsumer -> mbusSystem_18ea34: acknowledge event
```

## Related

- Architecture dynamic view: `dynamic-gazebo-message-bus-event-processing`
- Related flows: [Task Management](task-management.md), [Editorial Copy Creation](editorial-copy-creation.md), [Salesforce Data Sync](salesforce-data-sync.md)

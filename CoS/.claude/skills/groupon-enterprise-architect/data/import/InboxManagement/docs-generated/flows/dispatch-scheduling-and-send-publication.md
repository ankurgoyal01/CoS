---
service: "inbox_management_platform"
title: "Dispatch Scheduling and Send Publication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "dispatch-scheduling-and-send-publication"
flow_type: event-driven
trigger: "Dispatch-ready user-campaign entry available in Redis dispatch queue"
participants:
  - "inbox_dispatchScheduler"
  - "inbox_rocketmanPublisher"
  - "continuumInboxManagementRedis"
  - "continuumInboxManagementPostgres"
architecture_ref: "dynamic-inbox-core-coordination"
---

# Dispatch Scheduling and Send Publication

## Summary

Once the coordination workflow has promoted eligible user-campaign pairs to the Redis dispatch queue, the dispatch scheduling flow takes over. The Dispatch Scheduler dequeues entries, applies final send-time scheduling logic, and hands them to the RocketMan Publisher, which serializes and produces a SendEvent to the Kafka topic consumed by RocketMan for actual channel delivery. This is the final step within InboxManagement before responsibility transfers to RocketMan.

## Trigger

- **Type**: event (queue-driven)
- **Source**: `inbox_coordinationWorker` writes dispatch-ready entries to the Redis dispatch queue
- **Frequency**: Continuous; the dispatcher daemon polls the dispatch queue and processes entries as they arrive

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dispatch Scheduler | Dequeues dispatch-ready entries, applies scheduling logic, and drives publication | `inbox_dispatchScheduler` |
| RocketMan Publisher | Serializes dispatch payloads and produces SendEvents to the RocketMan Kafka topic | `inbox_rocketmanPublisher` |
| Inbox Management Redis | Hosts the dispatch queue | `continuumInboxManagementRedis` |
| Inbox Management Postgres | Provides throttle rates and runtime config for dispatch | `continuumInboxManagementPostgres` |

## Steps

1. **Dequeue dispatch entry**: Dispatch Scheduler reads eligible entries from the Redis dispatch queue (sorted set by scheduled send time).
   - From: `inbox_dispatchScheduler`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

2. **Read throttle config**: Dispatch Scheduler reads current throttle rates from Postgres to ensure send rates stay within limits.
   - From: `inbox_dispatchScheduler`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

3. **Apply scheduling logic**: Scheduler validates send time eligibility, applies per-channel throttle rates, and determines final dispatch order.
   - From: `inbox_dispatchScheduler`
   - To: `inbox_dispatchScheduler` (internal decision)
   - Protocol: Internal

4. **Emit dispatch payloads to publisher**: Scheduler passes finalized dispatch payloads to the RocketMan Publisher.
   - From: `inbox_dispatchScheduler`
   - To: `inbox_rocketmanPublisher`
   - Protocol: Internal

5. **Serialize SendEvent**: RocketMan Publisher serializes the dispatch payload into a SendEvent using gson.
   - From: `inbox_rocketmanPublisher`
   - To: `inbox_rocketmanPublisher` (internal)
   - Protocol: Internal

6. **Produce SendEvent to Kafka**: Publisher produces the serialized SendEvent to the RocketMan Kafka dispatch topic.
   - From: `inbox_rocketmanPublisher`
   - To: RocketMan Kafka topic
   - Protocol: Kafka

7. **RocketMan consumes and delivers**: RocketMan reads the SendEvent from Kafka and executes channel delivery (email/push/SMS).
   - From: RocketMan Kafka topic
   - To: RocketMan (external)
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis dispatch queue unavailable | Dispatcher halts; retries on reconnection | Processing pauses; queue depth alert fires |
| Throttle limit reached | Dispatcher backs off; entries remain in queue | Send delayed until throttle window resets |
| Kafka producer error | Retry with Kafka producer retry config | Event re-attempted; alert if persistent |
| Serialization error | Event dropped and logged as error | Send lost; error metric incremented |
| RocketMan consumer lag | No direct handling in InboxManagement; queue depth rises | `inbox_queueMonitor` alerts on dispatch queue depth |

## Sequence Diagram

```
inbox_dispatchScheduler -> continuumInboxManagementRedis: Dequeue dispatch entry
inbox_dispatchScheduler -> continuumInboxManagementPostgres: Read throttle config (JDBC)
inbox_dispatchScheduler -> inbox_rocketmanPublisher: Emit dispatch payload
inbox_rocketmanPublisher -> RocketManKafkaTopic: Produce SendEvent (Kafka)
RocketManKafkaTopic --> RocketMan: SendEvent consumed
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Calculation Coordination Workflow](calculation-coordination-workflow.md), [Queue Monitoring and Health Checks](queue-monitoring-and-health-checks.md)
- See also: [Events](../events.md) for SendEvent details

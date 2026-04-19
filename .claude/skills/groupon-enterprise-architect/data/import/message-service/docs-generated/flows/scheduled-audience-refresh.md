---
service: "message-service"
title: "Scheduled Audience Refresh"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-audience-refresh"
flow_type: event-driven
trigger: "ScheduledAudienceRefreshed event consumed from Kafka"
participants:
  - "messagingKafkaConsumers"
  - "messagingAudienceImportJobs"
  - "messageBus"
architecture_ref: "dynamic-scheduled-audience-refresh"
---

# Scheduled Audience Refresh

## Summary

This event-driven flow describes how the CRM Message Service reacts to an audience refresh signal from the Kafka message bus. When a `ScheduledAudienceRefreshed` event arrives on the configured Kafka topic, `messagingKafkaConsumers` parses the event and dispatches the audience ID to `messagingAudienceImportJobs` for asynchronous processing. This flow is the entry point into the [Audience Assignment Batch](audience-assignment-batch.md) pipeline.

## Trigger

- **Type**: event
- **Source**: Kafka topic carrying `ScheduledAudienceRefreshed` events (produced by the audience management pipeline or by this service itself after an import completes)
- **Frequency**: Driven by the upstream audience refresh schedule; typically periodic (e.g., hourly or on-demand audience updates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka (MBus) | Delivers ScheduledAudienceRefreshed events | `messageBus` |
| Kafka Consumers | Polls Kafka topic and dispatches events to import jobs | `messagingKafkaConsumers` |
| Audience Import Jobs | Receives dispatch and executes the batch import pipeline | `messagingAudienceImportJobs` |

## Steps

1. **Poll Kafka topic**: `messagingKafkaConsumers` continuously polls the `ScheduledAudienceRefreshed` Kafka topic for new events.
   - From: `messagingKafkaConsumers`
   - To: `messageBus` (Kafka)
   - Protocol: Kafka consumer protocol

2. **Receive ScheduledAudienceRefreshed event**: A new event arrives; the consumer deserializes the payload and extracts the audience ID.
   - From: `messageBus` (Kafka)
   - To: `messagingKafkaConsumers`
   - Protocol: Kafka consumer protocol

3. **Dispatch to Audience Import Jobs**: The consumer delivers the audience ID to an `messagingAudienceImportJobs` Akka actor for asynchronous processing.
   - From: `messagingKafkaConsumers`
   - To: `messagingAudienceImportJobs`
   - Protocol: Direct (in-process, actor message)

4. **Execute audience assignment batch**: The Akka actor runs the full [Audience Assignment Batch](audience-assignment-batch.md) pipeline — fetching export metadata from AMS, downloading the export file, and writing assignments to Bigtable or Cassandra.
   - From: `messagingAudienceImportJobs`
   - To: (see Audience Assignment Batch flow)
   - Protocol: Multiple (REST, GCP, CQL/Bigtable)

5. **Acknowledge Kafka offset**: After the import job completes successfully, the Kafka consumer commits the offset to mark the event as processed.
   - From: `messagingKafkaConsumers`
   - To: `messageBus` (Kafka)
   - Protocol: Kafka consumer protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Event deserialization failure | Consumer discards malformed event or routes to error log | Assignment not triggered; audience remains at previous state |
| Audience import job failure | Akka supervisor may retry the actor; Kafka offset not committed | Event may be redelivered on next poll (at-least-once semantics) |
| Kafka broker unavailable | Consumer blocks and retries connection; no dispatch occurs | Audience assignments not refreshed until broker is recovered |

## Sequence Diagram

```
Kafka(ScheduledAudienceRefreshed) -> messagingKafkaConsumers: event { audienceId }
messagingKafkaConsumers -> messagingAudienceImportJobs: dispatch(audienceId)
messagingAudienceImportJobs --> messagingKafkaConsumers: job accepted
messagingKafkaConsumers -> Kafka(ScheduledAudienceRefreshed): commit offset
Note over messagingAudienceImportJobs: Runs Audience Assignment Batch flow (async)
```

## Related

- Architecture dynamic view: `dynamic-scheduled-audience-refresh`
- Related flows: [Audience Assignment Batch](audience-assignment-batch.md)
- Events consumed: see [Events](../events.md)

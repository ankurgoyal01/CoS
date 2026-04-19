---
service: "mobile-logging-v2"
title: "GRP5 Checkout Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "grp5-checkout-event-processing"
flow_type: synchronous
trigger: "A GRP5 event row is encountered during MessagePack decode of a log upload"
participants:
  - "mobileLogV2_decodePipeline"
  - "mobileLogV2_encodingComponent"
  - "mobileLogV2_kafkaPublishComponent"
  - "messageBus"
  - "metricsStack"
architecture_ref: "components-continuumMobileLoggingService"
---

# GRP5 Checkout Event Processing

## Summary

GRP5 is the purchase confirmation event emitted by the Groupon mobile app when a checkout order is successfully created. It carries payment method information and an error code indicating whether the purchase succeeded or failed. This flow documents the specialised processing applied to GRP5 events: payment method extraction from the `_eventfield21` extra-info blob, success/error outcome determination from the `errorCode` field, and emission of detailed checkout-specific metrics. Each purchased item in an order generates a distinct GRP5 event.

## Trigger

- **Type**: event (internal — part of the decode loop)
- **Source**: A row with `eventType == GRP5` is decoded from a mobile log upload by the Message Decode Pipeline
- **Frequency**: Once per checkout event row within a log upload payload; can be multiple per request if a client batches multiple purchase confirmations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Decode Pipeline | Deserialises the GRP5 row into a `GRP5Event` object; extracts outcome and payment method | `mobileLogV2_decodePipeline` |
| Event Encoding Component | Encodes the populated `GRP5Event` for Kafka | `mobileLogV2_encodingComponent` |
| Kafka Publish Component | Publishes the encoded GRP5 event to `mobile_tracking` | `mobileLogV2_kafkaPublishComponent` |
| Kafka Message Bus | Stores the GRP5 event on the `mobile_tracking` topic | `messageBus` |
| Metrics Stack | Receives GRP5-specific detailed metrics (success/error breakdown, payment method) | `metricsStack` |

## Steps

1. **Identify GRP5 event row**: During the event-row iteration in the decode pipeline, a row whose first field equals `GRP5` is identified. Jackson deserialises it into the `GRP5Event` subclass (registered via `@JsonSubTypes`).
   - From: raw event row (List<Object>)
   - To: `GRP5Event` object
   - Protocol: Direct (Jackson deserialisation)

2. **Determine purchase outcome from error code**: The `errorCode` field is read. An empty value or `"0"` maps to `MetricsEvents.SUCCESS`; any non-zero value maps to `MetricsEvents.ERROR`. This result field is used in metrics emission.
   - From/To: `GRP5Event` (internal field `result`)
   - Protocol: Direct

3. **Extract payment method from extra-info**: The `_eventfield21` field is deserialised from a stringified JSON blob into an `ExtraInfo` object. The payment method is resolved by checking `paymentType` first (modern clients), then `payment_type` (legacy clients). Numeric-only values are rejected. If neither field is populated, the default payment method string is used.
   - From: `_eventfield21` string field
   - To: `GRP5Event.extraInfo` (`Optional<ExtraInfo>`)
   - Protocol: Direct (Jackson `StringifiedJsonDeserializer`)

4. **Merge device header fields**: As in the standard decode flow, the device header (platform, version, locale, device ID, etc.) is merged into the GRP5 event JSONObject.
   - From: `deviceHeader` JSONObject
   - To: merged GRP5 event JSONObject
   - Protocol: Direct

5. **Emit detailed GRP5 metrics**: Because `GRP5` is in the `EventTypeMetricsEnum` (not `DEFAULT`), the `EventMetrics.emitMetricAndLogEvent()` switch case emits granular metrics including the purchase outcome (`success` or `error`), the payment method label, client platform, client version, region, and Groupon app version. These are tagged metrics sent to the metrics stack.
   - From: `mobileLogV2_decodePipeline` / metrics component
   - To: `metricsStack`
   - Protocol: tsdaggr

6. **Encode and publish**: The normalised GRP5 event proceeds through the standard [Event Encoding](kafka-event-publish.md) and Kafka publish steps.
   - From: `mobileLogV2_encodingComponent`
   - To: `messageBus` (topic: `mobile_tracking`)
   - Protocol: Kafka/TLS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `_eventfield21` is null or absent | `extraInfo` remains `Optional.empty()`; default payment method used | GRP5 event published with default payment label |
| `_eventfield21` contains unparseable JSON | `StringifiedJsonDeserializer` returns null; `extraInfo` is empty | GRP5 event published with default payment label |
| `errorCode` is null or empty | Treated as success (`MetricsEvents.SUCCESS`) | Success metric emitted |
| Kafka publish fails | Same as standard Kafka error handling — one retry; event dropped on exhaustion | GRP5 event lost; error metric emitted |

## Sequence Diagram

```
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Detect eventType=GRP5; deserialise row to GRP5Event
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Map errorCode -> result (SUCCESS or ERROR)
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Deserialise _eventfield21 -> ExtraInfo; extract paymentMethod
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Merge deviceHeader fields into event JSONObject
mobileLogV2_decodePipeline -> metricsStack: Emit GRP5 metrics (outcome, paymentMethod, platform, region, grouponVersion)
mobileLogV2_decodePipeline -> mobileLogV2_encodingComponent: Pass normalised GRP5 JSONObject
mobileLogV2_encodingComponent -> mobileLogV2_kafkaPublishComponent: Pass encoded payload
mobileLogV2_kafkaPublishComponent -> messageBus: Produce to mobile_tracking (TLS)
messageBus --> mobileLogV2_kafkaPublishComponent: Ack
```

## Related

- Architecture ref: `components-continuumMobileLoggingService`
- Parent flow: [Mobile Log Ingestion](mobile-log-ingestion.md)
- Decode context: [MessagePack Decode and Normalisation](messagepack-decode-normalisation.md)
- Publish context: [Kafka Event Publish](kafka-event-publish.md)

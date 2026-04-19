---
service: "mobile-logging-v2"
title: "Mobile Log Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "mobile-log-ingestion"
flow_type: synchronous
trigger: "POST /v2/mobile/logs from iOS or Android mobile client"
participants:
  - "iOS/Android mobile client"
  - "api-proxy"
  - "mobileLogV2_ingressApi"
  - "mobileLogV2_decodePipeline"
  - "mobileLogV2_encodingComponent"
  - "mobileLogV2_kafkaPublishComponent"
  - "messageBus"
  - "metricsStack"
  - "loggingStack"
architecture_ref: "dynamic-mobile-log-ingestion"
---

# Mobile Log Ingestion

## Summary

The Mobile Log Ingestion flow is the primary end-to-end path through the Mobile Logging Service. A mobile client periodically uploads a batched MessagePack-encoded log file containing multiple GRP telemetry events. The service decodes the payload, normalises each event against a known schema, filters invalid or noisy events, encodes the valid events using Loggernaut, and publishes them to the Kafka topic `mobile_tracking`. The HTTP response is returned to the client once the request has been accepted and queued for processing.

## Trigger

- **Type**: api-call
- **Source**: iOS or Android Groupon application (legacy or MBNXT variant), routed through `api-proxy`
- **Frequency**: Periodic — clients upload log batches at intervals determined by the mobile app; typically every few minutes during active user sessions

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| iOS/Android client | Initiates log upload with MessagePack payload | External |
| api-proxy | Gateway — routes request to service, forwards `true-client-ip` | `api-proxy` |
| Mobile Logging Ingress API | Receives HTTP request, acquires in-flight permit, submits payload for async processing | `mobileLogV2_ingressApi` |
| Message Decode Pipeline | Reads request body, unpacks MessagePack, maps and denormalises event rows | `mobileLogV2_decodePipeline` |
| Event Encoding Component | Encodes each normalised event into Loggernaut serialised format | `mobileLogV2_encodingComponent` |
| Kafka Publish Component | Sends encoded events to the Kafka broker over TLS | `mobileLogV2_kafkaPublishComponent` |
| Kafka (`messageBus`) | Receives and durably stores events on `mobile_tracking` topic | `messageBus` |
| Metrics Stack | Records per-event-type processing outcome counters | `metricsStack` |
| Logging Stack | Receives structured operational log entries for each step | `loggingStack` |

## Steps

1. **Client uploads log file**: The mobile client POSTs a binary MessagePack file to `POST /v2/mobile/logs` with `Content-Type: binary/messagepack` and query parameters `client_id`, `client_version_id`, and `fileName`.
   - From: iOS/Android client
   - To: `api-proxy`
   - Protocol: HTTPS

2. **Gateway forwards request**: `api-proxy` validates and forwards the request, injecting the `true-client-ip` header.
   - From: `api-proxy`
   - To: `mobileLogV2_ingressApi` (port 8080)
   - Protocol: HTTP

3. **Ingress API accepts and checks capacity**: The `mobileLogV2_ingressApi` validates the `Content-Type` header. If not `binary/messagepack`, it returns an error immediately. It then attempts to acquire an in-flight permit from the bounded semaphore (`maxInFlightTasks`). If the service is at capacity, it returns an error (logged as `IN_FLIGHT_ACQUIRE_FAILED`).
   - From: `mobileLogV2_ingressApi` (internal)
   - Protocol: Direct

4. **Read request body**: The ingress API reads the request body with a `requestReadTimeout` (default 5 seconds). Read failures are logged as `READ_TIMEOUT_ERROR` or `READ_ERROR`.
   - From: `mobileLogV2_ingressApi`
   - To: `mobileLogV2_decodePipeline`
   - Protocol: Direct (in-process, RxJava observable)

5. **Decode MessagePack payload**: The `mobileLogV2_decodePipeline` unpacks the binary MessagePack content into a list of rows. It discards the first (timestamp) row, extracts the client header row, and iterates over the remaining event rows. See [MessagePack Decode and Normalisation flow](messagepack-decode-normalisation.md) for detail.
   - From: `mobileLogV2_decodePipeline` (internal)
   - Protocol: Direct (in-process)

6. **Encode events**: Each normalised `JSONObject` event is passed to the `mobileLogV2_encodingComponent`, which serialises it using the Loggernaut (`kafka-message-serde`) encoder into the outbound payload format.
   - From: `mobileLogV2_decodePipeline`
   - To: `mobileLogV2_encodingComponent`
   - Protocol: Direct (in-process)

7. **Publish to Kafka**: The `mobileLogV2_kafkaPublishComponent` sends the encoded payload to the Kafka broker on the configured topic (`mobile_tracking`) using the TLS-authenticated Kafka producer (`acks=1`, `retries=1`). A `KAFKA_PRODUCER_SENT` log event is emitted on success.
   - From: `mobileLogV2_kafkaPublishComponent`
   - To: `messageBus` (Kafka)
   - Protocol: Kafka/TLS

8. **Emit processing metrics**: For each event, outcome metrics (`success`, `error`, `exception`, `processed`, `fail`) are emitted per event type to the metrics stack.
   - From: `continuumMobileLoggingService`
   - To: `metricsStack`
   - Protocol: tsdaggr

9. **Write operational logs**: Request lifecycle events, errors, and debug information are written as structured log entries to the logging stack via Filebeat.
   - From: `continuumMobileLoggingService`
   - To: `loggingStack`
   - Protocol: Filebeat log shipping

10. **Return HTTP response**: The ingress API returns HTTP 200 with a JSON body (or an appropriate error status) to the mobile client.
    - From: `mobileLogV2_ingressApi`
    - To: iOS/Android client (via `api-proxy`)
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unsupported `Content-Type` | Return HTTP error immediately; log `CONTENT_TYPE_NOT_SUPPORTED` | Request rejected; no events processed |
| In-flight capacity exceeded | Return HTTP error; log `IN_FLIGHT_ACQUIRE_FAILED` | Request rejected; no events processed |
| Request body read timeout | Log `READ_TIMEOUT_ERROR`; release in-flight permit | Request rejected; no events processed |
| MessagePack decode error | Log `DECODE_ERROR` or `DECODE_ARRAY_ERROR` | Affected payload discarded; partial processing if other events in batch succeeded before error |
| Encode error | Log `ENCODE_ERROR` | Affected event dropped; other events in batch continue |
| Kafka send failure | Log `KAFKA_SEND` error; count as `error` metric; one retry attempted | Event dropped after retry exhaustion |
| In-flight permit interruption | Log `IN_FLIGHT_ACQUIRE_INTERRUPTED` | Request rejected |

## Sequence Diagram

```
MobileClient -> api-proxy: POST /v2/mobile/logs (MessagePack binary, Content-Type: binary/messagepack)
api-proxy -> mobileLogV2_ingressApi: Forward HTTP request with true-client-ip
mobileLogV2_ingressApi -> mobileLogV2_ingressApi: Validate Content-Type; acquire in-flight permit
mobileLogV2_ingressApi -> mobileLogV2_decodePipeline: Submit raw payload
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Unpack MessagePack; map client header; denormalise events; filter noise
mobileLogV2_decodePipeline -> mobileLogV2_encodingComponent: Pass normalised JSONObject events
mobileLogV2_encodingComponent -> mobileLogV2_kafkaPublishComponent: Pass encoded payloads
mobileLogV2_kafkaPublishComponent -> messageBus: Produce encoded events to mobile_tracking (TLS)
messageBus --> mobileLogV2_kafkaPublishComponent: Ack (acks=1)
mobileLogV2_kafkaPublishComponent -> metricsStack: Emit success/error counters per event type
mobileLogV2_ingressApi -> loggingStack: Write structured logs via Filebeat
mobileLogV2_ingressApi --> MobileClient: HTTP 200 OK (JSON)
```

## Related

- Architecture dynamic view: `dynamic-mobile-log-ingestion`
- Related flows: [MessagePack Decode and Normalisation](messagepack-decode-normalisation.md), [Kafka Event Publish](kafka-event-publish.md), [GRP5 Checkout Event Processing](grp5-checkout-event-processing.md)

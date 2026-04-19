---
service: "mobile-logging-v2"
title: "MessagePack Decode and Event Normalisation"
generated: "2026-03-03"
type: flow
flow_name: "messagepack-decode-normalisation"
flow_type: synchronous
trigger: "Raw client payload submitted by Ingress API after successful body read"
participants:
  - "mobileLogV2_decodePipeline"
architecture_ref: "components-continuumMobileLoggingService"
---

# MessagePack Decode and Event Normalisation

## Summary

This flow describes how the Message Decode Pipeline processes a raw MessagePack binary payload received from a mobile client. The pipeline unpacks the binary format, extracts a structured client header, iterates over event rows, applies schema-based field mapping for each GRP event type, filters out noise and PII-leaking events, and emits a stream of normalised `JSONObject` records ready for encoding. This is an entirely in-process operation using an RxJava observable chain.

## Trigger

- **Type**: api-call (internal invocation)
- **Source**: `mobileLogV2_ingressApi` submits the raw client payload after reading the request body
- **Frequency**: Once per successful log upload request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Decode Pipeline | Orchestrates all decode, mapping, filtering, and normalisation steps | `mobileLogV2_decodePipeline` |

## Steps

1. **Unpack MessagePack binary**: `MessagepackToObjectConverter` reads the binary data and converts it into a `List<List<Object>>` — a list of rows, each row being a list of typed values. The `replaceInfinity` flag controls whether `Infinity` float values are replaced with `null` during conversion.
   - From: raw byte stream (request body)
   - To: in-memory row list
   - Protocol: Direct (MessagePack library)

2. **Discard timestamp prefix row**: The first row in the list is a prefix timestamp and is discarded unconditionally.
   - From: `mobileLogV2_decodePipeline` (internal)
   - Protocol: Direct

3. **Extract client header row**: The second row is mapped to a `JSONObject` using the `MobileDeviceSourceFieldsAsList` schema. Named fields include `clientPlatform`, `clientVersion`, `clientLocale`, `clientBcookie`, `clientDeviceID`, `clientClientID`, `sessionId`, `brand`, `appInstanceId`, `grouponVersion`, and others. Unknown-position fields use the `_clientfield<N>` naming convention. If `grouponVersion` is absent it defaults to `legacy`.
   - From: row list
   - To: `deviceHeader` JSONObject
   - Protocol: Direct

4. **Detect iOS 3.10 client**: Checks whether the client platform matches `IP(HONE|AD)CON (.*)` and version matches `3.10 (.*)`. If so, a bug-fix decode path is used for non-funnel event types to correct a field offset introduced by MBA-154.
   - From: `deviceHeader`
   - Protocol: Direct

5. **Iterate over event rows**: Each remaining row is evaluated to determine if it is a GRP event (first field is a string containing `GRP`). Non-GRP rows are skipped.
   - From: row iterator
   - Protocol: Direct

6. **Map event fields**: For each GRP row, `GRPMapper.map()` resolves the GRP type string (e.g., `GRP7`) to an integer using a precomputed `ImmutableMap`. The appropriate schema (`EventTypeToMobileEventSchema` for typed events, or `MobileEventFields` for generic events) is selected. Fields are mapped by position; unknown-position fields use the `_eventfield<N>` naming convention.
   - From: event row array
   - To: `event` JSONObject (partial)
   - Protocol: Direct

7. **Merge device header into event**: All device header fields from step 3 are copied into the event `JSONObject`, producing a fully denormalised record.
   - From: `deviceHeader` + partial event
   - To: fully denormalised `event` JSONObject
   - Protocol: Direct

8. **Apply GRP40 PII redaction**: If `eventType == GRP40`, fields `_eventfield6` and `_eventfield7` (request headers and body) are replaced with `[redacted]` to prevent personal information from being forwarded to Kafka.
   - From/To: `event` JSONObject (in-place mutation)
   - Protocol: Direct

9. **Fix bad bcookies**: Compares `clientBcookie` (or `_clientfield4`) against a known bad-bcookie list loaded from `bad_bcookies.txt` at startup. If a match is found and the `idfa` (or `_clientfield9`) field is non-empty, the bcookie value is replaced with the idfa value (ported from legacy Ruby service, MBA-154 fix).
   - From/To: `event` JSONObject (in-place mutation)
   - Protocol: Direct

10. **Filter noise events**: Events are discarded (not emitted) if:
    - The event is a GRP7 where `url == https://logging.groupon.com/v2/mobile/logs` (self-referential logging calls)
    - The event is an Android GRP8 with `category == ImagePerfEvent` (Android image performance noise)
    - The event is a GRP7 or GRP40 from a client with version below 18.2 (older clients generating incorrect events)

11. **Emit valid event**: Each surviving event `JSONObject` is emitted downstream to the `mobileLogV2_encodingComponent`.
    - From: `mobileLogV2_decodePipeline`
    - To: `mobileLogV2_encodingComponent`
    - Protocol: Direct (RxJava `subscriber.onNext()`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Empty log payload (no rows) | Throws `IllegalArgumentException("Empty log.")` | Payload rejected; logged as `DECODE_ERROR` |
| Payload has no header row | Throws `IllegalArgumentException("Log has no header.")` | Payload rejected; logged as `DECODE_ERROR` |
| Payload has header but no event rows | Throws `IllegalArgumentException("Log has a header but no events.")` | Payload rejected; logged as `DECODE_ERROR` |
| MessagePack conversion failure | `IOException` propagated via `Throwables.propagate()` | Payload rejected; logged as `DECODE_ARRAY_ERROR` |
| Unknown GRP type string | `GRPMapper` throws `IllegalArgumentException` | That row is skipped; other rows continue |
| Non-GRP row in event list | Silently skipped by `isGRP()` check | Row ignored |

## Sequence Diagram

```
mobileLogV2_ingressApi -> mobileLogV2_decodePipeline: Submit raw byte payload
mobileLogV2_decodePipeline -> MessagepackToObjectConverter: Unpack binary to List<List<Object>>
MessagepackToObjectConverter --> mobileLogV2_decodePipeline: Nested row list
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Discard timestamp prefix row
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Map client header row -> deviceHeader JSONObject
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: For each event row: GRP check -> field map -> merge header
mobileLogV2_decodePipeline -> mobileLogV2_decodePipeline: Apply GRP40 redaction; fix bad bcookies; filter noise
mobileLogV2_decodePipeline -> mobileLogV2_encodingComponent: Emit normalised JSONObject (per valid event)
```

## Related

- Architecture ref: `components-continuumMobileLoggingService`
- Parent flow: [Mobile Log Ingestion](mobile-log-ingestion.md)
- Related flows: [GRP5 Checkout Event Processing](grp5-checkout-event-processing.md), [Kafka Event Publish](kafka-event-publish.md)

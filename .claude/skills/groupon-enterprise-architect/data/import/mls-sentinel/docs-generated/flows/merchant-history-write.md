---
service: "mls-sentinel"
title: "Merchant History Write"
generated: "2026-03-03"
type: flow
flow_name: "merchant-history-write"
flow_type: synchronous
trigger: "POST /v1/history HTTP request"
participants:
  - "continuumMlsSentinelService"
  - "mlsSentinelHistoryDb"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# Merchant History Write

## Summary

MLS Sentinel serves as the write API for the Merchant History Service. External callers (authenticated by Client-ID) submit history events via `POST /v1/history`. Sentinel validates the event body, and depending on the `sentinelHistoryEventConfig` feature flags, either persists the event to the History DB, publishes it as an `mls.HistoryEvent` Kafka Command to Yang, or both. At least one of these two destinations must be enabled — enforced at startup by a `@Value.Check` validation.

## Trigger

- **Type**: synchronous (API call)
- **Source**: Authenticated internal callers via `POST /v1/history`
- **Frequency**: On-demand; tied to merchant lifecycle history recording events

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External caller (authenticated) | Submits history event via HTTP | (client of `continuumMlsSentinelService`) |
| MLS Sentinel Service | Validates, persists, and/or routes the history event | `continuumMlsSentinelService` |
| MLS Sentinel History DB | Persists history events (when `saveHistoryEventInHistoryService` enabled) | `mlsSentinelHistoryDb` |
| MLS Yang (Kafka consumer) | Receives history events via `mls.HistoryEvent` topic (when `sendHistoryEventToYang` enabled) | (external to this flow) |

## Steps

1. **Receives history event request**: The Resource API Layer accepts the `POST /v1/history` request with a `HistoryCreationMessage` body. Client-ID authentication is enforced.
   - From: External caller
   - To: `continuumMlsSentinelService` (Resource API Layer — `/v1/history`)
   - Protocol: HTTP POST

2. **Validates request body**: The JAX-RS resource deserializes and validates the `HistoryCreationMessage` payload, which includes historyId, merchantId, dealId, userId, deviceId, clientId, eventDate, eventType, eventTypeId, userType, and historyData.
   - From: Resource API Layer
   - To: Flow Processing Layer
   - Protocol: internal

3. **Persists to History DB** (if `saveHistoryEventInHistoryService` = `true`): The Persistence Layer writes the history event record to the History DB via JDBI.
   - From: `continuumMlsSentinelService` (Persistence Layer)
   - To: `mlsSentinelHistoryDb`
   - Protocol: JDBI / PostgreSQL

4. **Publishes HistoryEvent Command to Kafka** (if `sendHistoryEventToYang` = `true`): The Flow Processing Layer assembles a `Command<HistoryEventPayload>` and routes it via `RoutingService` to the `mls.HistoryEvent` Kafka topic.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.HistoryEvent`)
   - Protocol: Kafka 0.9.0.1

5. **Returns HTTP response**: The API responds to the caller after both configured persistence paths complete.
   - From: `continuumMlsSentinelService` (Resource API Layer)
   - To: External caller
   - Protocol: HTTP 200 (default)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request body (missing required fields) | JAX-RS validation error; HTTP 400 returned | Event not persisted; caller must fix and retry |
| DB write failure (History DB) | Exception propagated; HTTP 500 returned | Event not persisted; caller must retry |
| Kafka produce failure | Error logged; `MlsSentinel-US_KAFKA_PRODUCED` alert may fire | If only Kafka path is enabled, event is lost for Yang; caller receives error |
| Both persistence paths disabled | Startup validation (`@Value.Check`) prevents service from starting | Service does not start if both flags are false |
| Unauthenticated request | JTier Client-ID auth rejects request | HTTP 401 returned; event not processed |

## Sequence Diagram

```
ExternalCaller -> MlsSentinel (/v1/history): POST HistoryCreationMessage (Client-ID auth)
MlsSentinel    -> MlsSentinel (Flow Processor): Validates and processes history event
MlsSentinel    -> mlsSentinelHistoryDb: INSERT history event record (JDBI) [if saveHistoryEventInHistoryService]
mlsSentinelHistoryDb --> MlsSentinel: Write confirmed
MlsSentinel    -> Kafka (mls.HistoryEvent): Publishes HistoryEvent command [if sendHistoryEventToYang]
MlsSentinel    --> ExternalCaller: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Voucher Sold Processing](voucher-sold-processing.md)
- API surface: [API Surface](../api-surface.md) — `/v1/history`
- Data stores: [Data Stores](../data-stores.md) — History DB
- Configuration: [Configuration](../configuration.md) — `sentinelHistoryEventConfig`
- Events: [Events](../events.md)

---
service: "mls-yang"
title: "History Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "history-event-processing"
flow_type: event-driven
trigger: "Kafka message on mls.HistoryEvent topic"
participants:
  - "messageBus"
  - "smaApi_commandIngestion"
  - "smaApi_persistence"
  - "mlsYangDb"
  - "mlsYangHistoryDb"
architecture_ref: "dynamic-yang-command-smaApi_commandIngestion-flow"
---

# History Event Processing

## Summary

This flow handles ingestion of merchant history events from the `mls.HistoryEvent` Kafka topic. History events record significant lifecycle actions (e.g. deal cap raises, status changes) with full actor context. The handler applies idempotency checking before writing, and conditionally routes each event to two separate stores: the dedicated `historyDb` (when enabled via config), and the Yang primary database (only for event types in the configured whitelist, currently `DEAL_CAP_RAISE_EVENT`).

## Trigger

- **Type**: event
- **Source**: `mls.HistoryEvent` Kafka topic
- **Frequency**: Continuous — on each merchant lifecycle history event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka (`mls.HistoryEvent`) | Source of history event commands | `messageBus` |
| Command Ingestion Pipeline | Polls topic, deserialises, dispatches to `HistoryCreationHandler` | `smaApi_commandIngestion` |
| History Creation Handler | Applies idempotency checks and conditional routing logic | `smaApi_commandIngestion` |
| Persistence Layer | Executes inserts via `HistoryEventDao` and `YangHistoryEventDao` | `smaApi_persistence` |
| History DB | Primary history event store (all event types when enabled) | `mlsYangHistoryDb` |
| Yang Primary DB | Whitelist-filtered event store (e.g. `DEAL_CAP_RAISE_EVENT`) | `mlsYangDb` |

## Steps

1. **Consume history event**: The Kafka consumer polls `mls.HistoryEvent` with manual offset commit on consumer group `mls_yang-prod-snc1`.
   - From: `messageBus` (Kafka)
   - To: `smaApi_commandIngestion`
   - Protocol: Kafka (SSL)

2. **Deserialise payload**: Command is deserialised to `HistoryEvent` (v1) containing: `historyId`, `eventType`, `eventTypeId`, `eventDate`, `userType`, `userId`, `clientId`, `systemId`, `deviceId`, `merchantId`, `dealId`, `historyData`.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion` (internal)
   - Protocol: In-process

3. **Check config: write to historyDb?**: If `yangHistoryEventConfig.saveHistoryEventInHistoryService = true` (enabled in production), proceed to step 4. Otherwise skip to step 6.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion`
   - Protocol: In-process (config lookup)

4. **Idempotency check (historyDb)**: Calls `HistoryEventDao.findEvent(historyId)`. If a record already exists, logs a warning and skips write to `historyDb`.
   - From: `smaApi_persistence`
   - To: `mlsYangHistoryDb`
   - Protocol: JDBC (SELECT)

5. **Insert into historyDb**: If no duplicate found, calls `HistoryEventDao.insert(...)` with all event fields.
   - From: `smaApi_persistence`
   - To: `mlsYangHistoryDb`
   - Protocol: JDBC (INSERT)

6. **Check whitelist**: If `historyEvent.eventType` is in `yangHistoryEventConfig.typesWhitelist` (e.g. `DEAL_CAP_RAISE_EVENT`), proceed to steps 7-8. Otherwise skip.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion`
   - Protocol: In-process

7. **Idempotency check (yangDb)**: Calls `YangHistoryEventDao.findEvent(historyId)`. If already exists, logs a warning and skips write to `yangDb`.
   - From: `smaApi_persistence`
   - To: `mlsYangDb`
   - Protocol: JDBC (SELECT)

8. **Insert into yangDb**: If no duplicate, calls `YangHistoryEventDao.insert(...)`.
   - From: `smaApi_persistence`
   - To: `mlsYangDb`
   - Protocol: JDBC (INSERT)

9. **Commit offset**: Offset committed manually after all writes complete.
   - From: `smaApi_commandIngestion`
   - To: `messageBus`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate `historyId` (historyDb) | `LOGGER.warn` emitted; insert skipped | Idempotent — no duplicate write |
| Duplicate `historyId` (yangDb) | `LOGGER.warn` emitted; insert skipped | Idempotent — no duplicate write |
| Database write failure | JDBI exception propagates; offset not committed | Message replayed on next poll |
| `saveHistoryEventInHistoryService = false` | historyDb write path entirely bypassed | Only whitelist path evaluated |

## Sequence Diagram

```
Kafka(mls.HistoryEvent) -> KafkaEventConsumer: poll()
KafkaEventConsumer -> HistoryCreationHandler: handlerInternal(command)
HistoryCreationHandler -> HistoryEventDao: findEvent(historyId)
HistoryEventDao -> mlsYangHistoryDb: SELECT history_event WHERE history_id=?
mlsYangHistoryDb --> HistoryEventDao: null (not found)
HistoryCreationHandler -> HistoryEventDao: insert(historyId, eventType, ...)
HistoryEventDao -> mlsYangHistoryDb: INSERT INTO history_event
mlsYangHistoryDb --> HistoryEventDao: OK
HistoryCreationHandler -> HistoryCreationHandler: isWhitelisted(eventType)?
HistoryCreationHandler -> YangHistoryEventDao: findEvent(historyId)
YangHistoryEventDao -> mlsYangDb: SELECT WHERE history_id=?
mlsYangDb --> YangHistoryEventDao: null (not found)
HistoryCreationHandler -> YangHistoryEventDao: insert(historyId, eventType, ...)
YangHistoryEventDao -> mlsYangDb: INSERT INTO yang_history_event
mlsYangDb --> YangHistoryEventDao: OK
KafkaEventConsumer -> Kafka(mls.HistoryEvent): commitOffset()
```

## Related

- Architecture dynamic view: `dynamic-yang-command-smaApi_commandIngestion-flow`
- Related flows: [MLS Command Ingestion and Projection](command-ingestion.md)
- Configuration: `yangHistoryEventConfig.typesWhitelist`, `yangHistoryEventConfig.saveHistoryEventInHistoryService`
- Events documentation: [Events](../events.md)

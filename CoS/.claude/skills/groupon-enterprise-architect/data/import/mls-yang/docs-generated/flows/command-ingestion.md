---
service: "mls-yang"
title: "MLS Command Ingestion and Projection"
generated: "2026-03-03"
type: flow
flow_name: "command-ingestion"
flow_type: event-driven
trigger: "Kafka message arrival on any MLS command topic"
participants:
  - "messageBus"
  - "continuumSmaMetricsApi"
  - "smaApi_commandIngestion"
  - "smaApi_persistence"
  - "mlsYangDb"
  - "mlsYangRinDb"
  - "mlsYangHistoryDb"
  - "mlsYangDealIndexDb"
architecture_ref: "dynamic-yang-command-smaApi_commandIngestion-flow"
---

# MLS Command Ingestion and Projection

## Summary

This flow covers how mls-yang receives MLS command messages from Kafka and projects them into the appropriate read-model database. Each command topic has a dedicated Kafka consumer group listener and a typed handler that maps the command payload to a persistence operation. The flow is the core data ingestion mechanism for the Yang read side of the MLS CQRS architecture.

## Trigger

- **Type**: event
- **Source**: Kafka topics published by MLS Yin-side command producers (external to this service)
- **Frequency**: Continuous — on each message arrival; consumer poll interval 1,000ms in production

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka (MLS Topics) | Source of MLS command messages | `messageBus` |
| Command Ingestion Pipeline | Receives, deserialises, and dispatches commands to typed handlers | `smaApi_commandIngestion` |
| Persistence Layer | Executes DAO operations against the target database | `smaApi_persistence` |
| Yang Primary DB | Receives vouchers, CLO, merchant facts, account, bullet, deal metrics | `mlsYangDb` |
| History DB | Receives whitelisted history events | `mlsYangHistoryDb` |
| Deal Index DB | Receives deal snapshots and deal events | `mlsYangDealIndexDb` |
| RIN DB | Receives merchant lifecycle data (inventory) | `mlsYangRinDb` |

## Steps

1. **Consume Kafka message**: The Kafka consumer (`KafkaEventConsumer`) polls the configured topic (e.g. `mls.VoucherSold`) using consumer group `mls_yang-prod-snc1`.
   - From: `messageBus` (Kafka topic)
   - To: `smaApi_commandIngestion`
   - Protocol: Kafka (SSL, bootstrap `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`)

2. **Deserialise command**: `MessageDeserializer` deserialises the raw Kafka message bytes into a typed `Command<T>` envelope using the registered `commandTypes` for the topic.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion` (internal)
   - Protocol: In-process

3. **Dispatch to handler**: `CommandHandler` routes the `Command` to the appropriate typed handler based on the `payloadType` field (e.g. `VoucherSoldHandler`, `CloTransactionHandler`, `HistoryCreationHandler`, `DealSnapshotHandler`).
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion` (handler dispatch)
   - Protocol: In-process

4. **Execute projection write**: The handler calls the relevant DAO method on the persistence layer. Examples:
   - `VoucherSoldHandler` calls `VoucherSoldDao.upsertVoucherSold`
   - `CloTransactionHandler` calls `CloTransactionDao.insertAndUpsertRecentTransaction`
   - `DealSnapshotHandler` calls `DealSnapshotPersistenceService.updateDealSnapshot`
   - `HistoryCreationHandler` calls `HistoryEventDao.insert` and/or `YangHistoryEventDao.insert`
   - From: `smaApi_commandIngestion`
   - To: `smaApi_persistence`
   - Protocol: In-process (JDBI)

5. **Write to database**: The persistence layer executes the SQL statement against the target PostgreSQL database.
   - From: `smaApi_persistence`
   - To: `mlsYangDb`, `mlsYangHistoryDb`, `mlsYangDealIndexDb`, or `mlsYangRinDb` (depending on command type)
   - Protocol: JDBC

6. **Commit Kafka offset**: After successful processing, the consumer commits the offset (auto-commit enabled for topics where `auto.commit.enable: true`; manual for others).
   - From: `smaApi_commandIngestion`
   - To: `messageBus`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown command payload type | `handlerInternal` throws `IllegalStateException`; `ExceptionHandler` catches and logs | Message is skipped; offset committed to avoid blocking |
| Database write failure | JDBI exception propagates; consumer exception handler logs error | Offset not committed (for manual-commit topics); message replayed on next poll |
| Kafka SSL authentication failure | Consumer fails to connect; pod logs error; Kubernetes restarts pod | Consumer group lag builds until pod restarts and reconnects |
| Duplicate HistoryEvent | Pre-insert existence check finds existing `historyId`; `LOGGER.warn` emitted | Duplicate is silently skipped; idempotent |

## Sequence Diagram

```
Kafka(mls.VoucherSold) -> KafkaEventConsumer: poll()
KafkaEventConsumer -> MessageDeserializer: deserialise(bytes)
MessageDeserializer --> KafkaEventConsumer: Command<VoucherSold>
KafkaEventConsumer -> VoucherSoldHandler: handlerInternal(command)
VoucherSoldHandler -> VoucherSoldDao: upsertVoucherSold(merchantId, count, countedAt)
VoucherSoldDao -> mlsYangDb: SQL UPSERT
mlsYangDb --> VoucherSoldDao: OK
VoucherSoldDao --> VoucherSoldHandler: done
VoucherSoldHandler --> KafkaEventConsumer: done
KafkaEventConsumer -> Kafka(mls.VoucherSold): commitOffset()
```

## Related

- Architecture dynamic view: `dynamic-yang-command-smaApi_commandIngestion-flow`
- Related flows: [CLO Transaction Processing](clo-transaction-processing.md), [History Event Processing](history-event-processing.md)
- Events documentation: [Events](../events.md)

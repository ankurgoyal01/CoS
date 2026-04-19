---
service: "mls-yang"
title: "CLO Transaction Processing"
generated: "2026-03-03"
type: flow
flow_name: "clo-transaction-processing"
flow_type: event-driven
trigger: "Kafka message on mls.CloTransaction topic"
participants:
  - "messageBus"
  - "smaApi_commandIngestion"
  - "smaApi_persistence"
  - "mlsYangDb"
architecture_ref: "dynamic-yang-command-smaApi_commandIngestion-flow"
---

# CLO Transaction Processing

## Summary

This flow handles the ingestion of card-linked offer (CLO) transaction commands from the `mls.CloTransaction` Kafka topic. CLO transactions represent three lifecycle stages of a card-linked offer redemption: AUTH (authorisation), CLEAR (clearing/settlement), and REWARD (reward issuance with merchant charge). Each transaction type carries different fields and is mapped to a unified CLO transaction record in the Yang database.

## Trigger

- **Type**: event
- **Source**: `mls.CloTransaction` Kafka topic; published by MLS CLO command producers
- **Frequency**: Continuous — on each CLO transaction event in the merchant network

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka (`mls.CloTransaction`) | Source of CLO command messages | `messageBus` |
| Command Ingestion Pipeline | Polls topic, deserialises, dispatches to handler | `smaApi_commandIngestion` |
| CLO Transaction Handler | Classifies transaction type, extracts all fields | `smaApi_commandIngestion` |
| Persistence Layer | Executes upsert SQL via `CloTransactionDao` | `smaApi_persistence` |
| Yang Primary DB | Stores CLO transaction records | `mlsYangDb` |

## Steps

1. **Consume CLO command**: The Kafka consumer polls `mls.CloTransaction` on consumer group `mls_yang-prod-snc1` with manual offset commit.
   - From: `messageBus` (Kafka)
   - To: `smaApi_commandIngestion`
   - Protocol: Kafka (SSL)

2. **Deserialise payload**: Command is deserialised; payload is one of `CloAuthTransaction`, `CloClearTransaction`, or `CloRewardTransaction` (all v1).
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion` (internal)
   - Protocol: In-process

3. **Classify transaction type**: `CloTransactionHandler.handlerInternal` uses `instanceof` checks to identify the transaction type and sets `transactionType` enum value (`AUTH`, `CLEAR`, `REWARD`). For `CloRewardTransaction`, additionally extracts `merchantChargeAmount`, `merchantChargeFormattedAmount`, and `confirmedAt`.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_commandIngestion` (internal)
   - Protocol: In-process

4. **Persist CLO record**: Calls `CloTransactionDao.insertAndUpsertRecentTransaction` with the full set of fields: transaction UUID, type, timestamps (`transactionAt`, `eventTime`, `confirmedAt`), consumer UUID, deal UUID, claim UUID, redemption location UUID, country, currency, network type, group ID, currency exponent, amount fields (transaction, reward, marketing fee, merchant charge), billing record ID, pre-claim flag, and exclude-from-billing flag.
   - From: `smaApi_commandIngestion`
   - To: `smaApi_persistence`
   - Protocol: In-process (JDBI)

5. **Write to yangDb**: SQL insert + upsert recent transaction record in `mlsYangDb`.
   - From: `smaApi_persistence`
   - To: `mlsYangDb`
   - Protocol: JDBC

6. **Commit offset**: Offset committed manually after successful write.
   - From: `smaApi_commandIngestion`
   - To: `messageBus`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown CLO payload type | `IllegalStateException` thrown with payload type and version details | Consumer exception handler logs; offset not committed; message replayed |
| Database write failure | JDBI exception; offset not committed (manual commit mode) | Message replayed on next consumer poll |
| Duplicate transaction UUID | `insertAndUpsertRecentTransaction` handles upsert semantics | Idempotent — existing record is updated |

## Sequence Diagram

```
Kafka(mls.CloTransaction) -> KafkaEventConsumer: poll()
KafkaEventConsumer -> CloTransactionHandler: handlerInternal(command)
CloTransactionHandler -> CloTransactionHandler: classify(payload) -> AUTH|CLEAR|REWARD
CloTransactionHandler -> CloTransactionDao: insertAndUpsertRecentTransaction(fields...)
CloTransactionDao -> mlsYangDb: SQL INSERT + UPSERT
mlsYangDb --> CloTransactionDao: OK
CloTransactionDao --> CloTransactionHandler: done
KafkaEventConsumer -> Kafka(mls.CloTransaction): commitOffset()
```

## Related

- Architecture dynamic view: `dynamic-yang-command-smaApi_commandIngestion-flow`
- Related flows: [MLS Command Ingestion and Projection](command-ingestion.md)
- API: `GET /clo_transaction`, `GET /clo_transaction/search`, `GET /clo_transaction/{transaction_uuid}`
- Events documentation: [Events](../events.md)

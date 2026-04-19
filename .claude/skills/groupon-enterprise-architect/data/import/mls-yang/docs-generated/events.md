---
service: "mls-yang"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

mls-yang is a primarily event-driven service. It consumes nine categories of MLS command messages from Kafka topics and projects their payloads into read-model databases. It also publishes batch feedback commands to the MLS message bus (`jms.queue.mls.batchCommands`) upon scheduled job completion. Kafka consumers use SSL in production and are configured per-topic with their own consumer group (`mls_yang-prod-snc1` in production).

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.queue.mls.batchCommands` | Batch Feedback Command | Scheduled batch job completion | `id`, `origin` (prefixed `FEEDBACK:`), `payload` (job-specific), `context.timestamp` |

### Batch Feedback Command Detail

- **Topic**: `jms.queue.mls.batchCommands`
- **Trigger**: Completion of any scheduled Quartz batch import or retention job
- **Payload**: MLS `Command` envelope wrapping a job-specific feedback payload; context origin is prefixed with `FEEDBACK:` followed by the job name
- **Consumers**: MLS platform services (e.g. mls-yin or orchestration services) that track batch job completion
- **Guarantees**: at-least-once (durable queue in production; non-durable in staging)
- **Host (production)**: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com`
- **Host (staging)**: `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com`
- **Subscription ID (production)**: `mls-yang-feedback`

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `mls.VoucherSold` | `VoucherSold` (v1, v2) | `VoucherSoldHandler` | Upserts voucher-sold count into `mlsYangDb` |
| `mls.VoucherRedeemed` | `VoucherRedeemed` (v1, v2) | `VoucherRedeemedHandler` | Upserts voucher-redeemed count into `mlsYangDb` |
| `mls.BulletCreated` | `BulletCreated` (v1) | `BulletCreatedHandler` | Persists bullet record into `mlsYangDb` |
| `mls.MerchantFactChanged` | `MerchantFactChanged` (v1) | `MerchantFactChangedHandler` | Upserts merchant fact (e.g. metal tier) into `mlsYangDb` |
| `mls.MerchantAccountChanged` | `MerchantAccountChanged` (v1) | `MerchantAccountChangedHandler` | Upserts merchant account record into `mlsYangDb` |
| `mls.CloTransaction` | `CloAuthTransaction`, `CloClearTransaction`, `CloRewardTransaction` (v1) | `CloTransactionHandler` | Inserts/upserts CLO transaction record into `mlsYangDb` |
| `mls.HistoryEvent` | `HistoryEvent` (v1) | `HistoryCreationHandler` | Inserts history event into `mlsYangHistoryDb`; conditionally inserts whitelisted events into `mlsYangDb` |
| `mls.Generic` | `DealSnapshot` (v1) | `DealSnapshotHandler` | Updates deal snapshot in `mlsYangDealIndexDb` |
| `mls.Generic` | `DealEvent` (v1) | `DealEventHandler` | Processes deal events (disabled in production at time of last config) |

### VoucherSold Detail

- **Topic**: `mls.VoucherSold`
- **Handler**: Deserialises `VoucherSold` (v1 or v2 payload), calls `VoucherSoldDao.upsertVoucherSold` with merchant ID, count, and timestamp
- **Idempotency**: Upsert-based — repeated messages result in an update to the same row
- **Error handling**: Exception handler logs and skips unrecognised payload types; Kafka offset committed after processing
- **Processing order**: Unordered (no partition-key ordering guarantee enforced at handler level)

### CloTransaction Detail

- **Topic**: `mls.CloTransaction`
- **Handler**: Classifies payload as `AUTH`, `CLEAR`, or `REWARD` transaction type; calls `CloTransactionDao.insertAndUpsertRecentTransaction` with full transaction fields including merchant charge, marketing fee, reward amounts, and billing flags
- **Idempotency**: Insert + upsert recent pattern — deduplication by transaction UUID
- **Error handling**: Unknown payload type throws `IllegalStateException`; consumer error handler manages retry/skip
- **Processing order**: Unordered

### HistoryEvent Detail

- **Topic**: `mls.HistoryEvent`
- **Handler**: Checks idempotency by looking up `historyId` before inserting; conditionally writes to `historyDb` (if `saveHistoryEventInHistoryService=true`) and to `yangDb` (if event type is in `typesWhitelist`, e.g. `DEAL_CAP_RAISE_EVENT`)
- **Idempotency**: Pre-insert existence check using `historyId`; duplicate events are logged and skipped
- **Error handling**: Warnings logged for duplicate history IDs; no DLQ configured in source
- **Processing order**: Unordered

### DealSnapshot Detail

- **Topic**: `mls.Generic`
- **Handler**: Delegates to `DealSnapshotPersistenceService.updateDealSnapshot` which writes to `mlsYangDealIndexDb`
- **Idempotency**: Update-based persistence
- **Error handling**: Inherits from `AbstractHandler` exception handling
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase of explicit dead letter queue configuration. Error handling relies on consumer-level exception handlers and logging.

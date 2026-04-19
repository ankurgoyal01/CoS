---
service: "mls-sentinel"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, kafka]
---

# Events

## Overview

MLS Sentinel is primarily an event-driven service. It consumes six MessageBus (MBus) queues and topics covering merchant commerce lifecycle events, validates the payload data against owner services, and publishes seven Kafka Command topics. The MBus consumer infrastructure is managed by `MBusSourceManager`, which reads processor definitions from the `mbusConfiguration` section of the YAML config and registers a typed `AbstractProcessor` per destination. The Kafka producer is managed by `RoutingService`, which routes each validated `Command` object to Kafka topics and/or an outbound MBus destination based on the `commandRouter` configuration.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `mls.BulletCreated` | BulletCreated Command | Inventory product indexed or updated | Inventory product data snapshot |
| `mls.VoucherSold` | VoucherSold Command | `jms.queue.mls.VoucherSold` consumed and validated | Voucher ID, merchant data, inventory data |
| `mls.VoucherRedeemed` | VoucherRedeemed Command | `jms.queue.mls.VoucherRedeemed` consumed and validated | Voucher ID, redemption data |
| `mls.MerchantFactChanged` | MerchantFactChanged Command | Inventory product update triggers merchant fact re-evaluation | Merchant fact snapshot |
| `mls.MerchantAccountChanged` | MerchantAccountChanged Command | `jms.queue.mls.SalesforceCreated` or `SalesforceUpdate` consumed and validated | Salesforce account data, merchant ID |
| `mls.CloTransaction` | CloTransaction Command | `jms.topic.clo.redemptions` or `jms.topic.clo.replay.redemptions` consumed | CLO transaction data (auth, clear, or reward) |
| `mls.HistoryEvent` | HistoryEvent Command | `/v1/history` write API call or MBus history event | merchantId, dealId, userId, eventType, eventDate, historyData |

### mls.VoucherSold Detail

- **Topic**: `mls.VoucherSold`
- **Trigger**: `jms.queue.mls.VoucherSold` MBus event consumed and entity validated as current in VIS
- **Payload**: Voucher UUID, merchant data, inventory unit data assembled by Sentinel
- **Consumers**: MLS Yang (primary); any service subscribed to the topic
- **Guarantees**: at-least-once (MBus message is not acknowledged if validation fails; retried after 15 minutes)

### mls.VoucherRedeemed Detail

- **Topic**: `mls.VoucherRedeemed`
- **Trigger**: `jms.queue.mls.VoucherRedeemed` MBus event consumed and entity validated as current in VIS
- **Payload**: Voucher UUID, redemption data assembled by Sentinel
- **Consumers**: MLS Yang (primary)
- **Guarantees**: at-least-once (same retry strategy as VoucherSold)

### mls.MerchantAccountChanged Detail

- **Topic**: `mls.MerchantAccountChanged`
- **Trigger**: `jms.queue.mls.SalesforceCreated` or `jms.queue.mls.SalesforceUpdate` MBus event consumed
- **Payload**: Salesforce account data, resolved merchant ID
- **Consumers**: MLS Yang (primary)
- **Guarantees**: at-least-once

### mls.CloTransaction Detail

- **Topic**: `mls.CloTransaction`
- **Trigger**: `jms.topic.clo.redemptions` or `jms.topic.clo.replay.redemptions` MBus topic event consumed
- **Payload**: CLO transaction type (auth/clear/reward), CLO data payload
- **Consumers**: MLS Yang (primary)
- **Guarantees**: at-least-once

### mls.HistoryEvent Detail

- **Topic**: `mls.HistoryEvent`
- **Trigger**: Inbound POST to `/v1/history` or a history MBus event
- **Payload**: All fields from `HistoryCreationMessage` (historyId, merchantId, dealId, userId, deviceId, clientId, eventDate, eventType, eventTypeId, userType, historyData)
- **Consumers**: MLS Yang (primary), if `sendHistoryEventToYang` feature flag is enabled
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.queue.mls.VoucherSold` | VoucherSold | VoucherSold flow processor | Validates VIS entity, publishes `mls.VoucherSold` Kafka command |
| `jms.queue.mls.VoucherRedeemed` | VoucherRedeemed | VoucherRedeemed flow processor | Validates VIS entity, publishes `mls.VoucherRedeemed` Kafka command |
| `jms.queue.mls.SalesforceCreated` | SalesforceAccountCreated | Salesforce flow processor | Resolves merchant account, publishes `mls.MerchantAccountChanged` Kafka command |
| `jms.queue.mls.SalesforceUpdate` | SalesforceAccountUpdated | Salesforce flow processor | Resolves merchant account, publishes `mls.MerchantAccountChanged` Kafka command |
| `jms.topic.clo.redemptions` | CloRedemption | CLO flow processor | Assembles CLO transaction command, publishes `mls.CloTransaction` Kafka command |
| `jms.topic.clo.replay.redemptions` | CloRedemptionReplay | CLO replay processor | Same as CLO redemption, used for replayed/backfilled events |

### VoucherSold / VoucherRedeemed Detail

- **Topic**: `jms.queue.mls.VoucherSold` / `jms.queue.mls.VoucherRedeemed`
- **Handler**: Typed `AbstractProcessor` registered by `MBusSourceManager` on startup
- **Idempotency**: Entity-version check against VIS ensures Sentinel only emits commands when the RO data source has caught up with the RW source; duplicate MBus delivery yields idempotent Kafka output
- **Error handling**: If VIS entity is not yet current (database replication lag), message is NOT acknowledged; MBus redelivers after 15 minutes. Persistent failures accumulate in `MlsSentinel-US_MBUS_CONSUMED` Nagios alert.
- **Processing order**: Unordered (concurrent processors per queue)

### CLO Redemption Detail

- **Topic**: `jms.topic.clo.redemptions`
- **Handler**: CLO flow processor (registered via `mbusConfiguration`)
- **Idempotency**: Depends on CLO transaction ID deduplication; no explicit Sentinel-side dedup documented
- **Error handling**: Standard MBus retry; persistent failures surface in Wavefront outgoing call rate alert
- **Processing order**: Unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| DLQ via `retryDLQs` endpoint | Any configured database | Configurable via `earliest`/`latest` time range | Monitored via `MlsSentinel-US_MBUS_CONSUMED` Nagios alert |

Dead-letter messages are stored in a named database (passed as `{database}` path param to `/trigger/retryDLQs/{database}`) and can be replayed via the trigger API. No external DLQ broker (e.g., separate Kafka DLQ topic) is evidenced.

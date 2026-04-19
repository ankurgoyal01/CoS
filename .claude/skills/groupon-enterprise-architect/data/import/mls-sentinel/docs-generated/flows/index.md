---
service: "mls-sentinel"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for MLS Sentinel.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Voucher Sold Processing](voucher-sold-processing.md) | event-driven | `jms.queue.mls.VoucherSold` MBus event | Consumes VoucherSold event, validates inventory freshness against VIS, publishes `mls.VoucherSold` Kafka command |
| [Voucher Redeemed Processing](voucher-redeemed-processing.md) | event-driven | `jms.queue.mls.VoucherRedeemed` MBus event | Consumes VoucherRedeemed event, validates inventory freshness against VIS, publishes `mls.VoucherRedeemed` Kafka command |
| [CLO Transaction Processing](clo-transaction-processing.md) | event-driven | `jms.topic.clo.redemptions` or `jms.topic.clo.replay.redemptions` MBus topic | Consumes CLO redemption event, assembles CLO transaction command, publishes `mls.CloTransaction` Kafka command |
| [Merchant Account Changed](merchant-account-changed.md) | event-driven | `jms.queue.mls.SalesforceCreated` or `jms.queue.mls.SalesforceUpdate` MBus event | Resolves merchant account from Salesforce event, publishes `mls.MerchantAccountChanged` Kafka command |
| [Inventory Update and Backfill](inventory-update-backfill.md) | event-driven / batch | MBus deal snapshot/update messages from Deal Catalog, or `POST /trigger/backfillRequest/{type}` | Fetches inventory product data, updates deal index DB, publishes `mls.BulletCreated` and `mls.MerchantFactChanged` commands |
| [Merchant History Write](merchant-history-write.md) | synchronous | `POST /v1/history` HTTP request | Validates and persists a history event to the History DB; optionally publishes `mls.HistoryEvent` Kafka command to Yang |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 4 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Inventory Update Flow** spans `continuumDealCatalogService`, `messageBus`, `continuumMlsSentinelService`, `continuumVoucherInventoryService`, `continuumInventoryService`, and `mlsSentinelDealIndexDb`. Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`.
- **Voucher Sold / Redeemed flows** span the voucher source system, `messageBus`, `continuumMlsSentinelService`, `continuumVoucherInventoryService`, and MLS Yang (via Kafka).
- All event-driven flows terminate by publishing to Kafka topics consumed by `continuumMlsYangService` (MLS Yang).

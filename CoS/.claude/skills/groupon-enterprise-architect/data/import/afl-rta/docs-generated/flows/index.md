---
service: "afl-rta"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for AFL RTA (Affiliate Real-Time Attribution).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Click Attribution Flow](click-attribution-flow.md) | event-driven | `externalReferrer` event consumed from Kafka `janus-tier2` | Attributes an external referrer click event to a marketing channel and stores the click record in MySQL |
| [Order Attribution Flow](order-attribution-flow.md) | event-driven | `dealPurchase` event consumed from Kafka `janus-tier2` | Correlates a deal purchase with stored click history, enriches the attributed order, and publishes it to MBus |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

Both flows originate from the Janus data-engineering pipeline, which produces all inbound events on the `janus-tier2` Kafka topic. The Order Attribution Flow crosses into `continuumOrdersService` and `continuumMarketingDealService` for enrichment, then publishes to `messageBus` where `afl-3pgw` (Commission Junction gateway) consumes the attributed order.

- Architecture dynamic view for Click Attribution: `dynamic-afl-rta-click-aflRta_clickAttribution`
- Architecture dynamic view for Order Attribution: `dynamic-afl-rta-order-aflRta_clickAttribution`

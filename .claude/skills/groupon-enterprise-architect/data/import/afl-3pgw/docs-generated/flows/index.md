---
service: "afl-3pgw"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Affiliates 3rd Party Gateway (afl-3pgw).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Real-Time Order Registration](rta-order-registration.md) | event-driven | MBUS message on `jms.topic.afl_rta.attribution.orders` | Receives an attributed order event, enriches it with order/deal/incentive data, and submits to CJ or Awin in real time |
| [CJ Reconciliation and Correction Submission](cj-reconciliation-correction.md) | scheduled | Quartz scheduler (daily) | Computes missed/cancelled/refunded/charged-back orders and submits correction batches to Commission Junction |
| [CJ Report and Commission Processing](cj-report-processing.md) | scheduled | Quartz scheduler (daily) | Fetches CJ performance reports and commission data; persists to local database |
| [Awin Transaction Processing](awin-transaction-processing.md) | scheduled | Quartz scheduler (periodic) | Fetches Awin network reports, processes transaction approvals and corrections |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The Real-Time Order Registration flow spans multiple services and is documented as a Structurizr dynamic view:

- Architecture dynamic view: `dynamic-rta-order-registration-flow` (see `architecture/views/dynamics/rta-order-registration.dsl`)
- Participants: `messageBus` → `continuumAfl3pgwService` → `continuumOrdersService`, `continuumMarketingDealService`, `continuumIncentiveService`, `cjAffiliate`, `awinAffiliate`, `continuumAfl3pgwDatabase`

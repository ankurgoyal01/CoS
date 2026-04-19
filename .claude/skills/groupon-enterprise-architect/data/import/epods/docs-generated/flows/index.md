---
service: "epods"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for EPODS — Exchange Partner Order Data Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Booking Flow](booking-flow.md) | synchronous | API call from Booking Tool or Orders | End-to-end creation, retrieval, and cancellation of a booking through a partner system |
| [Webhook Processing Flow](webhook-processing-flow.md) | event-driven | Inbound HTTP POST from partner system | Reception and processing of partner-initiated webhook events (booking changes, availability updates) |
| [Availability Sync Flow](availability-sync-flow.md) | scheduled | Quartz scheduler (periodic) | Polling partner systems for availability data and publishing AvailabilityUpdate events |
| [Transaction Flow](transaction-flow.md) | event-driven | VoucherMessageHandler event from message bus | Processing voucher lifecycle events and coordinating partner-side redemption or cancellation |
| [Mapping Lifecycle Flow](mapping-lifecycle-flow.md) | synchronous | API call or sync trigger | Creating and maintaining bi-directional ID mappings between Groupon entities and partner-system identifiers |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Booking Flow** spans `continuumEpodsService`, external partner APIs (`mindbodyApi`, `bookerApi`), `continuumCalendarService`, `continuumOrdersService`, and `messageBus`. See [Booking Flow](booking-flow.md).
- The **Availability Sync Flow** spans `continuumEpodsService`, external partner APIs, `continuumEpodsRedis`, and `messageBus`. See [Availability Sync Flow](availability-sync-flow.md).
- The **Transaction Flow** spans `messageBus`, `continuumEpodsService`, external partner APIs, `continuumEpodsPostgres`, and `continuumOrdersService`. See [Transaction Flow](transaction-flow.md).
- Central architecture dynamic views: `dynamic-epods` (not yet defined in model — see `structurizr/import/epods/architecture/views/dynamics.dsl`).

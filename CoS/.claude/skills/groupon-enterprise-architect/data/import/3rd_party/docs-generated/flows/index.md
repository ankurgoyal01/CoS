---
service: "online_booking_3rd_party"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Online Booking 3rd Party.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Place Polling](merchant-place-polling.md) | scheduled | Resque scheduler (cron) | Detects pollable merchant-place mappings and triggers provider synchronization cycles |
| [Webhook Processing](webhook-processing.md) | event-driven | Inbound HTTP POST from provider | Ingests booking or availability push events from third-party provider systems |
| [Appointment Event Consumption](appointment-event-consumption.md) | event-driven | Message Bus — `BookingEngine.AppointmentEngine.Events` | Consumes appointment lifecycle events and applies provider sync actions |
| [Booking Tool Sync](booking-tool-sync.md) | event-driven | Message Bus — `BookingTool.Services.BookingEngine` | Consumes Booking Tool service events to reconcile mapping and provider state |
| [Service Mapping Lifecycle](service-mapping-lifecycle.md) | synchronous | API call — merchant operator | Creates, updates, and deletes service-level mappings between Groupon options and provider services |
| [Authorization Flow](authorization-flow.md) | synchronous | API call — merchant operator | Initiates and manages provider OAuth/API key authorization for a merchant place |
| [Sanity Check](sanity-check.md) | synchronous | Manual / monitoring system | Executes smoke tests to verify end-to-end integration health across all key dependencies |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |
| Event-driven (inbound push) | 1 |

## Cross-Service Flows

- **Merchant Mapping Request**: Architecture dynamic view `dynamic-merchant-mapping-request-flow` — spans `continuumOnlineBooking3rdPartyApi`, `continuumOnlineBooking3rdPartyMysql`, `continuumAvailabilityEngine`, `continuumAppointmentsEngine`, `continuumOnlineBooking3rdPartyRedis`
- **Provider Sync from Event**: Architecture dynamic view `dynamic-provider-workerProviderSync-from-inbound-event-flow` — spans `continuumOnlineBooking3rdPartyWorkers`, `messageBus`, `continuumOnlineBooking3rdPartyMysql`, `emeaBtos`, `continuumAvailabilityEngine`, `continuumAppointmentsEngine`

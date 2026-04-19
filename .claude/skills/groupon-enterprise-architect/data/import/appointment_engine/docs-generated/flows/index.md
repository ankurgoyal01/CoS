---
service: "appointment_engine"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Appointment Engine.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Reservation Request Lifecycle](reservation-request-lifecycle.md) | synchronous | Consumer submits appointment booking via API | Full lifecycle of a reservation request from creation to confirmation or decline |
| Availability Event Processing | event-driven | Message Bus event from Availability Engine | Processes availability slot changes and updates reservation state accordingly |
| Order Status Change Processing | event-driven | Message Bus event from Orders / Inventory Services | Syncs appointment state with order and voucher inventory status changes |
| GDPR Data Deletion | event-driven | `gdpr.account.v1.erased` Message Bus event | Deletes or anonymizes personal data for a GDPR erasure request |
| Appointment Confirmation and Reschedule | synchronous | Merchant API action (confirm / decline / reschedule) | Merchant-initiated state transitions on confirmed appointments |
| Periodic Data Cleanup | scheduled | resque-scheduler cron trigger | Background cleanup of stale reservation and appointment records |

> Flows without links are documented in the table above but flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Reservation Request Lifecycle** flow spans `continuumAppointmentEngineApi` → Availability Engine → Online Booking Notifications → Message Bus. See [Reservation Request Lifecycle](reservation-request-lifecycle.md).
- The **Order Status Change Processing** flow spans Message Bus → `continuumAppointmentEngineUtility` → `continuumAppointmentEngineApi` → `continuumAppointmentEngineMySql`.
- The central architecture dynamic view `appointment-lifecycle` covers the full cross-service appointment booking flow.

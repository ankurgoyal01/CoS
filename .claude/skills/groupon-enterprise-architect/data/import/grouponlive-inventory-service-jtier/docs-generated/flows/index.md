---
service: "grouponlive-inventory-service-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Groupon Live Inventory Service JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Seat Reservation](seat-reservation.md) | synchronous | API call (`POST /v1/reservations`) | Creates a seat hold with the appropriate third-party ticketing partner and records the reservation in MySQL |
| [Ticket Purchase](ticket-purchase.md) | synchronous | API call (`POST /v1/purchases`) | Converts a confirmed reservation into a completed ticket purchase against the partner and records the order |
| [Async Purchase via Quartz](async-purchase-job.md) | asynchronous | Quartz job enqueue (`POST /enqueue_job`) | Executes the purchase flow asynchronously through the `PurchaseJob` Quartz job |
| [Event Availability Check](event-availability-check.md) | synchronous | API call (`GET /v1/products/{productUuid}/events/availability`) | Fetches live seat availability for all events of a product directly from the partner API |
| [Provenue Vendor Sync](provenue-vendor-sync.md) | scheduled | Quartz scheduler (periodic) | Synchronizes Provenue vendor API version metadata by pinging the Provenue API and updating the `venues_credentials` store |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Seat Reservation** and **Ticket Purchase** flows involve outbound calls to external partner APIs (Provenue, Telecharge) and a callback to the internal `glive-inventory-rails` service to synchronize customer and event state.
- The **Async Purchase via Quartz** flow decouples the purchase request from the HTTP response cycle using an in-process Quartz scheduler backed by the MySQL Quartz job store.
- Cross-service dynamic views for these flows are not yet defined in the central architecture model (see `architecture/views/dynamics.dsl` — no dynamic views defined).

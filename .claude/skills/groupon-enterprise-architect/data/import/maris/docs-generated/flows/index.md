---
service: "maris"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for MARIS (Hotel Inventory and Reservation Integration Service).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotel Room Availability](hotel-room-availability.md) | synchronous | API call — GET `/getaways/v2/marketrate/hotels/{id}/rooms` or GET `/inventory/v1/products/availability` | Fetches real-time hotel room availability and pricing from Expedia Rapid and returns enriched results to callers |
| [Hotel Reservation Booking](hotel-reservation-booking.md) | synchronous | API call — POST `/inventory/v1/reservations` | Creates a hotel reservation via Expedia Rapid, persists reservation and unit records, and initiates payment authorization with the Orders Service |
| [Unit Status Change Processing](unit-status-change-processing.md) | event-driven | `Orders.StatusChanged` MBus event | Consumes order status change events and applies corresponding unit and reservation lifecycle transitions in MARIS |
| [Unit Redemption](unit-redemption.md) | synchronous | API call — POST `/inventory/v1/units/{id}/redemption` | Records the redemption of a hotel inventory unit and updates its state in `marisMySql` |
| [GDPR Data Erasure](gdpr-data-erasure.md) | event-driven | `gdpr.erased` MBus event | Erases personally identifiable data for a given subject from `marisMySql` and publishes a `gdpr.erased.complete` confirmation event |
| [Scheduled Refund Sync](scheduled-refund-sync.md) | scheduled | Quartz scheduler (periodic) | Batch job that identifies reservations requiring refund processing and synchronizes refund state with Expedia and the Orders Service |
| [Scheduled Cancellation Processing](scheduled-cancellation-processing.md) | scheduled | Quartz scheduler (periodic) | Batch job that processes pending hotel reservation cancellations with Expedia Rapid and updates unit state in `marisMySql` |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The following flows span multiple services and are relevant to the broader Continuum architecture:

- **Hotel Reservation Booking** spans `continuumTravelInventoryService`, Expedia Rapid API, `continuumOrdersService`, and `marisMySql`. See [Hotel Reservation Booking](hotel-reservation-booking.md).
- **Unit Status Change Processing** is driven by events from `continuumOrdersService` via `messageBus`. See [Unit Status Change Processing](unit-status-change-processing.md).
- **GDPR Data Erasure** is part of the platform-wide GDPR erasure orchestration flow. See [GDPR Data Erasure](gdpr-data-erasure.md).

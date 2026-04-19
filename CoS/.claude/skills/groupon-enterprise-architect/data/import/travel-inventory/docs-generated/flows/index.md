---
service: "travel-inventory"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Getaways Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotel Availability Check](hotel-availability-check.md) | synchronous | API call -- GET availability summary/detail/calendar | Consumer or shopping service queries hotel availability and pricing for given dates and parameters |
| [Reservation Creation](reservation-creation.md) | synchronous | API call -- POST /v2/getaways/inventory/reservations | Consumer books a hotel room, persisting the reservation and notifying Backpack and downstream systems |
| [Rate Plan Management](rate-plan-management.md) | synchronous | API call -- Extranet rate plan CRUD endpoints | Merchant or Extranet UI creates, updates, or retrieves rate plans with cache invalidation |
| [Daily Inventory Report Generation](daily-inventory-report-generation.md) | batch | Scheduled -- Cron triggers /v2/getaways/inventory/reporter/generate | Python cron triggers the service to generate a daily inventory report CSV and transfer it via SFTP |
| [Backpack Reservation Sync](backpack-reservation-sync.md) | asynchronous | Event-driven -- reservation/cancel events via MBus | Reservation and cancellation events are published to MBus and consumed by Backpack Reservation Service for itinerary sync |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Hotel Availability Check** spans `continuumTravelInventoryService`, `continuumBackpackReservationService` (via Backpack Availability Cache), `continuumContentService`, `continuumVoucherInventoryService`, and Forex Service -- see [Hotel Availability Check](hotel-availability-check.md).
- **Reservation Creation** spans `continuumTravelInventoryService` and `continuumBackpackReservationService` -- see [Reservation Creation](reservation-creation.md).
- **Daily Inventory Report Generation** spans `continuumTravelInventoryCron`, `continuumTravelInventoryService`, and `continuumAwsSftpTransfer` -- see [Daily Inventory Report Generation](daily-inventory-report-generation.md).
- **Backpack Reservation Sync** spans `continuumTravelInventoryService` and `continuumBackpackReservationService` via `messageBus` -- see [Backpack Reservation Sync](backpack-reservation-sync.md).

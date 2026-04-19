---
service: "glive-inventory-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for GLive Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Ticket Inventory Creation](ticket-inventory-creation.md) | synchronous | API request from Admin UI or internal service | Creates a new ticket product with events and availability in MySQL, syncs with third-party provider, invalidates Varnish cache, and publishes inventory event to MessageBus |
| [Third-Party Ticket Purchase](third-party-ticket-purchase.md) | synchronous + asynchronous | API request from Groupon Website during checkout | Orchestrates ticket purchase across reservation hold, GTX transaction, third-party provider order placement (Ticketmaster/AXS/Telecharge/ProVenue), and inventory update |
| [Event Reservation Flow](event-reservation-flow.md) | synchronous | API request from Groupon Website or Admin UI | Creates, holds, and manages a ticket reservation with expiry, coordinating with third-party provider and Redis locking |
| [Background Job Processing](background-job-processing.md) | asynchronous / batch | Resque/ActiveJob job enqueue from API controllers or scheduled triggers | Worker tier pulls jobs from Redis queues and executes third-party integrations, cache refresh, GDPR processing, reporting, and inventory updates |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Third-Party Ticket Purchase](third-party-ticket-purchase.md) flow spans `continuumGliveInventoryService`, `continuumGtxService`, and one of the four third-party providers (`continuumTicketmasterApi`, `continuumAxsApi`, `continuumTelechargePartner`, `continuumProvenuePartner`), plus `messageBus` for event publishing. Refer to the central architecture model for the full cross-service dynamic view once defined.
- The [Background Job Processing](background-job-processing.md) flow spans `continuumGliveInventoryWorkers`, `continuumGliveInventoryService` (shared codebase), `continuumGliveInventoryDb`, `continuumGliveInventoryRedis`, and external providers. Worker processes share the same external client component (`continuumGliveInventoryService_externalClients`).
- No dynamic views are currently defined in `architecture/views/dynamics.dsl` for this service.

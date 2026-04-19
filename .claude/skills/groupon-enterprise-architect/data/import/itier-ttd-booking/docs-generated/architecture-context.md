---
service: "itier-ttd-booking"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTtdBookingService"]
---

# Architecture Context

## System Context

`itier-ttd-booking` is a container within the `continuumSystem` software system — Groupon's core commerce engine. It sits at the checkout boundary of the TTD/GLive vertical, receiving browser requests for booking and reservation pages and orchestrating data assembly from upstream Continuum platform services. It does not own persistent data; it depends on `continuumDealCatalogService` (via `apiProxy`) for deal metadata, `continuumUsersService` for authenticated user context, and `continuumGLiveInventoryService` for availability and reservation state.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| TTD Booking ITier Service | `continuumTtdBookingService` | Backend service | Node.js (ITier) | Node.js 16, itier-server 7.8.0 | Serves GLive booking widget, reservation spinner/status, and TTD pass content |
| API Proxy | `apiProxy` | Gateway | Stub | — | Service-client request gateway used by continuumTtdBookingService for downstream calls |
| Deal Catalog Service | `continuumDealCatalogService` | Backend service | Stub | — | Provides deal metadata and option/inventory-service attributes |
| Users Service | `continuumUsersService` | Backend service | Stub | — | Provides authenticated user context for booking and reservations |
| GLive Inventory Service | `continuumGLiveInventoryService` | Backend service | Stub | — | Manages GLive availability, reservation creation, and reservation status |

## Components by Container

### TTD Booking ITier Service (`continuumTtdBookingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Routing Layer (`itierTtdBooking_webRouting`) | Defines route handlers for booking, reservation, and ttd-pass endpoints | Express/Keldor routes |
| GLive Booking Redesign Controller (`gliveBookingRedesignController`) | Builds booking widget HTML/JSON assets and orchestrates availability payload assembly | Controller |
| Reservation Controller (`reservationController`) | Handles reservation page rendering and status polling endpoints | Controller |
| Reservation Workflow (`reservationWorkflow`) | Implements create/poll reservation orchestration and redirect decision logic | Domain workflow |
| GAPI Wrapper Adapter (`gapiWrapperAdapter`) | Wraps deal/user fetches from Groupon V2 and user auth modules | Adapter |
| GLive Inventory Adapter (`gliveInventoryAdapter`) | Calls GLive inventory APIs for availability, reservation create/status, and customer orders | Adapter |
| TTD Pass Controller (`ttdPassController`) | Renders ttd-pass page and card responses | Controller |
| TTD Pass Integration Adapter (`ttdPassAdapter`) | Calls Alligator Cards API and card rendering utilities | Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTtdBookingService` | `apiProxy` | Sends service-client requests through API proxy | HTTPS |
| `continuumTtdBookingService` | `continuumDealCatalogService` | Reads deal metadata and option inventory-service attributes | HTTPS/JSON |
| `continuumTtdBookingService` | `continuumUsersService` | Retrieves authenticated user context for booking/reservations | HTTPS/JSON |
| `continuumTtdBookingService` | `continuumGLiveInventoryService` | Reads availability, creates reservations, and polls reservation state | HTTPS/JSON |
| `itierTtdBooking_webRouting` | `gliveBookingRedesignController` | Routes booking widget endpoints | Direct |
| `itierTtdBooking_webRouting` | `reservationController` | Routes reservation and status endpoints | Direct |
| `itierTtdBooking_webRouting` | `ttdPassController` | Routes ttd-pass endpoint | Direct |
| `gliveBookingRedesignController` | `gapiWrapperAdapter` | Loads deal and user context | Direct |
| `gliveBookingRedesignController` | `gliveInventoryAdapter` | Loads GLive availability and event data | Direct |
| `reservationController` | `reservationWorkflow` | Executes reservation orchestration | Direct |
| `reservationWorkflow` | `gapiWrapperAdapter` | Reads deal and user context | Direct |
| `reservationWorkflow` | `gliveInventoryAdapter` | Creates reservations and polls status | Direct |
| `ttdPassController` | `ttdPassAdapter` | Retrieves and renders TTD pass cards | Direct |

## Architecture Diagram References

- System context: `contexts-continuum-ttd-booking`
- Container: `containers-continuum-ttd-booking`
- Component: `components-continuum-ttd-booking-service`
- Dynamic (booking reservation flow): `dynamic-booking-reservation-reservationWorkflow`

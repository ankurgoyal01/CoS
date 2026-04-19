---
service: "online_booking_api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumOnlineBookingApi"
  containers: [continuumOnlineBookingApi]
---

# Architecture Context

## System Context

The Online Booking API sits within the **Continuum** platform as the primary external-facing HTTP gateway for all online booking operations. It is consumed by CS tooling (Zendesk application), merchant-facing portals, and consumer booking UIs. The service has no database of its own; it is a pure orchestration layer that calls eight internal Continuum services to fulfil each request, aggregates and transforms their responses, and presents a stable versioned JSON API contract.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Online Booking API | `continuumOnlineBookingApi` | Service / API | Ruby on Rails | ~> 5.0 | Versioned REST API that orchestrates booking, reservation, place, and merchant setting workflows |

## Components by Container

### Online Booking API (`continuumOnlineBookingApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`onlineBookingApiControllers`) | Expose versioned public endpoints; validate request parameters; coordinate request/response flow | Rails Controllers (v2 and v3 namespaces) |
| Response Transformations (`onlineBookingApiTransformations`) | Adapt raw downstream service payloads into stable, versioned API response schemas | Ruby Modules |
| Reservations Helper (`onlineBookingApiReservationsHelper`) | Map business-level status transitions (e.g., `confirmed`, `merchant_declined`) into the correct downstream mutation API calls | Ruby Helper |
| Service Discovery API Clients (`onlineBookingApiServiceClients`) | Typed, configured HTTP client instances for all eight downstream service dependencies using `api_clients` with service-discovery URLs | ServiceDiscoveryClient + ApiClients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOnlineBookingApi` | `continuumAppointmentsEngine` | Reads and mutates reservations, requests, places, and contact attempts | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumAvailabilityEngine` | Reads option/place availability and override windows | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumCalendarService` | Fetches option service details and place reachability data | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumDealCatalogService` | Resolves deal metadata for reservation and request responses | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumM3PlacesService` | Reads place metadata for option enrichment | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumOnlineBookingNotifications` | Reads and updates notification settings and place notification config | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumUsersService` | Resolves consumer profile details (name, phone) for reservation request listings | HTTP/JSON |
| `continuumOnlineBookingApi` | `continuumVoucherInventoryService` | Fetches voucher units for reservation enrichment | HTTP/JSON |
| `onlineBookingApiControllers` | `onlineBookingApiTransformations` | Transforms downstream entities into stable API schemas | Direct (Ruby) |
| `onlineBookingApiControllers` | `onlineBookingApiReservationsHelper` | Dispatches reservation lifecycle actions | Direct (Ruby) |
| `onlineBookingApiControllers` | `onlineBookingApiServiceClients` | Invokes downstream services through typed clients | Direct (Ruby) |
| `onlineBookingApiReservationsHelper` | `onlineBookingApiServiceClients` | Executes reservation action API calls | Direct (Ruby) |

## Architecture Diagram References

- Component: `components-online-booking-api`

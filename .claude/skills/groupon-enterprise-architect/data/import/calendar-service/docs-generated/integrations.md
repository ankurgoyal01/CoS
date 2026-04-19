---
service: "calendar-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

Calendar Service maintains seven downstream dependencies: three are external partner/platform systems (EPODS, Third-Party Booking, Appointments Service) and four are internal Continuum services (Voucher Inventory, Third-Party Inventory, M3 Merchant, and MBus). All HTTP calls are made via `calendarService_externalClients` using JTier Retrofit clients backed by `jtier-resilience4j` for circuit breaking and retry. Async integration with the `availabilityEngineEventsBus` is handled by `messageBusAdapters`. External stubs exist for EPODS, Third-Party Booking, Appointments Service, and M3 Place in the federated validation DSL, indicating those targets are not yet in the central federated model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| EPODS | REST | Create, check, and cancel external booking partner reservations | yes | `continuumEpodsService` |
| Third-Party Booking Service | REST | Adapter for third-party booking platform APIs | yes | `onlineBookingThirdPartyService` (stub) |
| Appointments Service | REST | Fetch and sync appointment-backed booking data | yes | `appointmentEngineService` (stub) |
| M3 Place Service | REST | Fetch place metadata and open hours for availability compilation | no | `m3PlaceService` (stub) |

### EPODS Detail

- **Protocol**: REST
- **Base URL / SDK**: JTier Retrofit client via `calendarService_externalClients`; called by both `continuumCalendarServiceCalSer` (synchronous booking path) and `continuumCalendarUtility` (async sync jobs)
- **Auth**: Internal service auth via JTier conventions
- **Purpose**: Calendar Service creates EPODS bookings when a unit booking is confirmed, checks booking status for sync operations, and cancels EPODS bookings when a booking is declined
- **Failure mode**: Circuit breaker via `jtier-resilience4j`; booking creation failure results in an error response to the caller; sync failures are retried by Quartz jobs in `continuumCalendarUtility`
- **Circuit breaker**: Yes — `jtier-resilience4j` 1.4.6

### Third-Party Booking Service Detail

- **Protocol**: REST
- **Base URL / SDK**: JTier Retrofit client via `calendarService_externalClients`
- **Auth**: Internal service auth via JTier conventions
- **Purpose**: Routes booking operations to third-party booking platform partners when the unit's booking type requires it
- **Failure mode**: Circuit breaker via `jtier-resilience4j`; failure surfaces as booking creation error
- **Circuit breaker**: Yes — `jtier-resilience4j` 1.4.6

### Appointments Service Detail

- **Protocol**: REST
- **Base URL / SDK**: JTier Retrofit client via `calendarService_externalClients`
- **Auth**: Internal service auth via JTier conventions
- **Purpose**: Fetches appointment data for appointment-backed bookings; appointment events are also consumed from MBus to keep booking state synchronized
- **Failure mode**: Circuit breaker via `jtier-resilience4j`; graceful degradation where appointment data is unavailable
- **Circuit breaker**: Yes — `jtier-resilience4j` 1.4.6

### M3 Place Service Detail

- **Protocol**: REST
- **Base URL / SDK**: JTier Retrofit client via `calendarService_externalClients` (`availabilityCore` component)
- **Auth**: Internal service auth via JTier conventions
- **Purpose**: Fetches place metadata and merchant open hours used during availability compilation
- **Failure mode**: Availability compilation may produce incomplete or stale results if M3 Place is unavailable; circuit breaker prevents cascading
- **Circuit breaker**: Yes — `jtier-resilience4j` 1.4.6

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory Service | REST | Validates and queries voucher inventory during booking creation and confirmation | `continuumVoucherInventoryService` |
| Third-Party Inventory Service | REST | Queries third-party inventory availability for third-party-backed bookings | `continuumThirdPartyInventoryService` |
| M3 Merchant Service | REST | Fetches merchant metadata used in booking and availability context | `continuumM3MerchantService` |
| MBus (Availability Events Bus) | MBus | Publishes `AvailabilityRecordChanged` and `ProductAvailabilitySegments`; consumes `AvailabilityRecordChanged`, `ProductAvailabilitySegments`, and `AppointmentEvents` | `availabilityEngineEventsBus` (stub) |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include booking surfaces, checkout orchestration, and CX tooling that call the `/v1/*` REST endpoints.

## Dependency Health

- All outbound HTTP dependencies use JTier Retrofit clients wrapped with `jtier-resilience4j` 1.4.6 circuit breakers
- EPODS failures on the synchronous booking path surface as API errors; asynchronous EPODS sync failures in `continuumCalendarUtility` are retried via Quartz job scheduling
- MBus consumption failures rely on platform-level MBus retry and dead-letter handling
- No explicit health check endpoints for downstream dependencies are declared in the architecture DSL

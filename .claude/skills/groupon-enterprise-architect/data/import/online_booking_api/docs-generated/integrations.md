---
service: "online_booking_api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 8
---

# Integrations

## Overview

The Online Booking API depends on eight internal Continuum services. All integrations use synchronous HTTP/JSON calls via the `api_clients` gem with service-discovery-resolved base URLs configured per environment in `service_discovery_client.yml`. Connect timeouts are typically 2–10 seconds; request timeouts are 10–30 seconds depending on environment. There are no external third-party integrations owned directly by this service.

## External Dependencies

> No evidence found in codebase. This service has no direct external (third-party) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Appointments Engine (`appointment_engine`) | HTTP/JSON | Primary data store proxy for reservations, reservation requests, places, contact attempts, and place metrics | `continuumAppointmentsEngine` |
| Availability Engine (`availability_engine`) | HTTP/JSON | Computes and returns available time segments per option; manages override windows | `continuumAvailabilityEngine` |
| Calendar Service (`calendar-service`) | HTTP/JSON | Provides option service details (engine type, duration, place, merchant IDs), place-level reachability hours, and additional attribute definitions | `continuumCalendarService` |
| Deal Catalog (`deal-catalog`) | HTTP/JSON | Resolves deal metadata (deal UUID, options, Salesforce ID) for enriching reservation and request responses | `continuumDealCatalogService` |
| M3 Place Read Service (`m3_placeread`) | HTTP/JSON | Reads place metadata including location country for option booking settings enrichment | `continuumM3PlacesService` |
| Online Booking Notifications (`online_booking_notifications`) | HTTP/JSON | Reads and updates per-place and per-merchant notification channel settings | `continuumOnlineBookingNotifications` |
| Users Service (`users-service`) | HTTP/JSON | Resolves consumer profile details (first name, last name, phone number) for reservation request listings | `continuumUsersService` |
| Voucher Inventory Service (`voucher-inventory`) | HTTP/JSON | Fetches voucher unit details when `include_voucher=true` is requested on a reservation show call | `continuumVoucherInventoryService` |

### Appointments Engine Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://booking-engine-appointments-vip.snc1/`
- **Auth**: None (internal network)
- **Purpose**: All reservation CRUD, reservation request confirm/decline/update, contact attempt logging, place settings read/write, place metrics
- **Failure mode**: HTTP error code is proxied to the caller; timeout returns HTTP 408
- **Circuit breaker**: No evidence found in codebase

### Availability Engine Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://booking-engine-availability-vip.snc1/`
- **Auth**: None (internal network)
- **Purpose**: Returns available time segments for a given option and time window; used by the `GET /v3/options/{id}/availability` endpoint
- **Failure mode**: HTTP 404 from upstream results in HTTP 404 to caller
- **Circuit breaker**: No evidence found in codebase

### Calendar Service Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://booking-engine-calendar-service-vip.snc1/`
- **Auth**: None (internal network)
- **Purpose**: Fetches `optionService` data (engine type, duration, place/merchant IDs), place reachability hours via `next_reachable_hour`
- **Failure mode**: Exceptions caught and treated as absent service; falls back to reservations-only path in `local_booking_settings`
- **Circuit breaker**: No evidence found in codebase

### Deal Catalog Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://deal-catalog.snc1/deal_catalog/`
- **Auth**: `clientId` query parameter via `DEAL_CATALOG_CLIENT_ID` environment variable
- **Purpose**: Resolves deal UUID to deal object (options, Salesforce ID) for enriching responses
- **Failure mode**: Errors caught per parallel group; missing deal data results in partial response
- **Circuit breaker**: No evidence found in codebase

### M3 Place Read Service Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://place-service.snc1/placereadservice/`
- **Auth**: `client_id` query parameter via `PLACE_SERVICE_CLIENT_ID` environment variable
- **Purpose**: Returns location metadata (specifically country code) for a place; used in `local_booking_settings` to enrich option response
- **Failure mode**: Exceptions caught; country resolves to `nil` if unavailable
- **Circuit breaker**: No evidence found in codebase

### Users Service Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `https://users-service-app-vip.snc1/users/v1/`
- **Auth**: `X-Api-Key` header via `USERS_SERVICE_HEADERS_X_API_KEY` environment variable
- **Purpose**: Resolves consumer UUIDs to profile objects (first name, last name) for reservation request listings
- **Failure mode**: Errors caught per parallel group; missing user data results in partial response
- **Circuit breaker**: No evidence found in codebase

### Voucher Inventory Service Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://vis-vip.snc1/`
- **Auth**: `clientId` query parameter via `VOUCHER_INVENTORY_CLIENT_ID` environment variable
- **Purpose**: Fetches voucher units when explicitly requested on `GET /v3/reservations/{id}`
- **Failure mode**: Errors caught; voucher data absent from response if unavailable
- **Circuit breaker**: No evidence found in codebase

### Online Booking Notifications Detail

- **Protocol**: HTTP/JSON
- **Base URL (production snc1)**: `http://booking-engine-notifications-vip.snc1/`
- **Auth**: None (internal network)
- **Purpose**: Provides and updates merchant and place notification channel configurations
- **Failure mode**: HTTP error proxied to caller
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on `.service.yml`, the service is consumed by Zendesk CS tooling (identified by `client_id` + HMAC authentication), merchant booking portals, and consumer-facing booking flows.

## Dependency Health

All service calls are made through the `api_clients` gem using `ApiClients.in_parallel` for concurrent calls where possible. Each parallel group catches errors independently (`catch_errors: false` or `group_errors: false`), allowing partial success responses when non-critical dependencies fail. Connect timeouts are 2 seconds; request timeouts are 10–30 seconds depending on environment. Timeout responses from downstream result in HTTP 408 being returned to the caller.

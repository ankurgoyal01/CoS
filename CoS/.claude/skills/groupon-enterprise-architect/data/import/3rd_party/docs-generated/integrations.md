---
service: "online_booking_3rd_party"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 10
---

# Integrations

## Overview

`online_booking_3rd_party` has one external dependency (third-party provider APIs, aggregated as `emeaBtos`) and ten internal Continuum platform dependencies. All internal integrations use HTTP/JSON over the Groupon platform client layer. The Message Bus (STOMP/JMS) is used for async event integration with Appointment Engine and Booking Tool.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| 3rd-Party Provider APIs (Xola, Genbook, etc.) | rest | Fetches provider service/booking/availability changes; relays booking lifecycle actions | yes | `emeaBtos` |

### EMEA BTOS / Provider APIs Detail

- **Protocol**: HTTP/JSON (REST)
- **Base URL / SDK**: Provider-specific API endpoints managed per-provider configuration
- **Auth**: Per-provider OAuth tokens / API keys stored in `access_tokens` table
- **Purpose**: The primary integration target — all outbound booking creation, availability polling, and booking lifecycle actions are relayed to provider APIs through this dependency
- **Failure mode**: Worker sync cycle fails; Resque retries with backoff; MySQL records sync failure state; events not published until sync succeeds
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Appointment Engine | rest + mbus | Creates/updates reservations; receives appointment lifecycle events | `continuumAppointmentsEngine` |
| Availability Engine | rest | Reads/upserts place/service state and ingests availability snapshots | `continuumAvailabilityEngine` |
| Users Service | rest | Fetches user/account data for booking workflows | `continuumUsersService` |
| Deal Catalog | rest | Fetches and updates deal product metadata | `continuumDealCatalogService` |
| Deal Management API | rest | Reads and updates inventory product details | `continuumDealManagementApi` |
| Calendar Service | rest | Uses legacy calendar/place/service APIs for compatibility paths | `continuumCalendarService` |
| Voucher Inventory API | rest | Validates and redeems voucher inventory units | `continuumVoucherInventoryApi` |
| Orders Service | rest | Reads order context for voucher-linked reservation flows | `continuumOrdersService` |
| Merchant Booking Tool | mbus | Consumes booking and service events via platform topics | `continuumMerchantBookingTool` |
| Message Bus | mbus (STOMP/JMS) | Consume BookingTool/AppointmentEngine topics; publish BookingEngine.3rdParty events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumers based on event and API patterns:
- Booking Tool — pushes booking and service events consumed by this service
- Appointment Engine — pushes appointment lifecycle events consumed by this service

## Dependency Health

- Redis health is checked as a liveness/readiness probe by the API container
- External provider API failures cause worker sync cycle failures with Resque retry
- No circuit breaker configuration confirmed from inventory — failures propagate as exceptions subject to Resque retry logic

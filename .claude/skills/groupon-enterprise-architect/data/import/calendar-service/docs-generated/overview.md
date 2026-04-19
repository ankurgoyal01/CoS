---
service: "calendar-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Booking / Calendar"
platform: "Continuum"
team: "BookingEngine"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.15.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Calendar Service Overview

## Purpose

Calendar Service is the Continuum platform's authoritative service for booking calendar management, availability computation, and appointment orchestration. It exposes REST APIs consumed by downstream booking surfaces to query availability windows, create and manage bookings, and synchronize reservation state with external booking partners (EPODS, third-party booking). Background workers handle asynchronous availability compilation and scheduled synchronization jobs independent of the API request path.

## Scope

### In scope

- Managing booking availability windows and time-range queries via `/v1/services/availability`
- Ingesting raw availability data from external sources via `/v1/services/{id}/ingest_availability`
- CRUD lifecycle for bookings at `/v1/units/bookings` and related sub-resources
- Booking confirmation, decline, and sync operations (`/v1/bookings/{id}/sync`, `/v1/bookings/{id}/confirm`, `/v1/bookings/{id}/decline`)
- Product availability segment management at `/v1/products/segments`
- CX-facing booking endpoints at `/v1/cx/*`
- Place and merchant configuration sync (`/v1/merchants/{id}/places/{id}/sync`)
- Publishing `AvailabilityRecordChanged` and `ProductAvailabilitySegments` events to MBus
- Consuming `AvailabilityRecordChanged`, `ProductAvailabilitySegments`, and `AppointmentEvents` from MBus
- Background Quartz job execution for EPODS synchronization, cleanup, and redemption workflows
- Redis-backed caching of hot availability and booking lookups

### Out of scope

- Merchant onboarding and place configuration (owned by M3 Place / M3 Merchant services)
- Voucher and inventory lifecycle (owned by Voucher Inventory Service and Third-Party Inventory Service)
- Appointment business logic beyond consuming appointment events (owned by Appointments Service)
- Consumer-facing checkout and order placement (owned by commerce checkout services)

## Domain Context

- **Business domain**: Booking / Calendar
- **Platform**: Continuum
- **Upstream consumers**: Booking surfaces, checkout orchestration, CX tooling
- **Downstream dependencies**: EPODS, Third-Party Booking, Appointments Service, M3 Place, M3 Merchant, Voucher Inventory Service, Third-Party Inventory Service, MBus (availability events)

## Stakeholders

| Role | Description |
|------|-------------|
| BookingEngine team | Service owners; responsible for feature development, on-call, and architecture decisions |
| Merchant Operations | Relies on accurate availability and booking state for merchant-facing tools |
| CX / Customer Support | Uses CX endpoints to inspect and modify bookings on behalf of customers |
| Partner Integrations | Depends on EPODS and third-party booking sync accuracy |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Summary: Java 17 |
| Framework | Dropwizard / JTier | 5.15.0 | Summary: JTier 5.15.0 |
| Runtime | JVM | 17 | Summary: Java 17 |
| Build tool | Maven | — | Summary: Maven |
| Package manager | Maven | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | — | db-client | PostgreSQL DaaS integration for primary booking datastore |
| jtier-daas-mysql | — | db-client | MySQL DaaS integration for availability engine datastore |
| jtier-retrofit | — | http-framework | HTTP client adapters for EPODS, Inventory, Appointments, and M3 |
| jtier-messagebus-dropwizard | — | message-client | MBus producer and consumer integration for availability and booking events |
| jtier-jedis-bundle | — | db-client | Redis cache client for hot availability and booking lookups |
| jtier-quartz-bundle | — | scheduling | Quartz scheduler bundle powering background cleanup and EPODS sync jobs |
| jtier-jdbi3 | — | orm | JDBI3 DAO layer for Postgres and MySQL access |
| jtier-resilience4j | 1.4.6 | http-framework | Circuit breaker and retry patterns for external HTTP calls |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.

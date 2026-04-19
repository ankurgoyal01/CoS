---
service: "bots"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 7
---

# Integrations

## Overview

BOTS integrates with 11 downstream systems: 7 internal Continuum services and 4 external systems (Salesforce, Google OAuth, Google Calendar, Message Bus). Most integrations are REST via JTier Retrofit clients (`botsApiIntegrationClientsComponent`). The Worker also directly consumes Message Bus events and performs background REST calls. Two additional integrations (TSD Aggregator, Rocketman Commercial) are defined as stubs in the architecture model but are not wired in the current central model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google OAuth | OAuth 2.0 | Authenticate merchant Google account for calendar integration | yes | `googleOAuth` |
| Google Calendar API | REST (Google API v3) | Synchronize merchant calendars (import/export bookings) | yes | `googleCalendar` |
| Salesforce | REST | Read/update merchant onboarding and CRM account state; process onboarding jobs | yes | `salesForce` |
| Message Bus | Message Bus protocol | Consume deal onboarding/offboarding and GDPR events; publish booking lifecycle events | yes | `messageBus` |

### Google OAuth Detail

- **Protocol**: OAuth 2.0
- **Base URL / SDK**: google-api-client 1.25.0
- **Auth**: OAuth 2.0 client credentials / authorization code flow
- **Purpose**: Authenticates merchant Google accounts so BOTS can access their Google Calendar for sync
- **Failure mode**: Calendar synchronization fails; merchant calendar sync is suspended until re-authentication
- **Circuit breaker**: No evidence found

### Google Calendar API Detail

- **Protocol**: REST (Google Calendar API v3)
- **Base URL / SDK**: google-apis-calendar v3, ical4j 3.0.20
- **Auth**: OAuth 2.0 token obtained via Google OAuth integration
- **Purpose**: Imports external calendar events into BOTS availability and exports BOTS bookings as Google Calendar events
- **Failure mode**: Calendar sync background job fails; merchant calendar out of sync until next scheduled run
- **Circuit breaker**: No evidence found

### Salesforce Detail

- **Protocol**: REST
- **Base URL / SDK**: JTier Retrofit client
- **Auth**: Salesforce API credentials (managed via secrets)
- **Purpose**: Reads and updates merchant onboarding state and CRM account data; Worker processes onboarding sync jobs
- **Failure mode**: Onboarding jobs fail or stale; merchant setup state may be inconsistent until retry
- **Circuit breaker**: No evidence found

### Message Bus Detail

- **Protocol**: JTier MessageBus (internal Groupon event infrastructure)
- **Base URL / SDK**: jtier-messagebus-client
- **Auth**: Internal service authentication
- **Purpose**: Inbound: consume `deal.onboarding`, `deal.offboarding`, `gdpr.erasure` events. Outbound: publish `booking.events.*` lifecycle events
- **Failure mode**: Event processing paused; retry and DLQ behavior managed by Message Bus infrastructure
- **Circuit breaker**: Managed by Message Bus consumer infrastructure

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| M3 Merchant Service | REST | Retrieve merchant account and profile data | `continuumM3MerchantService` |
| Deal Management API | REST | Retrieve deal metadata for booking configuration | `continuumDealManagementService` |
| Deal Catalog | REST | Retrieve deal catalog entities for campaign setup | `continuumDealCatalogService` |
| Calendar Service | REST | Update booking calendar entities in Continuum's calendar layer | `continuumCalendarService` |
| Voucher Inventory Service (VIS) | REST | Retrieve voucher details; process voucher redemption workflows | `continuumVoucherInventoryService` |
| M3 Place Read | REST | Retrieve merchant place/location details for availability context | `continuumM3PlacesService` |
| Cyclops | REST | Retrieve customer profile data for booking context | `cyclops` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. BOTS API endpoints are consumed by merchant-facing tooling and internal Groupon systems that manage merchant booking workflows.

## Dependency Health

- All internal Continuum service calls are made via JTier Retrofit clients (`botsApiIntegrationClientsComponent`), which inherit JTier-standard timeout and retry configuration.
- Message Bus consumer infrastructure provides built-in retry and dead-letter routing for consumed events.
- No explicit circuit breaker patterns were identified in the repository inventory. Failure isolation relies on JTier client-level timeout configuration and upstream infrastructure resilience.
- TSD Aggregator and Rocketman Commercial are declared as architecture stubs but are commented out of active relations — they are not currently wired dependencies.

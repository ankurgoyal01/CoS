---
service: "bookingtool"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 7
---

# Integrations

## Overview

The Booking Tool maintains 10 integration dependencies — 3 external SaaS platforms and 7 internal Continuum services. All outbound HTTP calls are executed through Guzzle-based clients in the `btIntegrationClients` component. Salesforce is the most critical external dependency, providing merchant and deal metadata. Rocketman V2 handles all transactional email delivery. Internal dependencies span voucher validation, deal catalog, merchant management, authentication, and notification.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/REST | Synchronizes merchant and deal metadata | yes | `salesForce` (stub) |
| Zendesk | HTTPS/REST | Creates and manages merchant support tickets | no | — |
| InfluxDB | UDP/HTTP | Emits operational metrics | no | — |

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Guzzle HTTP client — base URL from environment configuration
- **Auth**: OAuth 2.0 / API key (standard Salesforce connected app)
- **Purpose**: Provides authoritative merchant identity and deal metadata used to validate bookings and populate local merchant cache
- **Failure mode**: Degraded — local MySQL cache may serve stale merchant data; new merchant onboarding blocked
- **Circuit breaker**: No evidence found

### Zendesk Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: `zendesk_api` SDK v2.2.14
- **Auth**: API token (Zendesk API key)
- **Purpose**: Creates support tickets on behalf of merchants for booking-related issues; used in merchant-support workflows
- **Failure mode**: Non-critical — booking operations continue; support ticket creation fails silently or with retry
- **Circuit breaker**: No evidence found

### InfluxDB Detail

- **Protocol**: UDP/HTTP
- **Base URL / SDK**: `influxdb-php` ^1.15
- **Auth**: InfluxDB credentials via environment
- **Purpose**: Emits time-series operational metrics (booking volumes, latency, error rates) for monitoring dashboards
- **Failure mode**: Non-critical — metrics collection degrades; no impact to booking operations
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory | HTTPS/REST | Validates voucher codes on booking; reinstates vouchers on cancellation | — |
| Deal Catalog | HTTPS/REST | Retrieves deal configuration and rules for availability validation | — |
| MX Merchant API | HTTPS/REST | Reads merchant account status and configuration | — |
| Cyclops | HTTPS/REST | Internal monitoring / alerting integration | — |
| Rocketman V2 | HTTPS/REST | Sends transactional confirmation, cancellation, and reschedule emails | — |
| Appointment Engine | HTTPS/REST | Coordinates appointment scheduling across Groupon services | — |
| RaaS | HTTPS/REST | Customer identity and access resolution | — |
| API-INTL | HTTPS/REST | International API gateway for locale-specific consumer requests | — |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

All outbound calls are made via Guzzle HTTP client. No explicit circuit breaker, retry policy, or timeout configuration is evidenced in the inventory beyond Guzzle's defaults. Salesforce connectivity is the highest-risk failure point given its role in merchant metadata. Internal service failures are expected to surface as HTTP 5xx responses propagated back to the caller.

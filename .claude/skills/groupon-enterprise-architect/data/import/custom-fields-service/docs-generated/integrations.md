---
service: "custom-fields-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 2
---

# Integrations

## Overview

Custom Fields Service has two internal Groupon dependencies: the Users Service (for purchaser data prefill) and the PostgreSQL DaaS database (for template persistence). All integration is synchronous HTTP or JDBC — no external third-party SaaS integrations are present.

## External Dependencies

> No evidence found in codebase.

Custom Fields Service has no external (non-Groupon) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | REST/HTTP | Fetch purchaser profile data (firstName, lastName, email, phone) to prefill field values | `continuumUsersService` |
| PostgreSQL (DaaS) | JDBC | Persist and read custom field template definitions | `continuumCustomFieldsDatabase` |

### Users Service Detail

- **Protocol**: REST/HTTP via Retrofit2
- **Base URL**: `http://users-service.production.service/` (production); configurable per environment via `userServiceClient.url`
- **Auth**: API key header — `X-API-KEY: ${USER_SERVICE_API_KEY}` (value sourced from Kubernetes secret)
- **Endpoint called**: `GET users/v1/accounts?id={userId}` with `X-Request-Id` header for tracing
- **Purpose**: Retrieves user account profile data when `purchaserId` query parameter is supplied on GET field requests; used to prepopulate `firstName`, `lastName`, `email`, and `phone` field values
- **Failure mode**: If Users Service is unreachable or times out, CFS continues to function but returns fields without prefilled values (graceful degradation). An in-memory Guava cache (10,000 entries, 5-unit expiry in production) reduces the blast radius of Users Service latency.
- **Timeouts**: `connectTimeout: PT1S`, `readTimeout: PT0.5S`, `writeTimeout: PT0.5S`
- **Circuit breaker**: No evidence of a formal circuit breaker; degradation is achieved by configuring the userService host to a dead-end (`localhost:9999`) in the run config when prefill should be disabled

### PostgreSQL (DaaS) Detail

- **Protocol**: JDBC via JDBI3 (`jtier-jdbi3`)
- **Purpose**: All template persistence — create, read, delete custom field sets
- **Auth**: Database credentials sourced from `DAAS_APP_USERNAME` / `DAAS_APP_PASSWORD` environment variables (Kubernetes secrets)
- **Failure mode**: If the database is unavailable, field retrieval fails entirely; the service cannot serve templates from the database when the DB is down (no persistent fallback cache)
- **Pool size**: Transaction pool 50, session pool 2

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| TPIS (Third-Party Inventory Service) | REST/HTTP | Retrieve and validate custom fields for third-party booking flows |
| GLive (Groupon Live Inventory Service) | REST/HTTP | Retrieve and validate custom fields for live event bookings |
| VIS (Voucher Inventory Service) | REST/HTTP | Retrieve and validate custom fields for voucher purchase flows |
| Getaways Inventory Service | REST/HTTP | Retrieve and validate custom fields for getaway bookings |
| Goods | REST/HTTP | Retrieve and validate custom fields for goods purchase flows |

> Upstream consumers are tracked in the central architecture model and in `OWNERS_MANUAL.md`.

## Dependency Health

- **Users Service**: Monitored via Wavefront dashboards. Alerts configured for connection errors (SEV4) and slow response times (SEV4). Mitigation: disable prefill by redirecting `userService.host` to a dead-end in the run config.
- **PostgreSQL (DaaS)**: Monitored via Wavefront and CheckMK. Alerts configured for DB down (SEV3) and DB slow response (SEV4). No automatic failover at the application layer — relies on DaaS infrastructure for HA.

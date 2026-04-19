---
service: "billing-record-options-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 2
---

# Integrations

## Overview

BROS has a small and focused integration surface. It has no external (third-party) HTTP dependencies. Its two internal platform dependencies are DaaS PostgreSQL for persistent configuration storage and RAAS Redis for caching. No other Groupon microservices are called at runtime; all business logic is self-contained and data-driven from the database. Upstream consumers call BROS via REST HTTP.

## External Dependencies

> No evidence found in codebase. BROS does not call any third-party external systems at runtime.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS PostgreSQL | PostgreSQL (JDBC/JDBI) | Primary configuration store for all payment method data; read via `jtier-daas-postgres` and `jtier-jdbi` | `daasPostgresPrimary` |
| RAAS Redis | Redis | Low-latency cache layer for payment method data; accessed via `payment-cache` SDK | `raasRedis` |

### DaaS PostgreSQL Detail

- **Protocol**: PostgreSQL (JDBC connection pool managed by `jtier-daas-postgres`)
- **Base URL / SDK**: `jtier-daas-postgres` library (DaaS platform-managed connection configuration)
- **Auth**: Database credentials stored in `billing-record-options-service-secrets` git submodule (`.meta/deployment/cloud/secrets/`)
- **Purpose**: Stores and serves all payment method configuration — applications, client types, countries, payment types, providers, and importance rankings
- **Failure mode**: Service cannot serve payment method responses if the primary database is unavailable; no fallback beyond cache
- **Circuit breaker**: No evidence found in codebase

### RAAS Redis Detail

- **Protocol**: Redis (via `payment-cache` SDK version 1.0.4)
- **Base URL / SDK**: `payment-methods-server-sdk` and `payment-cache` SDK
- **Auth**: Managed by RAAS platform; credentials in secrets submodule
- **Purpose**: Provides a low-latency read path for payment method data, reducing database load
- **Failure mode**: Cache miss falls back to database read
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known application clients from seed data include: FRONTEND (`de.citydeal.web:frontend`), MOBILE (`de.citydeal.api:citydeal-api-webapp`), ADMIN (`de.citydeal.web:admin`), and CHECKOUT (`GROUPON_DESKTOP_WEB`, checkout application hash).

Internal base URL patterns for consumers:
- Production NA: `http://global-payments-config-service-us.snc1` / `http://global-payments-config-service-us.sac1`
- Production EMEA: `http://global-payments-config-service-row.dub1`
- Staging NA: `http://global-payments-config-service-staging-us.snc1`

## Dependency Health

- **PostgreSQL**: Health checked indirectly through the JTier `/grpn/status` endpoint (`path: /grpn/status`, `port: 8080`). Database connectivity failure causes request failures; no circuit breaker pattern is evident.
- **Redis**: Cache misses are tolerated gracefully (fall back to database). No explicit circuit breaker or retry policy found in source.
- DaaS and RAAS are listed as explicit `dependencies` in `.service.yml`: `daas_postgres` and `raas`.

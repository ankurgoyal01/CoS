---
service: "partner-attributes-mapping-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

PAMS has a minimal integration footprint. It owns its PostgreSQL database as its sole downstream dependency. It does not call any external partner APIs directly; it provides the signing materials and ID translations that other services use when calling partners. There are no external HTTP client calls, no message broker connections, and no cloud service SDK integrations evident in the codebase.

## External Dependencies

> No evidence found in codebase. PAMS does not make outbound HTTP calls to external partner systems. It generates signatures and maps IDs for use by callers, but does not itself contact partner endpoints.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumPartnerAttributesMappingPostgres` | JDBI / PostgreSQL | Read and write partner attribute mappings and HMAC secrets | `continuumPartnerAttributesMappingPostgres` |

### PostgreSQL Detail

- **Protocol**: JDBI3 over JDBC / PostgreSQL wire protocol
- **SDK**: `jtier-daas-postgres` + `jtier-jdbi3`
- **Auth**: DaaS-managed credentials (injected via `PostgresConfig`)
- **Purpose**: Sole datastore for all service state — ID mappings and partner signing secrets
- **Failure mode**: Service becomes unable to serve mapping reads/writes; signature operations that require database-sourced secrets also fail
- **Circuit breaker**: Managed by the JTier DaaS connection pool; no custom circuit breaker found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on the service's purpose (Groupon Anywhere / CLO partner distribution), likely consumers include internal CLO services that distribute offers to banking partners and other third-party channels. These services call PAMS to translate entity IDs before or after interacting with partner APIs, and to obtain signed request headers.

## Dependency Health

The service registers Dropwizard health checks for the PostgreSQL connection pool via `jtier-daas-postgres` (automatically registered as part of `buildTransactionPooledDataSource`). A custom `ServiceHealthCheck` ("math") is also registered at startup as a baseline liveness indicator. No custom retry or circuit breaker logic was found beyond what the JTier DaaS pool provides.

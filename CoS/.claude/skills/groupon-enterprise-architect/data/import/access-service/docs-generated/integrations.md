---
service: "mx-merchant-access"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 3
---

# Integrations

## Overview

The Merchant Access Service has a lean integration footprint. It owns its PostgreSQL database (provisioned via DaaS), consumes three MBus event topics from the users-service, and depends on `mx-merchant-api` as a declared service dependency. Outbound HTTP calls to internal services use the `mx-clients` library. MBus connectivity uses the `commons-mbus` library backed by the Groupon `messagebus` client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MBus (Message Bus) | MBus (messaging) | Receives account lifecycle events (merged, deactivated, erased) | yes | `messageBus` |

### MBus Detail

- **Protocol**: MBus publish-subscribe (Groupon internal message bus)
- **Base URL / SDK**: `commons-mbus` (mx-commons 1.54.21), `com.groupon.messagebus:messagebus-api`
- **Auth**: Connection via `hostParams` and `subscriptionId` configuration properties
- **Purpose**: Subscribes to account lifecycle topics so MAS can clean up access data when a user account is deactivated, erased, or merged
- **Failure mode**: MBus consumers will fail to start if `mbus.enabled=true` and connection fails; service health check exposes MBus status
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS PostgreSQL | JPA/JDBC | Primary data persistence | `continuumAccessPostgres` |
| `mx-merchant-api` | REST (mx-clients) | Declared service dependency for merchant data lookups | Not modeled separately in access-service DSL |
| check_mk | monitoring | Infrastructure health monitoring | Not modeled in DSL |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumer patterns from service configuration:
- SOX-scoped internal services consume `http://merchant-access-us-sox-vip.sac1` / `http://merchant-access-us-sox-vip.snc1` / `http://merchant-access-emea-sox-vip.dub1` (read-write)
- Non-SOX internal services consume `http://merchant-access-us-vip.sac1` / `http://merchant-access-us-vip.snc1` / `http://merchant-access-emea-vip.dub1` (read-only)

## Dependency Health

- The `accessSvc_healthAndMetrics` component runs scheduled health checks against the PostgreSQL store and emits metrics
- Service exposes `/health?invoker=service-portal` and `/ping` endpoints for readiness/liveness probes
- MBus consumer connectivity is reflected in the health check output
- Wavefront dashboards track incoming and outgoing request latency and error rates for all dependencies

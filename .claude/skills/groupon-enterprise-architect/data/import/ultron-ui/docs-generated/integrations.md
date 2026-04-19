---
service: "ultron-ui"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Ultron UI has a single internal dependency: `continuumUltronApi`. Every operator action performed in the browser results in an HTTP/JSON call from the Play controllers to the Ultron API backend. There are no external third-party dependencies and no direct database connections. The service is a pure UI proxy.

## External Dependencies

> No evidence found for any external third-party system dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Ultron API | HTTP/JSON | All job orchestration operations — groups, jobs, instances, lineage, resources | `continuumUltronApi` |

### Ultron API Detail

- **Protocol**: REST HTTP/JSON
- **Base URL / SDK**: Internal service URL; configured via environment variable at deployment time
- **Auth**: Service-to-service call; operator LDAP credentials validated at Ultron UI boundary
- **Purpose**: Single source of truth for all job orchestration data. Ultron UI proxies every read and write operation (groups, jobs, instances, resource lineage) to this backend.
- **Failure mode**: If `continuumUltronApi` is unavailable, all UI operations that require data will fail. The `/heartbeat` endpoint remains available as it does not depend on the API.
- **Circuit breaker**: No evidence found for a circuit breaker implementation.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Ultron UI is accessed directly by browser-based operators (data engineers, platform operators) via LDAP-authenticated HTTP.

## Dependency Health

- The `/heartbeat` endpoint on Ultron UI provides a liveness signal but does not chain-check `continuumUltronApi` health.
- No retry or circuit breaker patterns are evidenced in the inventory; failures from `continuumUltronApi` are surfaced directly to the browser client.

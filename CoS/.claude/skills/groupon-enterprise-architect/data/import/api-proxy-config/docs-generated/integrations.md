---
service: "api-proxy-config"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

`api-proxy-config` has no external third-party dependencies. Its integration landscape is entirely internal to the Continuum Platform. The primary integration is a one-way configuration provision relationship with the `apiProxy` runtime: this repository defines the routing rules that `apiProxy` uses to process live traffic. The configuration bundle also references several internal services as routing destinations — Redis Memorystore for rate limiting, Client ID Service, BASS service, Telegraf telemetry, and upstream route destination hosts — but these are referenced as static configuration values, not as direct runtime call targets from this service.

## External Dependencies

> No evidence found. `api-proxy-config` has no external (non-Groupon) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `apiProxy` | File artifact copy | Consumes the packaged configuration bundle at container startup via `/app/conf/` mount | `apiProxy` (stub) |
| `apiProxyRedisMemorystore` | Configuration reference | Redis host/port defined in bundle for API Proxy rate-limit counters | `apiProxyRedisMemorystore_2f3a9c` (stub) |
| `clientIdService` | Configuration reference | `clientServiceConfig` and `clientServiceConfigV3` endpoint definitions for dynamic client ID routing | `clientIdService_94c1e2` (stub) |
| `bassService` | Configuration reference | `bemodConfig` upstream endpoint definition | `bassService_1d8b77` (stub) |
| `apiProxyTelegraf` | Configuration reference | `influxDbOptions` telemetry endpoint definition for Jolokia metrics | `apiProxyTelegraf_6a41f0` (stub) |
| `apiProxyRouteDestinations` | Configuration reference | Destination host and route-group mapping definitions | `apiProxyRouteDestinations_7b2d11` (stub) |

### `apiProxy` Detail

- **Protocol**: File artifact copy (Docker image layer / Kubernetes volume mount at `/app/conf/`)
- **Base URL / SDK**: `docker-conveyor.groupondev.com/groupon-api/api-proxy-config` (Docker image reference in `common.yml`)
- **Auth**: N/A — artifact is copied into the runtime image at build/deploy time
- **Purpose**: The `apiProxy` runtime reads `mainConf.json` (pointed to by the `CONFIG` env var) and the referenced `routingConf.json` on startup to initialize its routing table, realm definitions, destinations, and experiment layers
- **Failure mode**: If the configuration artifact is malformed or the `CONFIG` env var points to a non-existent file, the `apiProxy` runtime fails to start; readiness probe at `/grpn/ready:9000` will not return healthy
- **Circuit breaker**: No — this is a static file dependency resolved at startup, not a live call

### Internal Dependency Health

The `routingConfigFileResolver` component validates that routing configuration files exist before mutations are applied. The `addNewRouteRequest.js` and `promoteRouteRequest.js` scripts use Node.js `assert` to validate all required fields before writing changes to disk. `doRoutesExist.js` is called before mutation operations to guard against duplicate route entries.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `apiProxy` runtime | File artifact (Docker image / Kubernetes volume) | Loads routing configuration at startup to initialize the API gateway routing table |
| DeployBot CI/CD pipeline | Git webhook / tag trigger | Packages and deploys versioned configuration artifacts to Kubernetes environments |
| API Platform operators | Node.js CLI (`config_tools/`) | Inspect and mutate routing configuration files during normal operations and incident response |

> Upstream consumers beyond `apiProxy` are tracked in the central architecture model (`continuumSystem`).

## Dependency Health

There are no live runtime dependencies to health-check. The `apiProxy` readiness probe at `/grpn/ready:9000` serves as the downstream signal that the configuration was successfully loaded. Helm chart deployment uses `krane` with a `--global-timeout` of 300–4000 seconds depending on environment, which times out if the `apiProxy` pods fail to become ready after a new configuration artifact is deployed.

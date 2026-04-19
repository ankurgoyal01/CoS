---
service: "deckard"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 10
---

# Integrations

## Overview

Deckard has no external (third-party) dependencies. All integrations are internal Groupon services. It calls seven downstream inventory services via REST HTTP, two decoration services via REST HTTP (Mentos and M3), and consumes events from the Groupon Message Bus (mbus). It is consumed exclusively by API Lazlo. All downstream HTTP clients are managed as Lazlo `RestClientVerticle` instances with configurable connection pools, timeouts, and wait queue limits.

## External Dependencies

> No evidence found in codebase. Deckard has no external (third-party) system integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Getaways Inventory Service | REST / HTTP | Fetches getaways inventory units for a consumer | `inventoryServices6c31` (stub) |
| Market Rate Getaways Inventory Service | REST / HTTP | Fetches market-rate getaways units for a consumer | `inventoryServices6c31` (stub) |
| Groupon Live (Glive) Inventory Service | REST / HTTP | Fetches Groupon Live event inventory units for a consumer | `inventoryServices6c31` (stub) |
| Goods Inventory Service | REST / HTTP | Fetches goods/products inventory units for a consumer | `inventoryServices6c31` (stub) |
| Card-Linked Offers (CLO) Inventory Service | REST / HTTP | Fetches card-linked offer units for a consumer | `inventoryServices6c31` (stub) |
| VIS (Voucher Inventory Service v2) | REST / HTTP | Fetches voucher inventory units for a consumer | `inventoryServices6c31` (stub) |
| TPIS (Third-Party Inventory Service) | REST / HTTP | Fetches third-party inventory units for a consumer | `inventoryServices6c31` (stub) |
| Mentos | REST / HTTP | Fetches decoration/metadata for inventory units | `mentosService3c5e` (stub) |
| M3 Decoration Service | REST / HTTP | Fetches decoration/metadata for inventory units | `m3DecorationService5f19` (stub) |
| Groupon Message Bus (mbus) | STOMP | Consumes inventory, order, and user account events | `mbusMessageBus7e8c` (stub) |

### Getaways Inventory Service Detail

- **Protocol**: REST / HTTP
- **Client name**: `getawaysInventoryClient`
- **Staging host**: `getaways-inventory.staging.service:80`
- **Auth**: `clientId=deckard` query parameter
- **Purpose**: Fetches getaways inventory units and checks availability for a consumer; supports prefixes `BD`, alias `legacy_getaways`
- **Failure mode**: Returns partial results; failed service listed in `errors.inventoryServices`; max wait queue size 24 requests
- **Circuit breaker**: Connection pool throttling via `maxPoolSize=100`, `maxWaitQueueSize=24`

### Market Rate Getaways (mrgetaways) Inventory Service Detail

- **Protocol**: REST / HTTP
- **Client name**: `marketRateGetawaysInventoryClient`
- **Staging host**: `getaways-maris.staging.service:80`
- **Auth**: `clientId=lazlo-2e4c266db5d4` query parameter
- **Purpose**: Fetches market-rate getaway inventory units; supports prefix `MR`
- **Failure mode**: Partial results; request timeout 60 seconds
- **Circuit breaker**: `maxPoolSize=50`, `maxWaitQueueSize=24`

### Groupon Live (Glive) Inventory Service Detail

- **Protocol**: REST / HTTP
- **Client name**: `gliveInventoryClient`
- **Staging host**: `grouponlive-inventory-service.staging.service:80`
- **Auth**: `clientId=f7a38aaddcc8d313-deckard` query parameter
- **Purpose**: Fetches Groupon Live event inventory units; supports prefix `GL`; 4 client instances
- **Failure mode**: Partial results; request timeout 1 second (aggressive)
- **Circuit breaker**: `maxPoolSize=100`, `maxWaitQueueSize=24`

### Goods Inventory Service Detail

- **Protocol**: REST / HTTP
- **Client name**: `goodsInventoryClient`
- **Staging host**: `goods-inventory-service.staging.service:80`
- **Auth**: `clientId=313d8ccddaa83a7f-deckard` query parameter
- **Purpose**: Fetches physical goods inventory units; supports prefix `GG`
- **Failure mode**: Partial results; request timeout 20 seconds
- **Circuit breaker**: `maxPoolSize=100`, `maxWaitQueueSize=24`

### Card-Linked Offers (CLO) Inventory Service Detail

- **Protocol**: REST / HTTP
- **Client name**: `cloInventoryClient`
- **Staging host**: `clo-inventory-service.staging.service:80`
- **Auth**: `clientId=f154f9d7c8b5a067-deckard` query parameter
- **Purpose**: Fetches card-linked offer inventory units; supports prefix `CL`
- **Failure mode**: Partial results; request timeout 20 seconds
- **Circuit breaker**: `maxPoolSize=100`, `maxWaitQueueSize=24`

### VIS (Voucher Inventory Service v2) Detail

- **Protocol**: REST / HTTP
- **Client name**: `voucherV2Inventory`
- **Staging host**: `voucher-inventory.staging.service:80`
- **Auth**: `clientId=5586304f57d5ff0d-deckard-gapi` query parameter
- **Purpose**: Fetches voucher inventory units; supports prefix `VS`; supports gift association; default inventory service; 4 client instances
- **Failure mode**: Partial results; request timeout 60 seconds
- **Circuit breaker**: `maxPoolSize=100`, `maxWaitQueueSize=24`

### TPIS (Third-Party Inventory Service) Detail

- **Protocol**: REST / HTTP
- **Client name**: `tpisInventoryClient`
- **Staging host**: `tpis-third-party-inventory-service.staging.service:80`
- **Auth**: `clientId=313d8ccddaa83a7f-deckard` query parameter
- **Purpose**: Fetches third-party inventory units; supports prefix `TP`; supports gift association
- **Failure mode**: Partial results; request timeout 20 seconds
- **Circuit breaker**: `maxPoolSize=100`, `maxWaitQueueSize=24`

### Groupon Message Bus (mbus) Detail

- **Protocol**: STOMP over mbus
- **Staging host**: `mbus-na-stable.grpn-dse-stable.us-west-1.aws.groupondev.com:61613`
- **Auth**: Internal network
- **Purpose**: Receives inventory unit update, order status change, and user account merge events to keep the Redis cache current
- **Failure mode**: If mbus is down, Deckard cache becomes stale; cache TTL (15 min stale, 24 hr expiry) limits staleness window
- **Circuit breaker**: Not applicable (subscription-based)

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumApiLazloService` (API Lazlo) | REST / HTTP | Sole caller; retrieves paginated inventory unit identifiers to decorate for front-end display |

## Dependency Health

Each inventory service REST client is configured with:
- **Connection timeout**: 100–200 ms
- **Request timeout**: 1,000–60,000 ms (varies by service)
- **Max pool size**: 50–100 connections
- **Max wait queue size**: 24 requests (requests exceeding this are rejected with an error)

If a downstream inventory service fails to respond within its timeout, Deckard returns a partial result set with the failed service listed in `errors.inventoryServices`. The service can continue operating with reduced coverage as long as at least one inventory service is reachable. If the Redis cache is unavailable, all requests become cache misses and latency increases significantly. See [Runbook](runbook.md) for mitigation steps.

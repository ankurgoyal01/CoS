---
service: "deckard"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDeckardService", "continuumCacheRedisCluster", "continuumAsyncUpdateRedis"]
---

# Architecture Context

## System Context

Deckard sits within the `continuumSystem` (Continuum Platform) as the consumer-facing inventory aggregation layer. It receives requests exclusively from `continuumApiLazloService` (API Lazlo), which calls Deckard to obtain a paginated, filtered, and sorted list of inventory unit identifiers for a given consumer. Deckard then decorates this aggregation by fetching raw unit data from multiple downstream inventory services and persisting results in Redis. It also integrates with the Groupon Message Bus to react to inventory, order, and user events without waiting for inbound API requests.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deckard Service | `continuumDeckardService` | Backend service | Java / Vert.x (Lazlo) | 4.0.29 | Aggregates inventory units for My Groupons with filtering, sorting, and pagination |
| Redis Cache Cluster | `continuumCacheRedisCluster` | Cache | Redis | — | Application cache for consumer inventory units and metadata (cluster mode) |
| Redis Async Update Queue | `continuumAsyncUpdateRedis` | Queue store | Redis | — | Standalone Redis used as async update queue for background cache refresh |

## Components by Container

### Deckard Service (`continuumDeckardService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| LazloControllerVerticle | Receives HTTP requests and routes to BLS handlers | Lazlo / Vert.x |
| BLSInventoryUnitVerticle | Business logic: fetches, merges, filters, sorts, and paginates inventory units | Lazlo BLS |
| LazloMessageBusClientVerticle | Connects to Groupon Message Bus and dispatches events to handlers | mbus-client / Vert.x |
| OrdersMsgHandlerVerticle | Handles `Orders.InventoryUnits.StatusChanged` events; triggers cache refresh | Lazlo BLS |
| InventoryServiceMsgHandlerVerticle | Handles per-service `InventoryUnits.Updated.*` events; triggers cache refresh | Lazlo BLS |
| UsersMsgHandlerVerticle | Handles `users.account.v1.merged` events; merges consumer cache entries | Lazlo BLS |
| CacheRedisVerticle | Manages read/write access to the Redis application cache cluster | Vert.x Redis |
| AsyncUpdateRedisVerticle | Manages access to the Redis async update queue | Vert.x Redis |
| QueueVerticle | Enqueues async cache refresh requests | asyncupdater library |
| DequeueVerticle | Dequeues and processes pending cache refresh requests | asyncupdater library |
| Filter Grammar (ANTLR4) | Parses the custom filter expression language (`Filter.g4`) | ANTLR4 4.5 |
| Inventory Service Clients | Per-service REST clients (getaways, mrgetaways, glive, goods, clo, vis, tpis) | Lazlo RestClientVerticle |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiLazloService` | `continuumDeckardService` | Requests inventory units list for a consumer | REST / HTTP |
| `continuumDeckardService` | `continuumCacheRedisCluster` | Reads/writes cached consumer inventory units | Redis protocol |
| `continuumDeckardService` | `continuumAsyncUpdateRedis` | Queues async update requests for background cache refresh | Redis protocol |
| `continuumDeckardService` | Inventory Services (stub) | Fetches inventory units per service for a consumer | REST / HTTP |
| `continuumDeckardService` | Mentos (stub) | Fetches decoration data for inventory units | REST / HTTP |
| `continuumDeckardService` | M3 (stub) | Fetches decoration data for inventory units | REST / HTTP |
| `continuumDeckardService` | Message Bus (stub) | Consumes inventory/user/order events | STOMP / mbus |
| Orders Service (stub) | Message Bus (stub) | Publishes inventory unit status events | STOMP / mbus |
| Users Service (stub) | Message Bus (stub) | Publishes account merge events | STOMP / mbus |
| Inventory Services (stub) | Message Bus (stub) | Publish inventory unit update events | STOMP / mbus |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-deckard`
- Component: `components-deckard` (no component definitions yet in federated model)

---
service: "maris"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 5
---

# Integrations

## Overview

MARIS has 2 external dependencies (Expedia EAN API and Expedia Rapid API) and 5 internal Groupon dependencies (Orders Service, Deal Catalog Service, Content Service, Travel Search Service, and MBus). All outbound HTTP calls use typed clients built on `jtier-retrofit`. Message bus interactions use `jtier-messagebus-client`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Expedia EAN API | HTTPS REST | Legacy hotel content and availability queries | yes | `unknown_expediarapidapi_12b321ae` (stub) |
| Expedia Rapid API | HTTPS REST | Current hotel availability, content retrieval, booking, and cancellation | yes | `unknown_expediarapidapi_12b321ae` (stub) |

### Expedia EAN API Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: Expedia EAN API (base URL configured via environment; specific value not documented here)
- **Auth**: API key / partner credentials (configured via secrets)
- **Purpose**: Legacy integration for hotel content and market rate queries; used in the `/getaways/v2/marketrate/hotels/{id}/rooms` flow
- **Failure mode**: Hotel room availability queries fail; API returns error or empty response to upstream consumer
- **Circuit breaker**: Not explicitly evidenced in architecture model; JTier Retrofit client behavior applies

### Expedia Rapid API Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: Expedia Rapid API (base URL configured via environment; specific value not documented here)
- **Auth**: API key / partner credentials (configured via secrets)
- **Purpose**: Primary integration for real-time hotel availability, room content retrieval, itinerary booking, and booking cancellation
- **Failure mode**: Reservation creation or cancellation fails; booking flow cannot complete; availability queries return errors to upstream callers
- **Circuit breaker**: Not explicitly evidenced in architecture model

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders Service | HTTP/JSON | Authorizes, captures, and reverses inventory unit payments | `continuumOrdersService` |
| Deal Catalog Service | HTTP/JSON | Resolves legacy product identifiers for hotel inventory units | `continuumDealCatalogService` |
| Content Service | HTTP/JSON | Fetches hotel content metadata for enriching inventory responses | `unknown_getawayscontentservice_1dc01dfc` (stub) |
| Travel Search Service | HTTP/JSON | Fetches travel search hotel details for availability enrichment | `unknown_travelsearchservice_f8dcf9f9` (stub) |
| MBus (message bus) | JMS Topics/Queues | Publishes unit update and GDPR completion events; consumes order status and GDPR erasure events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on event subscriptions and API usage patterns:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Travel Search Service | HTTP/JSON | Queries hotel room availability and market rates |
| Deal Catalog Service | HTTP/JSON | Queries inventory product availability |
| Downstream event consumers | MBus / JMS | Subscribe to `InventoryUnits.Updated.Mrgetaways` and `UpdatedSnapshot` topics |

## Dependency Health

- All outbound HTTP integrations use `jtier-retrofit` typed clients; retry and timeout behavior follows JTier defaults
- MBus connectivity is managed by `jtier-messagebus-client` with platform-managed retry semantics
- Orders Service is a critical synchronous dependency for reservation payment operations; its unavailability will block payment capture and reversal flows
- Expedia Rapid API is a critical external dependency; its unavailability will prevent new reservation creation and availability queries
- Content Service and Travel Search Service are non-blocking enrichment dependencies; their unavailability may degrade response completeness without blocking core reservation operations

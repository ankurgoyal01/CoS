---
service: "epods"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 8
internal_count: 7
---

# Integrations

## Overview

EPODS integrates with 8 external third-party partner systems and 7 internal Groupon/Continuum services. All outbound integrations use HTTP REST via `jtier-retrofit`. Resilience patterns (retry, circuit breaker, fallback) are implemented using `failsafe` 2.3.1. Inbound partner webhooks are received over HTTP at the `/webhook/*` path. Internal message bus interactions use JMS/STOMP via `jtier-messagebus-client`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MindBody | rest + webhook | Partner booking API; inbound booking change webhooks | yes | `mindbodyApi` |
| Booker | rest | Partner booking API | yes | `bookerApi` |
| Square | rest + webhook | Partner booking API; inbound webhooks (stub only) | yes | `squareApi` |
| Shopify | rest + webhook | Partner commerce API; inbound webhooks (stub only) | yes | `shopifyApi` |
| HBW | rest | Partner booking API (stub only) | yes | `hbwPartnerApi` |
| BT (Booking Tool) | rest | Booking tool integration (stub only) | no | `bookingToolService` |
| VIS | rest | Inventory lookup and updates (stub only) | yes | `visService` |
| PAMS | rest | Partner mappings (stub only) | yes | `pamsService` |

### MindBody Detail

- **Protocol**: HTTP REST (outbound) + HTTP Webhook (inbound)
- **Base URL / SDK**: Configured via service properties; called through `jtier-retrofit` client
- **Auth**: Partner API key (configured via environment/secrets)
- **Purpose**: Create, cancel, and retrieve bookings in the MindBody partner system; receive inbound webhook notifications of booking and availability changes
- **Failure mode**: Bookings fail with error response to caller; availability events may be delayed until next sync cycle
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### Booker Detail

- **Protocol**: HTTP REST (outbound)
- **Base URL / SDK**: Configured via service properties; called through `jtier-retrofit` client
- **Auth**: Partner API key (configured via environment/secrets)
- **Purpose**: Create, cancel, and retrieve bookings in the Booker partner system
- **Failure mode**: Booking requests fail with error response to caller
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### Square Detail

- **Protocol**: HTTP REST (outbound) + HTTP Webhook (inbound, stub only — not in active federated model)
- **Auth**: Partner API key
- **Purpose**: Partner booking API; inbound order/booking webhooks
- **Failure mode**: Booking requests fail with error response to caller
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### Shopify Detail

- **Protocol**: HTTP REST (outbound) + HTTP Webhook (inbound, stub only — not in active federated model)
- **Auth**: Partner API key / HMAC webhook signature
- **Purpose**: Partner commerce API; inbound order webhooks
- **Failure mode**: Commerce requests fail with error response to caller
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### HBW Detail

- **Protocol**: HTTP REST (stub only — not in active federated model)
- **Auth**: Partner API key
- **Purpose**: Partner booking API
- **Failure mode**: Booking requests fail with error response to caller
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### VIS Detail

- **Protocol**: HTTP REST (stub only — not in active federated model)
- **Auth**: Internal service auth
- **Purpose**: Inventory lookup and updates
- **Failure mode**: Inventory queries fail; availability may be stale
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

### PAMS Detail

- **Protocol**: HTTP REST (stub only — not in active federated model)
- **Auth**: Internal service auth
- **Purpose**: Partner attribute and mapping data
- **Failure mode**: Mapping lookups fail; bookings requiring PAMS data cannot be processed
- **Circuit breaker**: Yes — via `failsafe` 2.3.1

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | rest | Deal lookup by deal ID | `continuumDealCatalogService` |
| Calendar Service | rest | Booking sync and calendar slot management | `continuumCalendarService` |
| CFS (Custom Fields Service) | rest | Custom field lookup for bookings and orders | `continuumCfsService` |
| Partner Service | rest | Partner configuration retrieval | `continuumPartnerService` |
| Merchant API | rest | Merchant data retrieval | `continuumMerchantApi` |
| Orders Service | rest | Orders read for booking context | `continuumOrdersService` |
| Ingestion Service | rest | Push data into the ingestion pipeline | `continuumIngestionService` |
| Message Bus | mbus (JMS/STOMP) | Publish and consume availability, voucher, and booking events | `messageBus` |
| PSST Service | rest | Partner attribute signature (stub only) | `psstService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on integration patterns:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Booking Tool | rest | Initiates booking create and cancel operations via EPODS |
| Orders Service | rest | Reads booking status from EPODS for order processing |

## Dependency Health

- All outbound HTTP integrations use `failsafe` 2.3.1 for retry (with exponential backoff) and circuit breaker policies.
- Redis distributed locks in `continuumEpodsRedis` prevent concurrent availability sync conflicts.
- Partner API credentials and base URLs are externalized via environment configuration — no hard-coded endpoints.
- Stub-only integrations (Square webhook, Shopify webhook, HBW, BT, VIS, PAMS, PSST) are defined in the architecture model but not fully wired in the active federated model; they represent planned or partially implemented integrations.

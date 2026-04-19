---
service: "voucher-inventory-jtier"
title: "Inventory Product Lookup"
generated: "2026-03-03"
type: flow
flow_name: "inventory-product-lookup"
flow_type: synchronous
trigger: "HTTP GET /inventory/v1/products with a list of product IDs"
participants:
  - "continuumVoucherInventoryApi"
  - "continuumVoucherInventoryRedis"
  - "continuumVoucherInventoryProductDb"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumPricingService"
  - "continuumCalendarService"
  - "messageBus"
architecture_ref: "components-voucherInventoryApi"
---

# Inventory Product Lookup

## Summary

This is the primary synchronous flow of Voucher Inventory JTier. A consumer sends a `GET /inventory/v1/products` request with a list of product IDs. The API Resources layer dispatches the request to the Inventory Product Service, which performs a cache-behind lookup: checking Redis first, falling back to MySQL for misses, enriching the result with Pricing Service data (dynamic pricing, feature controls) and optionally with Calendar Service availability segments, then returning the assembled inventory response to the caller. The SLA target is p99 20ms at 800K RPM.

## Trigger

- **Type**: api-call
- **Source**: Upstream consumers (Deal Estate, Deal Wizard, and other registered clients)
- **Frequency**: On-demand, ~800K RPM sustained

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources (JAX-RS) | Receives and validates HTTP request | `continuumVoucherInventoryApi` |
| Inventory Product Service | Core orchestration: cache lookup, DB fallback, enrichment | `continuumVoucherInventoryApi` |
| Redis Cache Client | Reads cached inventory product data | `continuumVoucherInventoryRedis` |
| Inventory DAOs | Reads product and unit data from MySQL on cache miss | `continuumVoucherInventoryProductDb`, `continuumVoucherInventoryUnitsDb` |
| Pricing Client | Fetches dynamic pricing and feature controls | `continuumPricingService` |
| Booking Client | Fetches availability segments (when enabled) | `continuumCalendarService` |
| MessageBus Publisher | Publishes update event on cache refresh | `messageBus` |

## Steps

1. **Receives request**: Consumer sends `GET /inventory/v1/products?ids=<list>` with required headers (`Accept-Language`, `X-Country-Code`, `X-Request-Id`)
   - From: upstream consumer
   - To: `continuumVoucherInventoryApi` (JAX-RS API Resources)
   - Protocol: REST/HTTP

2. **Validates request**: API Resources validates required headers and query parameters; dispatches to Inventory Product Service
   - From: API Resources
   - To: Inventory Product Service
   - Protocol: direct (in-process)

3. **Checks Redis cache**: Inventory Product Service queries Redis Cache Client for each requested product ID
   - From: `continuumVoucherInventoryApi` (Redis Cache Client)
   - To: `continuumVoucherInventoryRedis`
   - Protocol: Redis

4. **Cache hit path**: For products found in Redis, returns cached inventory data directly (no DB or enrichment calls for cached items)
   - From: `continuumVoucherInventoryRedis`
   - To: Inventory Product Service (in-process)
   - Protocol: Redis

5. **Cache miss path — reads Product DB**: For products not in cache, Inventory DAOs query `voucher_inventory_production` database for product records
   - From: `continuumVoucherInventoryApi` (Inventory DAOs)
   - To: `continuumVoucherInventoryProductDb`
   - Protocol: JDBI/MySQL

6. **Cache miss path — reads Units DB**: Inventory DAOs query the VIS 2.0 units database for unit sold counts and barcode data
   - From: `continuumVoucherInventoryApi` (Inventory DAOs)
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: JDBI/MySQL

7. **Fetches pricing**: Pricing Client calls Pricing Service to retrieve dynamic pricing and feature controls for the requested products (client ID: `418587d4-c892-49fe-9a27-63928a4b7eb2`)
   - From: `continuumVoucherInventoryApi` (Pricing Client)
   - To: `continuumPricingService`
   - Protocol: HTTP (OkHttp/Retrofit); timeout: connectTimeout 150ms, readTimeout 600ms (production cloud)

8. **Fetches availability** (conditional): When `enableCalendarService: true` and the product acquisition method is in the HBW list, Booking Client calls Calendar Service for availability segments (`/v1/products/segments`, `/v1/products/availability`)
   - From: `continuumVoucherInventoryApi` (Booking Client)
   - To: `continuumCalendarService`
   - Protocol: HTTP (OkHttp/Retrofit); timeout: connectTimeout 150ms, readTimeout 600ms (production cloud)

9. **Writes to Redis cache**: Inventory Product Service writes the assembled result back to Redis with `inventoryProductTTL` of 10,800 seconds
   - From: `continuumVoucherInventoryApi` (Redis Cache Client)
   - To: `continuumVoucherInventoryRedis`
   - Protocol: Redis

10. **Publishes update event** (conditional): If the product data changed during this request, MessageBus Publisher emits an event to `jms.topic.InventoryProducts.Updated.Vis`
    - From: `continuumVoucherInventoryApi` (MessageBus Publisher)
    - To: `messageBus`
    - Protocol: JMS/STOMP

11. **Returns response**: Inventory Product Service returns the enriched inventory product list to the caller
    - From: `continuumVoucherInventoryApi` (API Resources)
    - To: upstream consumer
    - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pricing Service timeout / unavailable | Falls back to contracted price | Response returned with contracted price; no error surfaced to consumer |
| Calendar Service unavailable | Controlled by `enableCalendarService` flag; skipped if false | Response returned without availability segments |
| Redis unavailable | Falls through to MySQL reads | Increased DB load; response still served |
| MySQL unavailable | No explicit fallback documented | Request fails; 503 returned |
| Invalid / missing required headers | HTTP 400 Bad Request | Error returned to consumer |
| Unauthorized client ID | HTTP 403 Forbidden | Error returned; check Hybrid Boundary client registration |

## Sequence Diagram

```
Consumer           -> VoucherInventoryApi: GET /inventory/v1/products?ids=...
VoucherInventoryApi -> Redis:              GET product cache entries
Redis              --> VoucherInventoryApi: cache hit (partial or full)
VoucherInventoryApi -> ProductDB:          SELECT products (cache miss IDs only)
VoucherInventoryApi -> UnitsDB:            SELECT units, sold counts (cache miss IDs)
VoucherInventoryApi -> PricingService:     GET dynamic pricing / feature controls
PricingService     --> VoucherInventoryApi: pricing data (fallback: contracted price)
VoucherInventoryApi -> CalendarService:    GET /v1/products/segments (if enabled)
CalendarService    --> VoucherInventoryApi: availability segments
VoucherInventoryApi -> Redis:              SET enriched product entries (TTL: 10800s)
VoucherInventoryApi -> MessageBus:         PUBLISH InventoryProducts.Updated.Vis (if changed)
VoucherInventoryApi --> Consumer:          200 OK inventory product list (JSON)
```

## Related

- Architecture ref: `components-voucherInventoryApi`
- Related flows: [Inventory Event Processing](inventory-event-processing.md)
- API surface: [API Surface](../api-surface.md)
- Integrations: [Integrations](../integrations.md)

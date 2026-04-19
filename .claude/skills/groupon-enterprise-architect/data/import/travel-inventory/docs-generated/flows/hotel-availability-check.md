---
service: "travel-inventory"
title: "Hotel Availability Check"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "hotel-availability-check"
flow_type: synchronous
trigger: "API call -- GET availability summary, detail, or calendar endpoints"
participants:
  - "continuumTravelInventoryService"
  - "continuumTravelInventoryDb"
  - "continuumTravelInventoryHotelProductCache"
  - "continuumTravelInventoryInventoryProductCache"
  - "continuumBackpackAvailabilityCache"
  - "continuumBackpackReservationService"
  - "continuumContentService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-hotel-availability-check"
---

# Hotel Availability Check

## Summary

This flow handles consumer and shopping service queries for hotel availability and pricing. The Shopping API receives an availability request (summary, detail, or calendar), checks Redis and Memcached caches for pre-computed data, fetches missing data from MySQL and external services (Backpack, Content, Voucher Inventory, Forex), applies pricing and currency calculations, and returns a structured availability response. Caching at multiple layers ensures fast response times for repeated queries.

## Trigger

- **Type**: api-call
- **Source**: Consumer shopping services or internal tooling calling availability endpoints
- **Frequency**: Per-request, high volume during shopping peak hours

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopping API | Receives availability request and returns structured response | `continuumTravelInventoryService_shoppingApi` |
| Shopping Domain Services | Orchestrates availability logic, pricing calculations, and cache coordination | `continuumTravelInventoryService_shoppingDomain` |
| Caching Layer | Serves cached hotel product and inventory product data from Redis | `continuumTravelInventoryService_caching` |
| Backpack Memcache Integration | Serves cached Backpack availability results from Memcached | `continuumTravelInventoryService_memcacheIntegration` |
| Persistence Layer | Falls back to MySQL for uncached data | `continuumTravelInventoryService_persistence` |
| Hotel Product Detail Cache | Redis cache for hotel product details | `continuumTravelInventoryHotelProductCache` |
| Inventory Product Cache | Redis cache for inventory product snapshots | `continuumTravelInventoryInventoryProductCache` |
| Backpack Availability Cache | Memcached cache for Backpack availability results | `continuumBackpackAvailabilityCache` |
| Getaways Inventory DB | Source of truth for inventory, pricing, and availability data | `continuumTravelInventoryDb` |
| Backpack Reservation Service | Provides live availability when cache misses | `continuumBackpackReservationService` |
| Getaways Content Service | Provides hotel contact and content details for enriched responses | `continuumContentService` |
| Voucher Inventory Service | Provides voucher-based inventory product data | `continuumVoucherInventoryService` |
| Forex Client | Fetches foreign exchange rates for multi-currency pricing | `continuumTravelInventoryService_forexClient` |

## Steps

1. **Receive availability request**: Consumer or shopping service calls `GET /v2/getaways/inventory/availability/summary`, `/availability/detail`, or `/availability/calendar` with hotel, date range, and guest parameters.
   - From: `caller`
   - To: `continuumTravelInventoryService_shoppingApi`
   - Protocol: REST

2. **Delegate to Shopping Domain**: Shopping API passes the parsed request to Shopping Domain Services for orchestration.
   - From: `continuumTravelInventoryService_shoppingApi`
   - To: `continuumTravelInventoryService_shoppingDomain`
   - Protocol: direct

3. **Check Hotel Product Detail Cache**: Shopping Domain queries the Caching Layer for cached hotel product detail data in Redis.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_caching` -> `continuumTravelInventoryHotelProductCache`
   - Protocol: Redis

4. **Check Inventory Product Cache**: Shopping Domain queries the Caching Layer for cached inventory product snapshots in Redis.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_caching` -> `continuumTravelInventoryInventoryProductCache`
   - Protocol: Redis

5. **Check Backpack Availability Cache**: Shopping Domain queries the Backpack Memcache Integration for cached Backpack availability results in Memcached.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_memcacheIntegration` -> `continuumBackpackAvailabilityCache`
   - Protocol: Memcached

6. **Fetch uncached data from database**: For any cache misses, the Persistence Layer reads inventory, pricing, and availability data from MySQL.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

7. **Fetch Backpack availability (if cache miss)**: If Backpack availability is not cached, Shopping Domain calls the Backpack Reservation Service via HTTP clients.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_httpClients` -> `continuumBackpackReservationService`
   - Protocol: HTTP, JSON

8. **Fetch content details**: Shopping Domain calls the Content Service for hotel contact and localized content to enrich the response.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_httpClients` -> `continuumContentService`
   - Protocol: HTTP, JSON

9. **Fetch voucher inventory data (if applicable)**: For products with a voucher component, Shopping Domain calls the Voucher Inventory Service.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_httpClients` -> `continuumVoucherInventoryService`
   - Protocol: HTTP, JSON

10. **Fetch forex rates (if multi-currency)**: If multi-currency pricing is required, Shopping Domain calls the Forex Client for exchange rates.
    - From: `continuumTravelInventoryService_shoppingDomain`
    - To: `continuumTravelInventoryService_forexClient`
    - Protocol: HTTP

11. **Calculate pricing and assemble response**: Shopping Domain applies pricing logic, currency conversions, and business rules to produce the availability response.
    - From: `continuumTravelInventoryService_shoppingDomain`
    - To: `continuumTravelInventoryService_shoppingDomain` (internal)
    - Protocol: direct

12. **Update caches**: Caching Layer and Backpack Memcache Integration write fetched data back to Redis and Memcached for subsequent requests.
    - From: `continuumTravelInventoryService_shoppingDomain`
    - To: `continuumTravelInventoryService_caching`, `continuumTravelInventoryService_memcacheIntegration`
    - Protocol: Redis, Memcached

13. **Return availability response**: Shopping API returns the structured availability response to the caller.
    - From: `continuumTravelInventoryService_shoppingApi`
    - To: `caller`
    - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis cache unavailable | Fallback to MySQL direct reads | Response served with elevated latency; no data loss |
| Memcached cache unavailable | Fallback to live Backpack availability call | Response served with elevated latency |
| Backpack Reservation Service unavailable | Cached availability used if available; otherwise error | Partial or error response depending on cache state |
| Content Service unavailable | Availability returned without content enrichment | Response served without hotel content details |
| Voucher Inventory Service unavailable | Voucher-dependent products omitted or error returned | Partial availability for voucher products |
| Forex Service unavailable | Cached exchange rates used if available; otherwise single-currency only | Multi-currency pricing may be absent |
| MySQL read failure | Error returned to caller | HTTP 500 |

## Sequence Diagram

```
caller -> continuumTravelInventoryService_shoppingApi: GET /availability/summary|detail|calendar
continuumTravelInventoryService_shoppingApi -> continuumTravelInventoryService_shoppingDomain: delegate request
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_caching: check hotel product cache (Redis)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_caching: check inventory product cache (Redis)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_memcacheIntegration: check Backpack availability cache (Memcached)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_persistence: read uncached data (MySQL)
continuumTravelInventoryService_shoppingDomain -> continuumBackpackReservationService: fetch live availability (if cache miss)
continuumTravelInventoryService_shoppingDomain -> continuumContentService: fetch hotel content
continuumTravelInventoryService_shoppingDomain -> continuumVoucherInventoryService: fetch voucher inventory (if applicable)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_forexClient: fetch forex rates (if multi-currency)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_shoppingDomain: calculate pricing + assemble response
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_caching: update caches
continuumTravelInventoryService_shoppingApi --> caller: 200 OK + availability response
```

## Related

- Architecture dynamic view: `dynamic-hotel-availability-check`
- Related flows: [Reservation Creation](reservation-creation.md), [Backpack Reservation Sync](backpack-reservation-sync.md)

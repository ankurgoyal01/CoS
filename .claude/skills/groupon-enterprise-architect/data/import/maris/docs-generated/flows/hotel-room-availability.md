---
service: "maris"
title: "Hotel Room Availability"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "hotel-room-availability"
flow_type: synchronous
trigger: "API call — GET /getaways/v2/marketrate/hotels/{id}/rooms or GET /inventory/v1/products/availability"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "unknown_expediarapidapi_12b321ae"
  - "unknown_getawayscontentservice_1dc01dfc"
  - "unknown_travelsearchservice_f8dcf9f9"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Hotel Room Availability

## Summary

This flow retrieves real-time hotel room availability and pricing from the Expedia Rapid (or EAN) API and returns enriched results to the calling service. It is the primary read path for the Getaways vertical, enabling consumers such as Travel Search to display available hotel rooms with current rates. Metadata enrichment is performed via calls to the Content Service and Travel Search Service.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon services (Travel Search Service, Deal Catalog Service, or other Getaways consumers)
- **Frequency**: Per-request (on-demand, driven by user search or catalog queries)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (Travel Search / Deal Catalog) | Initiates availability request | `unknown_travelsearchservice_f8dcf9f9` / `continuumDealCatalogService` |
| MARIS Service | Orchestrates availability query, enrichment, and response assembly | `continuumTravelInventoryService` |
| Expedia Rapid API | Returns real-time room availability and pricing | `unknown_expediarapidapi_12b321ae` (stub) |
| Content Service | Provides hotel content metadata for enrichment | `unknown_getawayscontentservice_1dc01dfc` (stub) |
| Travel Search Service | Provides additional hotel details for enrichment | `unknown_travelsearchservice_f8dcf9f9` (stub) |
| MARIS MySQL | Consulted for existing product/unit state if needed | `marisMySql` |

## Steps

1. **Receives availability request**: Caller sends GET to `/getaways/v2/marketrate/hotels/{id}/rooms` or `/inventory/v1/products/availability`
   - From: `continuumTravelInventoryService` (API Resources layer)
   - To: `continuumTravelInventoryService` (Core Orchestration)
   - Protocol: Internal dispatch (JAX-RS resource to service)

2. **Queries Expedia Rapid API for room availability**: Sends authenticated HTTPS request to Expedia Rapid with hotel ID and date parameters
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Expedia Rapid API (`unknown_expediarapidapi_12b321ae`)
   - Protocol: HTTPS REST

3. **Fetches hotel content metadata** (enrichment): Calls Content Service to retrieve hotel metadata for the response
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Content Service (`unknown_getawayscontentservice_1dc01dfc`)
   - Protocol: HTTP/JSON

4. **Fetches travel search hotel details** (enrichment, if applicable): Calls Travel Search Service for additional hotel details
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Travel Search Service (`unknown_travelsearchservice_f8dcf9f9`)
   - Protocol: HTTP/JSON

5. **Assembles and returns enriched availability response**: Combines Expedia availability/pricing data with content and search metadata; returns structured JSON response to caller
   - From: `continuumTravelInventoryService`
   - To: Caller
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Expedia Rapid API unavailable | Return error response to caller | Caller receives 5xx or availability-not-found response |
| Expedia Rapid API returns no rooms | Return empty availability response | Caller receives valid empty result set |
| Content Service unavailable | Proceed with partial enrichment or degraded response | Room availability returned without full content metadata |
| Travel Search Service unavailable | Proceed with partial enrichment or degraded response | Room availability returned without travel search details |
| Invalid hotel ID | Expedia returns error; MARIS propagates | Caller receives 4xx response |

## Sequence Diagram

```
Caller -> MARIS: GET /getaways/v2/marketrate/hotels/{id}/rooms
MARIS -> ExpediaRapidAPI: GET availability/rooms (HTTPS)
ExpediaRapidAPI --> MARIS: Room availability and pricing
MARIS -> ContentService: GET hotel/{id} metadata (HTTP/JSON)
ContentService --> MARIS: Hotel content metadata
MARIS -> TravelSearchService: GET hotel details (HTTP/JSON)
TravelSearchService --> MARIS: Hotel details
MARIS --> Caller: Enriched room availability response (JSON)
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Hotel Reservation Booking](hotel-reservation-booking.md)

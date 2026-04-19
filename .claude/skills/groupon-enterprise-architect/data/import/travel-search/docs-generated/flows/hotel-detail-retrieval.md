---
service: "travel-search"
title: "Hotel Detail Retrieval Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "hotel-detail-retrieval"
flow_type: synchronous
trigger: "REST API call from Getaways client application"
participants:
  - "externalGetawaysClients_2f4a"
  - "travelSearch_apiResources"
  - "hotelDetailsManager"
  - "travelSearch_cacheLayer"
  - "travelSearch_persistenceLayer"
  - "travelSearch_externalClients"
  - "externalContentService_3b91"
  - "externalInventoryService_5d2a"
  - "externalExpediaEanApi_a1b2"
  - "continuumForexService"
  - "travelSearch_mbusPublisher"
architecture_ref: "dynamic-hotelSearchFlow"
---

# Hotel Detail Retrieval Flow

## Summary

This synchronous flow handles requests for a specific hotel's full detail page — content, availability, rates, and metadata. The `hotelDetailsManager` attempts a Redis cache read first; on a cache miss it fetches content from the Content Service and availability/rates from the Inventory Service and Expedia EAN API, merges the data, writes it back to cache and persistence, and optionally triggers an MDS update publication if the merged data has changed.

## Trigger

- **Type**: api-call
- **Source**: Getaways client application (`externalGetawaysClients_2f4a`) — `GET /travel-search/v1/hotels/{hotelId}`
- **Frequency**: On-demand (per hotel detail page view)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Clients | Requests hotel detail page | `externalGetawaysClients_2f4a` |
| REST Resources | Receives and routes HTTP request | `travelSearch_apiResources` |
| Hotel Details Manager | Orchestrates detail fetch, merge, cache, and MDS trigger | `hotelDetailsManager` |
| Cache Layer | Reads and writes hotel data in Redis | `travelSearch_cacheLayer` |
| Persistence Layer | Reads and writes hotel data in MySQL | `travelSearch_persistenceLayer` |
| External Service Clients | Issues outbound HTTP calls to content, inventory, EAN, and forex | `travelSearch_externalClients` |
| Content Service | Provides hotel content attributes | `externalContentService_3b91` |
| Inventory Service | Provides availability summaries | `externalInventoryService_5d2a` |
| Expedia EAN API | Provides live hotel availability and rates | `externalExpediaEanApi_a1b2` |
| Forex Service | Provides currency conversion rates for multi-currency display | `continuumForexService` |
| MBus Publisher | Publishes MDS hotel update if data has changed | `travelSearch_mbusPublisher` |

## Steps

1. **Receives hotel detail request**: Getaways client requests detail for a specific hotel ID with optional check-in/check-out dates.
   - From: `externalGetawaysClients_2f4a`
   - To: `travelSearch_apiResources`
   - Protocol: REST (HTTP GET)

2. **Routes to Hotel Details Manager**: REST resource validates the request and delegates to `hotelDetailsManager`.
   - From: `travelSearch_apiResources`
   - To: `hotelDetailsManager`
   - Protocol: direct

3. **Reads cached hotel data**: Attempts to read the hotel's full data record from Redis.
   - From: `hotelDetailsManager`
   - To: `travelSearch_cacheLayer`
   - Protocol: direct (Redis)

4. **Falls back to persistent data on cache miss**: If Redis has no record, reads the stored hotel record from MySQL.
   - From: `travelSearch_cacheLayer`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean / MySQL)

5. **Fetches hotel content**: Calls Content Service to retrieve up-to-date content attributes for the hotel.
   - From: `travelSearch_externalClients`
   - To: `externalContentService_3b91`
   - Protocol: REST

6. **Fetches availability summary**: Calls Inventory Service to retrieve current availability status.
   - From: `travelSearch_externalClients`
   - To: `externalInventoryService_5d2a`
   - Protocol: REST

7. **Fetches live rates from EAN**: Calls Expedia EAN API to retrieve live room availability and rate data for the requested dates.
   - From: `travelSearch_externalClients`
   - To: `externalExpediaEanApi_a1b2`
   - Protocol: REST

8. **Retrieves currency conversion rates**: Calls Forex Service to get current currency rates for multi-currency rate display.
   - From: `travelSearch_externalClients`
   - To: `continuumForexService`
   - Protocol: REST

9. **Merges hotel data**: Hotel Details Manager combines content, availability, EAN rates, and currency data into a unified hotel detail response.
   - From: `hotelDetailsManager` (internal merge)
   - To: `hotelDetailsManager`
   - Protocol: direct

10. **Writes merged data to cache**: Stores the merged hotel detail record in Redis for subsequent requests.
    - From: `hotelDetailsManager`
    - To: `travelSearch_cacheLayer`
    - Protocol: direct (Redis)

11. **Writes merged data to persistence**: Persists the merged hotel detail to MySQL.
    - From: `hotelDetailsManager`
    - To: `travelSearch_persistenceLayer`
    - Protocol: direct (Ebean / MySQL)

12. **Publishes MDS update if changed**: If the merged data differs from the previously persisted record, triggers an MDS hotel update event via the MBus Publisher.
    - From: `hotelDetailsManager`
    - To: `travelSearch_mbusPublisher`
    - Protocol: direct (JMS)

13. **Returns hotel detail response**: REST resource serialises and returns the hotel detail to the client.
    - From: `travelSearch_apiResources`
    - To: `externalGetawaysClients_2f4a`
    - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis cache unavailable | Fall through to MySQL persistence read | Increased latency; no cache write on this request |
| Content Service unavailable | Return hotel record without content fields | Partial detail response returned to client |
| Inventory Service unavailable | Return hotel record without availability | Detail response returned without availability status |
| EAN API unavailable | Return cached or stored rates | Potentially stale rate data returned |
| Forex Service unavailable | Return rates in base currency only | Multi-currency display degraded |
| MBus publish failure | Log failure; next detail fetch or MDS control API call retries | MDS downstream consumers may receive delayed update |

## Sequence Diagram

```
GetawaysClients       -> travelSearch_apiResources  : GET /travel-search/v1/hotels/{hotelId}
travelSearch_apiResources -> hotelDetailsManager    : Hotel detail request
hotelDetailsManager   -> travelSearch_cacheLayer    : Read cache
travelSearch_cacheLayer -> travelSearch_persistenceLayer : Fallback to DB (cache miss)
hotelDetailsManager   -> travelSearch_externalClients   : Fetch content, inventory, EAN rates, forex
travelSearch_externalClients -> externalContentService_3b91 : Fetch content
travelSearch_externalClients -> externalInventoryService_5d2a : Fetch availability
travelSearch_externalClients -> externalExpediaEanApi_a1b2   : Fetch live rates
travelSearch_externalClients -> continuumForexService        : Get currency rates
hotelDetailsManager   -> travelSearch_cacheLayer    : Write merged data to cache
hotelDetailsManager   -> travelSearch_persistenceLayer : Write merged data to DB
hotelDetailsManager   -> travelSearch_mbusPublisher : Publish MDS update (if changed)
travelSearch_apiResources --> GetawaysClients       : HTTP 200 hotel detail
```

## Related

- Architecture dynamic view: `dynamic-hotelSearchFlow`
- Related flows: [Hotel Search Flow](hotel-search-flow.md), [MDS Hotel Update Flow](mds-hotel-update.md)

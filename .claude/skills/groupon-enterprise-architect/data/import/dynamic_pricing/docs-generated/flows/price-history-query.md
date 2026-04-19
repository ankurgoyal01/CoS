---
service: "dynamic_pricing"
title: "Price History Query"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "price-history-query"
flow_type: synchronous
trigger: "GET /pricing_service/v2.0/history/quote_id/{id}"
participants:
  - "continuumDynamicPricingNginx"
  - "continuumPricingService_priceHistoryController"
  - "continuumPricingService_quotePriceHistoryService"
  - "continuumPricingService_priceHistoryService"
  - "continuumPricingService_pricingDbRepository"
  - "continuumPricingDb"
architecture_ref: "dynamic-pricing-nginx-request-routing"
---

# Price History Query

## Summary

This flow handles a synchronous read request to retrieve historical price records associated with a specific quote ID. The service looks up the stored price history from the pricing database, assembles the historical timeline (including established price calculations where applicable), and returns the result to the caller. This flow is used for audit, reporting, and customer-facing price transparency purposes.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services querying price history for audit or reporting via `apiProxy` and `continuumDynamicPricingNginx`
- **Frequency**: On-demand; lower frequency than current price lookups

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dynamic Pricing NGINX | Receives and routes inbound request | `continuumDynamicPricingNginx` |
| Price History Controller | Accepts and parses GET price history request by quote ID | `continuumPricingService_priceHistoryController` |
| Quote Price History Service | Handles quote-based price history retrieval workflow | `continuumPricingService_quotePriceHistoryService` |
| Price History Service | Builds historical price timeline and established price data | `continuumPricingService_priceHistoryService` |
| Pricing DB Repository | Queries price history records and established price data | `continuumPricingService_pricingDbRepository` |
| Pricing Service DB | Authoritative store for price history records | `continuumPricingDb` |

## Steps

1. **Receive request**: Caller sends GET to `/pricing_service/v2.0/history/quote_id/{id}`.
   - From: `apiProxy`
   - To: `continuumDynamicPricingNginx`
   - Protocol: HTTPS

2. **Proxy to pricing pod**: NGINX routes to a read-capable pricing pod.
   - From: `continuumDynamicPricingNginx`
   - To: `continuumPricingService_priceHistoryController`
   - Protocol: HTTP

3. **Delegate to history services**: Price History Controller dispatches the quote ID to the Quote Price History Service and Price History Service.
   - From: `continuumPricingService_priceHistoryController`
   - To: `continuumPricingService_quotePriceHistoryService`
   - Protocol: direct

4. **Retrieve quote price history**: Quote Price History Service queries `continuumPricingDb` for records matching the given quote ID.
   - From: `continuumPricingService_pricingDbRepository`
   - To: `continuumPricingDb`
   - Protocol: JDBC

5. **Build price history timeline**: Price History Service assembles the historical price timeline and computes established price metrics from the retrieved records.
   - From: `continuumPricingService_priceHistoryService`
   - To: `continuumPricingService_pricingDbRepository` -> `continuumPricingDb`
   - Protocol: JDBC

6. **Return history response**: Assembled price history is returned to the caller.
   - From: `continuumPricingService_priceHistoryController`
   - To: `apiProxy` (via `continuumDynamicPricingNginx`)
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Quote ID not found | Service returns empty or not-found response | Caller receives empty history; no error thrown |
| DB unavailable | Request fails | Caller receives error response |
| Large result set | No evidence found for pagination handling | Response may be large; no pagination confirmed in available inventory |

## Sequence Diagram

```
apiProxy -> continuumDynamicPricingNginx: GET /pricing_service/v2.0/history/quote_id/{id}
continuumDynamicPricingNginx -> continuumPricingService_priceHistoryController: Proxy request (HTTP)
continuumPricingService_priceHistoryController -> continuumPricingService_quotePriceHistoryService: Lookup quote price history
continuumPricingService_quotePriceHistoryService -> continuumPricingDb: Query price history by quote ID (JDBC)
continuumPricingDb --> continuumPricingService_quotePriceHistoryService: Price history records
continuumPricingService_priceHistoryController -> continuumPricingService_priceHistoryService: Build price timeline and established price
continuumPricingService_priceHistoryService -> continuumPricingDb: Query established price data (JDBC)
continuumPricingDb --> continuumPricingService_priceHistoryService: Established price data
continuumPricingService_priceHistoryService --> continuumPricingService_priceHistoryController: Assembled price history
continuumPricingService_priceHistoryController --> continuumDynamicPricingNginx: 200 OK + price history
continuumDynamicPricingNginx --> apiProxy: 200 OK + price history
```

## Related

- Architecture dynamic view: `dynamic-pricing-nginx-request-routing`
- Related flows: [Get Current Price Cache Lookup](get-current-price-cache-lookup.md), [Create Retail Price](create-retail-price.md)
- See [Data Stores](../data-stores.md) for price history entity details

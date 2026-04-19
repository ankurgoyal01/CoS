---
service: "cs-api"
title: "Deal and Order Inquiry"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-order-inquiry"
flow_type: synchronous
trigger: "Agent looks up orders or deals for a customer"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "serviceClients"
  - "continuumOrdersService"
  - "continuumDealCatalogService"
  - "continuumGoodsInventoryService"
  - "lazloApi"
  - "continuumGoodsCentralService"
architecture_ref: "dynamic-cs-api"
---

# Deal and Order Inquiry

## Summary

This flow handles agent requests to look up orders placed by a customer and to retrieve deal details associated with those orders. CS API queries the Orders Service for order history, then enriches each order with deal metadata from the Deal Catalog Service. Goods inventory data is fetched from `continuumGoodsInventoryService` and `continuumGoodsCentralService` for physical goods orders, and `lazloApi` is queried for additional deal or API context where applicable.

## Trigger

- **Type**: api-call
- **Source**: Cyclops CS agent web application (GET `/orders` or GET `/deals`)
- **Frequency**: On-demand; each time an agent views an order or deal for a customer

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Requests order or deal data | `customerSupportAgent` |
| CS API Service | Orchestrates inquiry | `continuumCsApiService` |
| API Resources | Handles HTTP request; assembles response | `csApi_apiResources` |
| Service Clients | Issues downstream HTTP calls | `serviceClients` |
| Orders Service | Returns order history for a customer | `continuumOrdersService` |
| Deal Catalog Service | Returns deal metadata by deal ID | `continuumDealCatalogService` |
| Goods Inventory Service | Returns goods inventory details | `continuumGoodsInventoryService` |
| Lazlo API | Returns additional deal/API context data | `lazloApi` |
| Goods Central Service | Returns goods product data | `continuumGoodsCentralService` |

## Steps

1. **Receive order or deal inquiry**: Cyclops sends GET `/orders?customerId=<id>` or GET `/deals?dealId=<id>`.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Query orders**: For `/orders`, `serviceClients` calls `continuumOrdersService` to retrieve order history.
   - From: `serviceClients`
   - To: `continuumOrdersService`
   - Protocol: HTTP

3. **Load deal data**: For each order (or for a direct `/deals` request), `serviceClients` calls `continuumDealCatalogService` to load deal metadata.
   - From: `serviceClients`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP

4. **Fetch goods inventory** (for physical goods): `serviceClients` calls `continuumGoodsInventoryService` to retrieve inventory status.
   - From: `serviceClients`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP

5. **Fetch Lazlo data** (where applicable): `serviceClients` calls `lazloApi` for additional deal context or API data.
   - From: `serviceClients`
   - To: `lazloApi`
   - Protocol: HTTP

6. **Fetch goods central data** (for product details): `serviceClients` calls `continuumGoodsCentralService` for product-level detail.
   - From: `serviceClients`
   - To: `continuumGoodsCentralService`
   - Protocol: HTTP

7. **Assemble enriched response**: `csApi_apiResources` merges order, deal, inventory, and product data into a response object.
   - From: `csApi_apiResources`
   - To: `csApi_apiResources`
   - Protocol: Internal

8. **Return deal/order data to agent**: Response returned to Cyclops.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders Service unavailable | HTTP call fails | 503 returned; agent cannot view order history |
| Deal Catalog unavailable | HTTP call fails | Partial response; deal metadata missing from order |
| Goods Inventory unavailable | HTTP call fails | Partial response; inventory status missing |
| Lazlo API unavailable | HTTP call fails | Partial response; supplemental deal context missing |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : GET /orders?customerId=X
csApi_apiResources -> serviceClients  : Fetch orders
serviceClients -> continuumOrdersService : GET orders (HTTP)
continuumOrdersService --> serviceClients : Order list
csApi_apiResources -> serviceClients  : Load deal data
serviceClients -> continuumDealCatalogService : GET deal (HTTP)
continuumDealCatalogService --> serviceClients : Deal metadata
csApi_apiResources -> serviceClients  : Fetch goods inventory
serviceClients -> continuumGoodsInventoryService : GET inventory (HTTP)
continuumGoodsInventoryService --> serviceClients : Inventory data
csApi_apiResources -> serviceClients  : Fetch Lazlo data
serviceClients -> lazloApi            : GET data (HTTP)
lazloApi --> serviceClients           : Lazlo response
csApi_apiResources -> serviceClients  : Fetch goods central
serviceClients -> continuumGoodsCentralService : GET goods (HTTP)
continuumGoodsCentralService --> serviceClients : Goods data
csApi_apiResources --> CyclopsUI      : 200 { orders/deals }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Customer Info Aggregation](customer-info-aggregation.md), [Convert to Cash Refund](convert-to-cash-refund.md)

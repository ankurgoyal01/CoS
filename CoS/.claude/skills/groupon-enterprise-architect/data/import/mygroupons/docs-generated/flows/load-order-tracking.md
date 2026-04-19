---
service: "mygroupons"
title: "Load Order Tracking"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "load-order-tracking"
flow_type: synchronous
trigger: "User views /mygroupons/track-order/:id"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumThirdPartyInventoryService"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-mygroupons-order-tracking"
---

# Load Order Tracking

## Summary

This flow renders the shipment tracking page for a physical goods order. The service fetches the order record and then calls Third-Party Inventory Service to retrieve current shipment tracking status (carrier, tracking number, estimated delivery). Deal metadata is fetched in parallel to display the product context alongside the tracking information.

## Trigger

- **Type**: user-action
- **Source**: Browser GET request to `/mygroupons/track-order/:id`
- **Frequency**: On demand — triggered when a customer checks the shipping status of a physical goods order

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests tracking page; views shipment status | — |
| My Groupons Service | Route handler, tracking data orchestration, SSR | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and confirms order ownership | `continuumUsersService` |
| Orders Service | Returns order details including shipment reference | `continuumOrdersService` |
| Third-Party Inventory Service | Returns carrier tracking status for the shipment | `continuumThirdPartyInventoryService` |
| Deal Catalog Service | Returns deal/product metadata for display | `continuumDealCatalogService` |

## Steps

1. **Receives tracking request**: Browser sends `GET /mygroupons/track-order/:id` with session cookie.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session and ownership**: keldor validates session; Users Service confirms the user owns the order.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches order details**: Retrieves the order record including shipment reference identifiers.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Fan-out: tracking and deal data**: In parallel, fetches shipment tracking status from Third-Party Inventory Service and deal/product metadata from Deal Catalog.
   - From: `continuumMygrouponsService`
   - To: `continuumThirdPartyInventoryService`, `continuumDealCatalogService` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Fetches page layout**: Requests global page layout from Layout Service.
   - From: `continuumMygrouponsService`
   - To: Layout Service (via `apiProxy`)
   - Protocol: REST/HTTP

6. **Renders tracking page**: Merges order, tracking, deal, and layout data; renders the tracking page using Preact and Mustache, showing carrier name, tracking number, status timeline, and estimated delivery date.
   - From: `continuumMygrouponsService` (internal)
   - To: `continuumMygrouponsService` (internal)
   - Protocol: direct

7. **Returns tracking page**: Streams the rendered HTML to the browser.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Order not owned by user | Returns 403 | Permission denied error page |
| Orders Service unavailable | Critical failure | Error page rendered |
| Third-Party Inventory Service unavailable | Non-critical; tracking section shows unavailable message | Page renders with "tracking unavailable" notice |
| No tracking data available for order | Non-critical | Page renders with "tracking not yet available" notice |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/track-order/:id
MyGrouponsService -> APIProxy: validate session + ownership
APIProxy -> UsersService: resolve user
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch order details
APIProxy -> OrdersService: get order by id
OrdersService --> APIProxy: order details (incl. shipment ref)
APIProxy --> MyGrouponsService: order details
MyGrouponsService -> APIProxy: fetch shipment tracking (parallel)
MyGrouponsService -> APIProxy: fetch deal metadata (parallel)
APIProxy -> ThirdPartyInventoryService: get tracking by shipment ref
ThirdPartyInventoryService --> APIProxy: tracking status + carrier info
APIProxy -> DealCatalogService: get deal metadata
DealCatalogService --> APIProxy: deal metadata
APIProxy --> MyGrouponsService: tracking + deal data
MyGrouponsService -> MyGrouponsService: SSR render (Preact + Mustache)
MyGrouponsService --> Browser: tracking page HTML
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-order-tracking`
- Related flows: [Render My Groupons Page](render-mygroupons-page.md), [Exchange Voucher](exchange-voucher.md)

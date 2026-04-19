---
service: "mdi-dashboard-v2"
title: "Deal Performance Tracking"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-performance-tracking"
flow_type: synchronous
trigger: "User views deal detail and options via the /options/:id route"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "apiProxy"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-mdi-deal-performance-tracking"
---

# Deal Performance Tracking

## Summary

The deal performance tracking flow provides users with a detailed view of a specific deal's options and voucher inventory. When a user requests a deal's options via `/options/:id`, the dashboard fetches deal option details from the Deal Catalog Service and voucher inventory counts from the Voucher Inventory Service, then presents the combined data to the user. This flow supports deal monitoring and performance assessment for Marketing and Merchandising operations.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `GET /options/:id` where `:id` is a deal identifier
- **Frequency**: on-demand, per user interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives user request; fetches deal options and inventory data; renders detail view | `continuumMarketingDealServiceDashboard` |
| API Proxy | Routes outbound HTTP calls to internal Continuum services | `apiProxy` |
| Deal Catalog Service | Provides deal option metadata for the specified deal ID | `continuumDealCatalogService` |
| Voucher Inventory Service | Provides voucher inventory counts for the specified deal | `continuumVoucherInventoryService` |

## Steps

1. **Receives deal options request**: User navigates to `GET /options/:id`.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Queries Deal Catalog Service for deal options**: Dashboard sends a request to the Deal Catalog Service to retrieve options for the given deal ID via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> `continuumDealCatalogService`
   - Protocol: REST / HTTP

4. **Returns deal option details**: Deal Catalog Service responds with option metadata (pricing, validity, terms) for the deal.
   - From: `continuumDealCatalogService`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

5. **Queries Voucher Inventory Service for inventory**: Dashboard requests voucher inventory counts for the deal ID from the Voucher Inventory Service via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> `continuumVoucherInventoryService`
   - Protocol: REST / HTTP

6. **Returns voucher inventory data**: Voucher Inventory Service responds with available and total voucher counts.
   - From: `continuumVoucherInventoryService`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

7. **Merges and renders deal detail view**: Dashboard merges deal option data with inventory counts and renders the deal detail page.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service returns 404 | Dashboard returns 404 to user | "Deal not found" page displayed |
| Deal Catalog Service returns 5xx | Dashboard propagates error | Error page displayed; deal options unavailable |
| Voucher Inventory Service returns 5xx | Dashboard renders page without inventory data (non-blocking) | Deal options shown without voucher inventory counts |
| Voucher Inventory Service timeout | Timeout treated as non-blocking; inventory section omitted | User sees deal options without inventory data |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: GET /options/12345
continuumMarketingDealServiceDashboard -> apiProxy: GET /catalog/deals/12345/options
apiProxy -> continuumDealCatalogService: GET /deals/12345/options
continuumDealCatalogService --> apiProxy: 200 OK { options: [...] }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { options: [...] }
continuumMarketingDealServiceDashboard -> apiProxy: GET /vouchers/inventory?dealId=12345
apiProxy -> continuumVoucherInventoryService: GET /inventory?dealId=12345
continuumVoucherInventoryService --> apiProxy: 200 OK { available: 150, total: 500 }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { available: 150, total: 500 }
continuumMarketingDealServiceDashboard --> User: 200 OK (HTML deal detail view)
```

## Related

- Architecture dynamic view: `dynamic-mdi-deal-performance-tracking`
- Related flows: [Deal Intelligence Search](deal-intelligence-search.md), [Merchant Insights](merchant-insights.md)

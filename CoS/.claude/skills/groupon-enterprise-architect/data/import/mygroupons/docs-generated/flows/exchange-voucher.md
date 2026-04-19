---
service: "mygroupons"
title: "Exchange Voucher"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "exchange-voucher"
flow_type: synchronous
trigger: "User submits exchange at /mygroupons/exchanges"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumVoucherInventoryService"
  - "continuumThirdPartyInventoryService"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-mygroupons-exchange-voucher"
---

# Exchange Voucher

## Summary

This flow allows a customer to exchange a purchased voucher for a different option or date within the same deal. The service verifies exchange eligibility via Voucher Inventory Service, checks available inventory through Third-Party Inventory Service, presents exchange options to the user, and processes the exchange. The `order_editing` feature flag gates access to this capability.

## Trigger

- **Type**: user-action
- **Source**: Browser GET (page render) and POST (form submission) to `/mygroupons/exchanges`
- **Frequency**: On demand — triggered when a customer initiates a voucher exchange

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates exchange; selects new option and confirms | — |
| My Groupons Service | Route handler, eligibility and inventory orchestration | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and user identity | `continuumUsersService` |
| Orders Service | Returns current voucher and order details | `continuumOrdersService` |
| Voucher Inventory Service | Checks exchange eligibility; processes exchange | `continuumVoucherInventoryService` |
| Third-Party Inventory Service | Returns available inventory options for exchange | `continuumThirdPartyInventoryService` |
| Deal Catalog Service | Returns deal and option metadata for exchange selection UI | `continuumDealCatalogService` |

## Steps

1. **Renders exchange page**: Browser requests `GET /mygroupons/exchanges`; service validates session and checks the `order_editing` feature flag.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor validates session; Users Service resolves user identity.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches current voucher**: Retrieves the voucher to be exchanged from Orders Service.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Checks exchange eligibility**: Queries Voucher Inventory Service to confirm the voucher can be exchanged.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Fetches available inventory**: Queries Third-Party Inventory Service for available exchange options (e.g., alternate dates or option tiers).
   - From: `continuumMygrouponsService`
   - To: `continuumThirdPartyInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

6. **Fetches deal metadata**: Retrieves deal and option descriptions from Deal Catalog to enrich the exchange selection UI.
   - From: `continuumMygrouponsService`
   - To: `continuumDealCatalogService` (via `apiProxy`)
   - Protocol: REST/HTTP

7. **Renders exchange options**: Merges eligibility, inventory, and deal data; renders the exchange selection form.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

8. **Receives exchange selection**: User selects the new option and submits the exchange form.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

9. **Processes exchange**: Submits the exchange to Voucher Inventory Service with the original and selected new option.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

10. **Returns confirmation**: Renders exchange confirmation page showing the new voucher details.
    - From: `continuumMygrouponsService`
    - To: `browser`
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `order_editing` flag disabled | Route returns feature-unavailable page | User sees exchange not available message |
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Voucher not exchange-eligible | Exchange form shows ineligibility reason | User sees reason for ineligibility |
| No inventory available | No exchange options shown | User informed no options available |
| Voucher Inventory Service unavailable | Critical failure for this route | Error page rendered |
| Third-Party Inventory Service unavailable | No options available | Exchange form shows no available options |
| Exchange submission fails | Error from Voucher Inventory Service | Error message shown; user prompted to retry |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/exchanges?voucherId=:id
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve user
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch voucher (parallel)
MyGrouponsService -> APIProxy: check exchange eligibility (parallel)
APIProxy -> OrdersService: get voucher
OrdersService --> APIProxy: voucher details
APIProxy -> VoucherInventoryService: eligibility check
VoucherInventoryService --> APIProxy: eligibility result
APIProxy --> MyGrouponsService: voucher + eligibility
MyGrouponsService -> APIProxy: fetch inventory options (parallel)
MyGrouponsService -> APIProxy: fetch deal metadata (parallel)
APIProxy -> ThirdPartyInventoryService: available options
ThirdPartyInventoryService --> APIProxy: inventory options
APIProxy -> DealCatalogService: deal metadata
DealCatalogService --> APIProxy: deal metadata
APIProxy --> MyGrouponsService: options + metadata
MyGrouponsService --> Browser: exchange selection form
Browser -> MyGrouponsService: POST /mygroupons/exchanges (selected option)
MyGrouponsService -> APIProxy: submit exchange
APIProxy -> VoucherInventoryService: process exchange
VoucherInventoryService --> APIProxy: exchange confirmation
APIProxy --> MyGrouponsService: exchange confirmation
MyGrouponsService --> Browser: confirmation page
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-exchange-voucher`
- Related flows: [Submit Return Request](submit-return-request.md), [Render My Groupons Page](render-mygroupons-page.md)

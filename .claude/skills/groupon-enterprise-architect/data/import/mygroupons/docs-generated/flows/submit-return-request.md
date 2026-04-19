---
service: "mygroupons"
title: "Submit Return Request"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "submit-return-request"
flow_type: synchronous
trigger: "User submits return form at /mygroupons/returns"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-mygroupons-return-request"
---

# Submit Return Request

## Summary

This flow handles post-purchase return requests for purchased vouchers. The service renders the return page, checks return eligibility against the Voucher Inventory Service (including partial return eligibility controlled by the `partial_returns` feature flag), and submits the return on behalf of the authenticated user. If the `salesforce_ticket_create` flag is enabled, a support ticket may be created in Salesforce alongside the return.

## Trigger

- **Type**: user-action
- **Source**: Browser GET (page render) and POST (form submission) to `/mygroupons/returns`
- **Frequency**: On demand — triggered when a customer initiates a return

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates return; submits return form | — |
| My Groupons Service | Route handler, eligibility orchestration, form processing | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and user identity | `continuumUsersService` |
| Orders Service | Returns order and voucher data for the return candidate | `continuumOrdersService` |
| Voucher Inventory Service | Checks return eligibility; processes return submission | `continuumVoucherInventoryService` |

## Steps

1. **Renders return page**: Browser requests `GET /mygroupons/returns`; service validates session, fetches order/voucher data, checks return eligibility, and renders the return form.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor middleware validates the session cookie and resolves the user.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches order data**: Retrieves the target order and voucher details.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Checks return eligibility**: Queries Voucher Inventory Service to determine if the voucher is eligible for return. If `partial_returns` flag is enabled, checks for partial return eligibility on multi-unit orders.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Renders return form**: Presents eligibility result and return options to the user (full return, partial return if applicable).
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

6. **Receives return form submission**: User selects return reason and quantity, submits the form via POST.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

7. **Submits return to Voucher Inventory Service**: Posts the return request with voucher ID, quantity, and reason code.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

8. **Returns confirmation**: Renders a success or failure confirmation page to the user.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Voucher not eligible for return | Return form shows ineligibility message | User sees reason for ineligibility |
| Voucher Inventory Service unavailable | Critical failure for this route | Error page rendered |
| Return submission rejected | Voucher Inventory Service returns error | Error message shown to user |
| Orders Service unavailable | Critical failure | Error page rendered |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/returns?voucherId=:id
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve user
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch order + voucher data
APIProxy -> OrdersService: get order details
OrdersService --> APIProxy: order + voucher data
APIProxy --> MyGrouponsService: order + voucher data
MyGrouponsService -> APIProxy: check return eligibility
APIProxy -> VoucherInventoryService: eligibility check
VoucherInventoryService --> APIProxy: eligibility result
APIProxy --> MyGrouponsService: eligibility result
MyGrouponsService --> Browser: return form (with eligibility)
Browser -> MyGrouponsService: POST /mygroupons/returns (return reason + quantity)
MyGrouponsService -> APIProxy: submit return
APIProxy -> VoucherInventoryService: process return
VoucherInventoryService --> APIProxy: return confirmation
APIProxy --> MyGrouponsService: return confirmation
MyGrouponsService --> Browser: confirmation page
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-return-request`
- Related flows: [Exchange Voucher](exchange-voucher.md), [Render My Groupons Page](render-mygroupons-page.md)

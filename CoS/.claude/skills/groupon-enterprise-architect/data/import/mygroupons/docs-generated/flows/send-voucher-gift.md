---
service: "mygroupons"
title: "Send Voucher Gift"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "send-voucher-gift"
flow_type: synchronous
trigger: "User submits gifting form at /mygroupons/gifting"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-mygroupons-send-gift"
---

# Send Voucher Gift

## Summary

This flow enables a customer to gift a purchased voucher to another person via email or SMS. The service renders the gifting UI (controlled by `gift_envelope` and `sms_gift` feature flags), validates gift eligibility, collects recipient information, and submits the gift transfer through Voucher Inventory Service. The `gifting_legacy` flag routes to the legacy gifting implementation when enabled.

## Trigger

- **Type**: user-action
- **Source**: Browser GET (page render) and POST (form submission) to `/mygroupons/gifting`
- **Frequency**: On demand — triggered when a customer chooses to gift a voucher

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates gifting; enters recipient information and submits | — |
| My Groupons Service | Route handler, eligibility check, gift submission orchestration | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and sender identity | `continuumUsersService` |
| Orders Service | Returns the voucher to be gifted | `continuumOrdersService` |
| Voucher Inventory Service | Validates gift eligibility; processes the gift transfer | `continuumVoucherInventoryService` |

## Steps

1. **Renders gifting page**: Browser requests `GET /mygroupons/gifting`; service evaluates `gifting_legacy`, `gift_envelope`, and `sms_gift` flags to determine which gifting variant to render.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor validates session; Users Service resolves sender identity.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches voucher details**: Retrieves the target voucher from Orders Service.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Checks gift eligibility**: Validates the voucher can be gifted via Voucher Inventory Service.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Renders gift form**: Presents recipient input fields; shows email delivery by default; SMS delivery option shown if `sms_gift` flag is enabled; gift envelope UI shown if `gift_envelope` flag is enabled.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

6. **Receives gift form submission**: User enters recipient name, email (and/or phone for SMS), optional message, and submits.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

7. **Submits gift transfer**: Posts gift request to Voucher Inventory Service with voucher ID, sender, and recipient details; delivery method (email/SMS) is included.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

8. **Returns gift confirmation**: Renders a confirmation page indicating the gift has been sent to the recipient.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Voucher not giftable | Gift form shows ineligibility reason | User sees reason voucher cannot be gifted |
| Invalid recipient email/phone | Validation error on form | User prompted to correct recipient details |
| Voucher Inventory Service unavailable | Critical failure for this route | Error page rendered |
| Gift transfer rejected | Error from Voucher Inventory Service | Error message shown; user prompted to retry |
| `gifting_legacy` enabled | Routes to legacy gifting handler | Legacy gifting experience rendered |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/gifting?voucherId=:id
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve sender
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch voucher details (parallel)
MyGrouponsService -> APIProxy: check gift eligibility (parallel)
APIProxy -> OrdersService: get voucher
OrdersService --> APIProxy: voucher details
APIProxy -> VoucherInventoryService: gift eligibility check
VoucherInventoryService --> APIProxy: eligibility result
APIProxy --> MyGrouponsService: voucher + eligibility
MyGrouponsService -> MyGrouponsService: evaluate gift_envelope, sms_gift, gifting_legacy flags
MyGrouponsService --> Browser: gift form (email + optional SMS)
Browser -> MyGrouponsService: POST /mygroupons/gifting (recipient + delivery method)
MyGrouponsService -> APIProxy: submit gift transfer
APIProxy -> VoucherInventoryService: process gift
VoucherInventoryService --> APIProxy: gift confirmation
APIProxy --> MyGrouponsService: gift confirmation
MyGrouponsService --> Browser: gift confirmation page
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-send-gift`
- Related flows: [Render My Groupons Page](render-mygroupons-page.md), [Submit Return Request](submit-return-request.md)

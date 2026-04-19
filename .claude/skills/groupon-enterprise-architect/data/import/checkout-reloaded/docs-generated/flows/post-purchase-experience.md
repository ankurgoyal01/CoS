---
service: "checkout-reloaded"
title: "Post-Purchase Experience"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "post-purchase-experience"
flow_type: synchronous
trigger: "Consumer lands on receipt page after order confirmation (GET /receipt/:orderId)"
participants:
  - "Consumer Browser"
  - "continuumCheckoutReloadedService"
  - "checkoutReloaded_api"
  - "checkoutReloaded_orchestrator"
  - "Order Service"
  - "Layout Service"
architecture_ref: "dynamic-checkout-reloaded-request-flow"
---

# Post-Purchase Experience

## Summary

After a successful order finalization, the consumer is directed through a post-purchase sequence: the receipt page is rendered with full order details, an optional post-purchase upsell offers page is presented (controlled by the `checkout.postPurchaseUpsell` feature flag), and the consumer may select and redeem a post-purchase offer. Each step is a synchronous SSR response from the BFF fetching data from the Order Service and related downstream systems.

## Trigger

- **Type**: user-action (redirect from payment processing flow)
- **Source**: Consumer browser follows the redirect to `GET /receipt/:orderId` after successful checkout submission
- **Frequency**: per-request (once per completed order, with additional optional steps for upsell interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Browser | Receives redirect to receipt; views upsell offers; optionally redeems post-purchase offer | — |
| Checkout Reloaded Service | BFF entry point for all post-purchase page renders and redemption submission | `continuumCheckoutReloadedService` |
| Checkout API | Handles GET and POST requests for receipt, post-purchase, and redemption | `checkoutReloaded_api` |
| Checkout Orchestrator | Coordinates data fetches for order details and upsell offers | `checkoutReloaded_orchestrator` |
| Order Service | Provides order details for receipt rendering; processes post-purchase redemption | — |
| Layout Service | Provides shared site header and footer HTML | — |

## Steps

### Receipt Rendering

1. **Receive receipt page request**: Consumer browser sends `GET /receipt/:orderId` (redirected from payment processing).
   - From: `Consumer Browser`
   - To: `checkoutReloaded_api`
   - Protocol: REST / HTTP

2. **Validate session and order ownership**: Checkout API validates session and confirms the consumer owns the requested orderId.
   - From: `checkoutReloaded_api`
   - To: `checkoutReloaded_orchestrator`
   - Protocol: Direct (in-process)

3. **Fetch order details**: Orchestrator calls Order Service to retrieve full order details for the given orderId.
   - From: `checkoutReloaded_orchestrator`
   - To: Order Service (via `API_PROXY_BASE_URL` / `itier-groupon-v2-client`)
   - Protocol: REST / HTTP

4. **Fetch layout fragments**: BFF requests shared header and footer from Layout Service.
   - From: `continuumCheckoutReloadedService`
   - To: Layout Service
   - Protocol: REST / HTTP

5. **Render receipt page via SSR**: Checkout API renders the Preact receipt component with order data and layout fragments; injects Redux state for client hydration.
   - From: `checkoutReloaded_api`
   - To: `Consumer Browser`
   - Protocol: REST / HTTP (HTML response)

### Post-Purchase Upsell (feature-flag gated: `checkout.postPurchaseUpsell`)

6. **Receive post-purchase page request**: Consumer browser navigates to `GET /post-purchase`.
   - From: `Consumer Browser`
   - To: `checkoutReloaded_api`
   - Protocol: REST / HTTP

7. **Fetch upsell offers**: Orchestrator fetches post-purchase upsell offers relevant to the consumer's order from downstream service(s).
   - From: `checkoutReloaded_orchestrator`
   - To: Order Service / Deal Catalog Service (via API Proxy)
   - Protocol: REST / HTTP

8. **Render post-purchase upsell page via SSR**: Checkout API renders the Preact upsell component with available offers.
   - From: `checkoutReloaded_api`
   - To: `Consumer Browser`
   - Protocol: REST / HTTP (HTML response)

### Post-Purchase Redemption

9. **Consumer selects and submits a post-purchase offer**: Consumer browser sends `POST /post-purchase/redeem` with the selected offer.
   - From: `Consumer Browser`
   - To: `checkoutReloaded_api`
   - Protocol: REST / HTTP (form POST or JSON body)

10. **Validate CSRF token**: Checkout API verifies the CSRF token before processing the redemption.
    - From: `checkoutReloaded_api`
    - To: `checkoutReloaded_api` (internal validation)
    - Protocol: Direct (in-process)

11. **Process redemption**: Orchestrator calls Order Service (or relevant downstream service) to process the post-purchase redemption.
    - From: `checkoutReloaded_orchestrator`
    - To: Order Service (via API Proxy)
    - Protocol: REST / HTTP

12. **Return redemption confirmation**: Checkout API renders or redirects to a confirmation state.
    - From: `checkoutReloaded_api`
    - To: `Consumer Browser`
    - Protocol: REST / HTTP (HTML response or redirect)

### Confirmation Email Re-send

13. **Consumer requests confirmation email re-send**: Consumer submits `POST /receipt/resend-email`.
    - From: `Consumer Browser`
    - To: `checkoutReloaded_api`
    - Protocol: REST / HTTP

14. **Validate CSRF and delegate to Order Service**: Checkout API validates CSRF and calls Order Service to re-trigger the confirmation email.
    - From: `checkoutReloaded_orchestrator`
    - To: Order Service (via API Proxy)
    - Protocol: REST / HTTP

15. **Return success/failure state**: Checkout API renders confirmation that the email was queued.
    - From: `checkoutReloaded_api`
    - To: `Consumer Browser`
    - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Order Service unavailable on receipt load | Orchestrator catches error | Receipt page rendered with error state; consumer cannot see order details |
| orderId not found or consumer not owner | Checkout API returns 404 or 403 | Access denied or not found page rendered |
| Post-purchase upsell flag disabled | `checkout.postPurchaseUpsell` flag is off | GET /post-purchase skipped or returns empty offers; consumer proceeds past upsell |
| Redemption POST fails at Order Service | Orchestrator catches error | Redemption error state rendered; consumer can retry |
| CSRF validation fails on any POST | Request rejected by Checkout API | 403 response; consumer prompted to reload and retry |
| Confirmation email re-send fails | Orchestrator catches error | Error message rendered; consumer advised to contact support |

## Sequence Diagram

```
Consumer Browser -> checkoutReloaded_api: GET /receipt/:orderId
checkoutReloaded_api -> checkoutReloaded_orchestrator: Fetch order details
checkoutReloaded_orchestrator -> Order Service: GET order/:orderId (via API Proxy)
Order Service --> checkoutReloaded_orchestrator: Order details
continuumCheckoutReloadedService -> Layout Service: GET header/footer
Layout Service --> continuumCheckoutReloadedService: HTML fragments
checkoutReloaded_api --> Consumer Browser: SSR HTML (receipt page)

Consumer Browser -> checkoutReloaded_api: GET /post-purchase
checkoutReloaded_orchestrator -> Order Service: GET upsell offers (via API Proxy)
Order Service --> checkoutReloaded_orchestrator: Upsell offer list
checkoutReloaded_api --> Consumer Browser: SSR HTML (post-purchase upsell page)

Consumer Browser -> checkoutReloaded_api: POST /post-purchase/redeem (selected offer)
checkoutReloaded_api -> checkoutReloaded_api: Validate CSRF token
checkoutReloaded_orchestrator -> Order Service: POST process redemption (via API Proxy)
Order Service --> checkoutReloaded_orchestrator: Redemption confirmation
checkoutReloaded_api --> Consumer Browser: SSR HTML (redemption confirmation)
```

## Related

- Architecture dynamic view: `dynamic-checkout-reloaded-request-flow`
- Related flows: [Cart to Checkout](cart-to-checkout.md), [Payment Processing](payment-processing.md)

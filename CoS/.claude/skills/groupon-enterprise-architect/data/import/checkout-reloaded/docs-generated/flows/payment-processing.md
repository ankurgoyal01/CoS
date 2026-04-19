---
service: "checkout-reloaded"
title: "Payment Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "payment-processing"
flow_type: synchronous
trigger: "Consumer submits checkout form (POST /checkout/submit)"
participants:
  - "Consumer Browser"
  - "continuumCheckoutReloadedService"
  - "checkoutReloaded_api"
  - "checkoutReloaded_orchestrator"
  - "checkoutReloaded_repository"
  - "continuumCheckoutReloadedDb"
  - "Adyen Payment Gateway"
  - "Order Service"
architecture_ref: "dynamic-checkout-reloaded-request-flow"
---

# Payment Processing

## Summary

When a consumer submits the checkout form, the BFF orchestrates the full payment-to-order sequence: it validates the CSRF token, calls Adyen to authorize the payment, and on success calls the Order Service to finalize the order. A successful completion redirects the consumer to the receipt page; any failure at the payment or order step returns the consumer to the checkout page with a contextual error state.

## Trigger

- **Type**: user-action
- **Source**: Consumer submits the checkout form in the browser, issuing `POST /checkout/submit`
- **Frequency**: per-request (once per checkout attempt; may repeat if consumer retries after failure)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Browser | Submits checkout form with payment details | — |
| Checkout Reloaded Service | BFF entry point; routes submission and coordinates response | `continuumCheckoutReloadedService` |
| Checkout API | Receives POST, validates CSRF token, validates payload | `checkoutReloaded_api` |
| Checkout Orchestrator | Sequences payment authorization and order finalization | `checkoutReloaded_orchestrator` |
| Checkout Repository | Persists and updates checkout session state during submission | `checkoutReloaded_repository` |
| Checkout Reloaded DB | Stores updated session state | `continuumCheckoutReloadedDb` |
| Adyen Payment Gateway | Authorizes the payment transaction | — |
| Order Service | Finalizes the order in the commerce platform after payment | — |

## Steps

1. **Receive checkout submission**: Consumer browser submits `POST /checkout/submit` with form data (payment method token, cart reference, consumer details).
   - From: `Consumer Browser`
   - To: `checkoutReloaded_api`
   - Protocol: REST / HTTP (form POST or JSON body)

2. **Validate CSRF token**: Checkout API verifies the CSRF token from the request against the server-side session. Rejects if invalid.
   - From: `checkoutReloaded_api`
   - To: `checkoutReloaded_api` (internal validation)
   - Protocol: Direct (in-process)

3. **Validate request payload**: Checkout API validates required fields (payment method, cart ID, consumer identity).
   - From: `checkoutReloaded_api`
   - To: `checkoutReloaded_orchestrator`
   - Protocol: Direct (in-process)

4. **Load checkout session**: Orchestrator loads in-progress session state for this checkout.
   - From: `checkoutReloaded_orchestrator`
   - To: `checkoutReloaded_repository`
   - Protocol: Direct (in-process)

5. **Query session from DB**: Repository reads current session record.
   - From: `checkoutReloaded_repository`
   - To: `continuumCheckoutReloadedDb`
   - Protocol: SQL

6. **Authorize payment via Adyen**: Orchestrator calls Adyen API with payment method data to authorize the transaction. Uses `ADYEN_API_KEY` and `ADYEN_MERCHANT_ACCOUNT`. Behavior is controlled by `checkout.adyenDropIn` and `checkout.newPaymentFlow` feature flags.
   - From: `checkoutReloaded_orchestrator`
   - To: Adyen Payment Gateway
   - Protocol: HTTPS (Adyen REST API / SDK)

7. **Handle Adyen authorization result**: On authorization success, Orchestrator proceeds to order finalization. On failure (declined, error), Orchestrator prepares an error state and aborts the flow.
   - From: Adyen Payment Gateway
   - To: `checkoutReloaded_orchestrator`
   - Protocol: HTTPS (response)

8. **Finalize order with Order Service**: Orchestrator calls Order Service to finalize the order, passing the Adyen authorization reference and cart details.
   - From: `checkoutReloaded_orchestrator`
   - To: Order Service (via `API_PROXY_BASE_URL` / `itier-groupon-v2-client`)
   - Protocol: REST / HTTP

9. **Persist finalized session state**: Orchestrator instructs Repository to update the session record with order confirmation details.
   - From: `checkoutReloaded_orchestrator`
   - To: `checkoutReloaded_repository`
   - Protocol: Direct (in-process)

10. **Write updated session to DB**: Repository persists the finalized state.
    - From: `checkoutReloaded_repository`
    - To: `continuumCheckoutReloadedDb`
    - Protocol: SQL

11. **Redirect to receipt page**: Checkout API responds with an HTTP redirect to `GET /receipt/:orderId` on success.
    - From: `checkoutReloaded_api`
    - To: `Consumer Browser`
    - Protocol: REST / HTTP (302 redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CSRF token invalid | Request rejected immediately by Checkout API | 403 response; consumer prompted to reload and retry |
| Adyen payment declined | Orchestrator catches decline result; no order call made | Checkout page re-rendered with payment declined error; consumer can retry with different payment method |
| Adyen API error (5xx) | Orchestrator catches error | Checkout page re-rendered with generic payment error; payment not charged |
| Order Service unavailable after payment auth | Orchestrator catches failure; Adyen authorization may require reversal | Error state rendered; operations team must investigate possible dangling Adyen auth |
| Order Service returns error | Orchestrator catches error | Checkout page re-rendered with order failure error; Adyen authorization may need manual reversal |
| DB write failure on session update | Repository logs error; flow continues | Session state may be stale; order may still succeed; idempotency depends on Order Service |

## Sequence Diagram

```
Consumer Browser -> checkoutReloaded_api: POST /checkout/submit (payment token, cart ref)
checkoutReloaded_api -> checkoutReloaded_api: Validate CSRF token
checkoutReloaded_api -> checkoutReloaded_orchestrator: Dispatch validated checkout request
checkoutReloaded_orchestrator -> checkoutReloaded_repository: Load session
checkoutReloaded_repository -> continuumCheckoutReloadedDb: SELECT session
continuumCheckoutReloadedDb --> checkoutReloaded_repository: Session record
checkoutReloaded_orchestrator -> Adyen Payment Gateway: Authorize payment (ADYEN_API_KEY, ADYEN_MERCHANT_ACCOUNT)
Adyen Payment Gateway --> checkoutReloaded_orchestrator: Authorization result (success/decline)
checkoutReloaded_orchestrator -> Order Service: POST finalize order (auth ref, cart data)
Order Service --> checkoutReloaded_orchestrator: Order confirmation (orderId)
checkoutReloaded_orchestrator -> checkoutReloaded_repository: Update session (order confirmed)
checkoutReloaded_repository -> continuumCheckoutReloadedDb: UPDATE session
checkoutReloaded_orchestrator --> checkoutReloaded_api: Order confirmed (orderId)
checkoutReloaded_api --> Consumer Browser: HTTP 302 redirect -> /receipt/:orderId
```

## Related

- Architecture dynamic view: `dynamic-checkout-reloaded-request-flow`
- Related flows: [Cart to Checkout](cart-to-checkout.md), [Post-Purchase Experience](post-purchase-experience.md)

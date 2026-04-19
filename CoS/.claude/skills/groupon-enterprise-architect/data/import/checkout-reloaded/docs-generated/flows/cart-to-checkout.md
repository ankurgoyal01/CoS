---
service: "checkout-reloaded"
title: "Cart to Checkout"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cart-to-checkout"
flow_type: synchronous
trigger: "Consumer navigates to /checkout from cart or deal page (GET request)"
participants:
  - "Consumer Browser"
  - "continuumCheckoutReloadedService"
  - "checkoutReloaded_api"
  - "checkoutReloaded_orchestrator"
  - "checkoutReloaded_repository"
  - "continuumCheckoutReloadedDb"
  - "Cart Service"
  - "Deal Catalog Service"
  - "Pricing Service"
  - "Layout Service"
architecture_ref: "dynamic-checkout-reloaded-request-flow"
---

# Cart to Checkout

## Summary

When a consumer navigates to the checkout page, the BFF assembles a fully server-side rendered Preact page by orchestrating concurrent data fetches from Cart Service, Deal Catalog Service, and Pricing Service. The rendered HTML — along with serialized Redux initial state for client hydration — is returned to the browser in a single HTTP response. This flow is read-only and produces no mutations.

## Trigger

- **Type**: user-action
- **Source**: Consumer browser issues `GET /checkout` or `GET /checkout/:orderId` from a cart review page or deal page
- **Frequency**: per-request (on demand, once per checkout initiation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Browser | Initiates checkout by navigating to /checkout | — |
| Checkout Reloaded Service | BFF entry point; routes request and assembles SSR response | `continuumCheckoutReloadedService` |
| Checkout API | Receives and validates incoming GET request | `checkoutReloaded_api` |
| Checkout Orchestrator | Coordinates parallel downstream data fetches | `checkoutReloaded_orchestrator` |
| Checkout Repository | Loads any existing checkout session state | `checkoutReloaded_repository` |
| Checkout Reloaded DB | Source of persisted checkout session data | `continuumCheckoutReloadedDb` |
| Cart Service | Provides current cart contents | — |
| Deal Catalog Service | Provides deal and product details for items in cart | — |
| Pricing Service | Validates and returns applicable pricing for cart items | — |
| Layout Service | Provides shared site header and footer HTML | — |

## Steps

1. **Receive checkout page request**: Consumer browser sends `GET /checkout` (or `GET /checkout/:orderId`).
   - From: `Consumer Browser`
   - To: `checkoutReloaded_api`
   - Protocol: REST / HTTP

2. **Validate session and route**: Checkout API validates the session cookie and routes the request to the Checkout Orchestrator.
   - From: `checkoutReloaded_api`
   - To: `checkoutReloaded_orchestrator`
   - Protocol: Direct (in-process)

3. **Load existing checkout session**: Orchestrator instructs Repository to load any in-progress session state for this consumer/order.
   - From: `checkoutReloaded_orchestrator`
   - To: `checkoutReloaded_repository`
   - Protocol: Direct (in-process)

4. **Query checkout session from DB**: Repository reads session record from PostgreSQL.
   - From: `checkoutReloaded_repository`
   - To: `continuumCheckoutReloadedDb`
   - Protocol: SQL

5. **Fetch cart contents**: Orchestrator calls Cart Service to retrieve the consumer's current cart.
   - From: `checkoutReloaded_orchestrator`
   - To: Cart Service (via `API_PROXY_BASE_URL` / `itier-groupon-v2-client`)
   - Protocol: REST / HTTP

6. **Fetch deal details**: Orchestrator calls Deal Catalog Service to retrieve product and deal information for each item in the cart.
   - From: `checkoutReloaded_orchestrator`
   - To: Deal Catalog Service (via API Proxy)
   - Protocol: REST / HTTP

7. **Validate pricing**: Orchestrator calls Pricing Service to obtain validated pricing for cart contents.
   - From: `checkoutReloaded_orchestrator`
   - To: Pricing Service (via API Proxy)
   - Protocol: REST / HTTP

8. **Fetch layout fragments**: BFF requests shared header and footer HTML from Layout Service.
   - From: `continuumCheckoutReloadedService`
   - To: Layout Service
   - Protocol: REST / HTTP

9. **Assemble Redux initial state**: Orchestrator combines cart, deal, pricing, and session data into a Redux state object for client hydration.
   - From: `checkoutReloaded_orchestrator`
   - To: `checkoutReloaded_api` (return)
   - Protocol: Direct (in-process)

10. **Render checkout page via SSR**: Checkout API renders the Preact checkout component tree server-side, injecting the Redux state and layout fragments.
    - From: `checkoutReloaded_api`
    - To: `Consumer Browser`
    - Protocol: REST / HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cart Service unavailable | Upstream call fails; orchestrator catches error | Checkout page rendered with error state; consumer shown a cart load failure message |
| Pricing Service unavailable | Upstream call fails; orchestrator catches error | Checkout page rendered with pricing error state; consumer cannot proceed to payment |
| Deal Catalog Service unavailable | Upstream call fails; orchestrator catches error | Checkout page rendered with incomplete item details; degraded display |
| Layout Service unavailable | Header/footer fragment missing | Page rendered without shared navigation; checkout functionality unaffected |
| DB unavailable (session load fails) | Repository catches DB error | Checkout proceeds without restored session state; fresh session started |

## Sequence Diagram

```
Consumer Browser -> checkoutReloaded_api: GET /checkout
checkoutReloaded_api -> checkoutReloaded_orchestrator: Route request (session validated)
checkoutReloaded_orchestrator -> checkoutReloaded_repository: Load checkout session
checkoutReloaded_repository -> continuumCheckoutReloadedDb: SELECT session WHERE id=...
continuumCheckoutReloadedDb --> checkoutReloaded_repository: Session record (or empty)
checkoutReloaded_orchestrator -> Cart Service: GET cart contents (via API Proxy)
Cart Service --> checkoutReloaded_orchestrator: Cart data
checkoutReloaded_orchestrator -> Deal Catalog Service: GET deal details (via API Proxy)
Deal Catalog Service --> checkoutReloaded_orchestrator: Deal data
checkoutReloaded_orchestrator -> Pricing Service: GET pricing validation (via API Proxy)
Pricing Service --> checkoutReloaded_orchestrator: Validated pricing
continuumCheckoutReloadedService -> Layout Service: GET header/footer fragments
Layout Service --> continuumCheckoutReloadedService: HTML fragments
checkoutReloaded_orchestrator --> checkoutReloaded_api: Assembled Redux state
checkoutReloaded_api --> Consumer Browser: SSR HTML (checkout page + Redux state)
```

## Related

- Architecture dynamic view: `dynamic-checkout-reloaded-request-flow`
- Related flows: [Payment Processing](payment-processing.md), [Post-Purchase Experience](post-purchase-experience.md)

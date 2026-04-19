---
service: "next-pwa-app"
title: "Checkout and Order Flow"
generated: "2026-03-03"
type: flow
flow_name: "checkout-and-order"
flow_type: synchronous
trigger: "User adds item to cart and completes purchase"
participants:
  - "consumer"
  - "mbnxtWebsite"
  - "web_feature_modules"
  - "web_graphql_client"
  - "mbnxtGraphQL"
  - "continuumApiLazloService"
  - "continuumOrdersService"
architecture_ref: "dynamic-consumer-browse-and-checkout"
---

# Checkout and Order Flow

## Summary

The checkout flow begins when a consumer adds a deal to their cart and proceeds through payment and order confirmation. The web client communicates with the MBNXT GraphQL API for cart management operations and order creation. The GraphQL layer delegates to the API Proxy (Lazlo) for pricing and checkout details, and to the Orders Service for order creation. The flow involves multiple mutations (add to cart, update cart, create order) and queries (breakdown, payment methods) before the final order is placed.

## Trigger

- **Type**: user-action
- **Source**: Consumer clicks "Buy" or "Add to Cart" on a deal page, then proceeds through checkout
- **Frequency**: On demand (conversion funnel, critical business path)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer | Initiates purchase actions | `consumer` |
| MBNXT Web | Hosts checkout pages and form interactions | `mbnxtWebsite` |
| Web Feature Modules | Checkout feature module managing cart and order UI | `web_feature_modules` |
| Web GraphQL Client | Executes cart and order GraphQL mutations | `web_graphql_client` |
| MBNXT GraphQL | Resolves cart/order mutations, orchestrates backend calls | `mbnxtGraphQL` |
| API Proxy (Lazlo) | Reads pricing, options, and checkout details | `continuumApiLazloService` |
| Orders Service | Creates and reads orders | `continuumOrdersService` |

## Steps

1. **Add to Cart**: Consumer clicks "Add to Cart" on a deal page
   - From: `consumer`
   - To: `mbnxtWebsite`
   - Protocol: Client-side interaction (Apollo mutation)

2. **Cart Mutation**: Web client sends addToCart GraphQL mutation
   - From: `web_graphql_client`
   - To: `mbnxtGraphQL`
   - Protocol: HTTP POST to `/api/graphql`

3. **Cart Backend Call**: GraphQL resolver delegates cart operation to API Proxy
   - From: `mbnxtGraphQL`
   - To: `continuumApiLazloService`
   - Protocol: REST/HTTPS

4. **Navigate to Checkout**: Consumer navigates to `/checkout/cart`
   - From: `consumer`
   - To: `mbnxtWebsite`
   - Protocol: HTTPS (client-side navigation)

5. **Checkout Data Load**: Checkout page queries for cart contents, breakdown, and payment options
   - From: `web_feature_modules` via `web_graphql_client`
   - To: `mbnxtGraphQL`
   - Protocol: HTTP POST to `/api/graphql`

6. **Pricing and Breakdown**: GraphQL resolver fetches pricing breakdown from API Proxy
   - From: `mbnxtGraphQL`
   - To: `continuumApiLazloService`
   - Protocol: REST/HTTPS

7. **Form Submission**: Consumer fills payment details and submits order
   - From: `consumer`
   - To: `mbnxtWebsite`
   - Protocol: Client-side form submission

8. **Create Order Mutation**: Web client sends createOrder GraphQL mutation
   - From: `web_graphql_client`
   - To: `mbnxtGraphQL`
   - Protocol: HTTP POST to `/api/graphql`

9. **Order Creation**: GraphQL resolver creates the order via the Orders Service
   - From: `mbnxtGraphQL`
   - To: `continuumOrdersService`
   - Protocol: REST/HTTPS

10. **Order Confirmation**: Order confirmation data returned and confirmation page rendered
    - From: `mbnxtGraphQL`
    - To: `web_graphql_client`
    - Protocol: GraphQL response (JSON)

11. **Redirect to Confirmation**: Consumer is redirected to the order confirmation/receipt page
    - From: `mbnxtWebsite`
    - To: `consumer`
    - Protocol: Client-side navigation to `/receipt/:orderId`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cart operation failure | GraphQL error returned with message | Error displayed to consumer with retry option |
| Pricing discrepancy | Breakdown re-fetched on checkout load | Updated pricing shown before order submission |
| Payment failure | Order creation returns error code | Consumer shown payment error with option to retry or use different payment |
| Order creation timeout | Timeout error from Orders Service | Consumer shown generic error; order may have been created (idempotency check needed) |
| Session expired | Auth middleware redirects to login | Consumer redirected to login, returns to checkout after auth |

## Sequence Diagram

```
Consumer -> MBNXT Web: Click "Add to Cart"
MBNXT Web -> MBNXT GraphQL: mutation addToCart
MBNXT GraphQL -> API Proxy (Lazlo): POST cart item
API Proxy (Lazlo) --> MBNXT GraphQL: Cart updated
MBNXT GraphQL --> MBNXT Web: Cart response
Consumer -> MBNXT Web: Navigate to /checkout/cart
MBNXT Web -> MBNXT GraphQL: query cartBreakdown
MBNXT GraphQL -> API Proxy (Lazlo): GET breakdown
API Proxy (Lazlo) --> MBNXT GraphQL: Pricing breakdown
MBNXT GraphQL --> MBNXT Web: Checkout data
Consumer -> MBNXT Web: Submit order (payment details)
MBNXT Web -> MBNXT GraphQL: mutation createOrder
MBNXT GraphQL -> Orders Service: POST create order
Orders Service --> MBNXT GraphQL: Order confirmation
MBNXT GraphQL --> MBNXT Web: Order result
MBNXT Web --> Consumer: Redirect to /receipt/:orderId
```

## Related

- Architecture dynamic view: `dynamic-consumer-browse-and-checkout`
- Related flows: [Consumer Browse and Search](consumer-browse-and-search.md), [Deal Page View](deal-page-view.md)

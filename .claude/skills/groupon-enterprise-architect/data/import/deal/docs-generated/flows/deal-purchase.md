---
service: "deal"
title: "Deal Purchase"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-purchase"
flow_type: synchronous
trigger: "Consumer clicks Buy / Add to Cart on deal page"
participants:
  - "Browser / Mobile App"
  - "dealWebApp"
  - "Groupon V2 Cart API"
architecture_ref: "dynamic-continuum-deal-purchase"
---

# Deal Purchase

## Summary

The deal purchase flow handles the consumer's intent to buy a deal by submitting the selection to the cart. When a consumer clicks the "Buy" or "Add to Cart" button on the deal page, the browser submits an AJAX request to `dealWebApp`, which relays the request to the Groupon V2 Cart API. The service acts as a proxy/orchestrator in this flow — it does not process payments or create orders directly.

## Trigger

- **Type**: user-action
- **Source**: Consumer clicks "Buy" or "Add to Cart" button on the rendered deal page
- **Frequency**: Per consumer purchase intent action (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / Mobile App | Initiates AJAX purchase request; receives cart confirmation | N/A (external consumer) |
| Deal Web App | Receives AJAX request; relays to Groupon V2 Cart API | `dealWebApp` |
| Groupon V2 Cart API | Adds deal option to consumer cart; returns cart state | > No evidence found in codebase. |

## Steps

1. **Receive Purchase Intent**: Consumer's browser sends `POST /deals/api/*` (buy button AJAX call) with selected deal option and quantity to `dealWebApp`.
   - From: `Browser / Mobile App`
   - To: `dealWebApp`
   - Protocol: HTTP POST (AJAX/JSON)

2. **Validate Request**: `dealWebApp` validates the incoming request parameters (deal option, quantity, consumer session).
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process

3. **Add to Cart**: `dealWebApp` calls the Groupon V2 Cart API via `itier-groupon-v2-client` to add the selected deal option to the consumer's cart.
   - From: `dealWebApp`
   - To: `Groupon V2 Cart API`
   - Protocol: REST/HTTP

4. **Return Cart Confirmation**: `dealWebApp` relays the Cart API response to the consumer's browser. On success, the buy button form updates to reflect the item is in cart or redirects to checkout.
   - From: `dealWebApp`
   - To: `Browser / Mobile App`
   - Protocol: HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 Cart API unavailable | Error propagated to consumer browser | Error message displayed on deal page; purchase not completed |
| Invalid deal option / out of stock | Cart API returns error; `dealWebApp` relays error | Consumer shown "unavailable" state on deal page |
| Consumer session expired | Session validation fails | Consumer redirected to login page |

## Sequence Diagram

```
Browser -> dealWebApp: POST /deals/api/* (buy button AJAX, deal option + quantity)
dealWebApp -> dealWebApp: validate request parameters
dealWebApp -> V2CartAPI: POST add deal to cart
V2CartAPI --> dealWebApp: cart confirmation / error
dealWebApp --> Browser: JSON response (success / error)
Browser -> Browser: update buy button UI or redirect to checkout
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-purchase`
- Related flows: [Deal Page Load](deal-page-load.md)

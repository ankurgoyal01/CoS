---
service: "payments"
title: "Payment Authorization"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "payment-authorization"
flow_type: synchronous
trigger: "API call from Orders Service during checkout"
participants:
  - "continuumOrdersService"
  - "continuumPaymentsService"
  - "payments_api"
  - "payments_providerRouter"
  - "payments_providerClient"
  - "payments_repository"
  - "paymentGateways"
architecture_ref: "dynamic-continuum-payments-service"
---

# Payment Authorization

## Summary

The payment authorization flow is triggered when the Orders Service sends a payment authorization request to the Payments Service during checkout. The Payments API receives the request, routes it through the Provider Router to select the appropriate payment gateway, and the Provider Client executes the authorization call against the external PSP. The result is persisted to the Payments DB and returned synchronously to the caller.

## Trigger

- **Type**: api-call
- **Source**: Orders Service (`continuumOrdersService`) during order checkout
- **Frequency**: Per-request (every order checkout)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders Service | Initiator; sends authorization request | `continuumOrdersService` |
| Payments API | Entry point; receives HTTP authorization request | `payments_api` |
| Provider Router | Selects the appropriate payment gateway/provider | `payments_providerRouter` |
| Provider Client | Executes the PSP authorization call | `payments_providerClient` |
| Payment Gateways | External PSP; processes the authorization | `paymentGateways` |
| Payment Repository | Persists the authorization result | `payments_repository` |

## Steps

1. **Orders Service sends authorization request**: The Orders Service sends a POST request to the Payments API to authorize a payment for an order.
   - From: `continuumOrdersService`
   - To: `payments_api`
   - Protocol: REST (JSON/HTTPS)

2. **Payments API routes to Provider Router**: The Payments API validates the request and forwards it to the Provider Router for gateway selection.
   - From: `payments_api`
   - To: `payments_providerRouter`
   - Protocol: direct (internal method call)

3. **Provider Router selects and invokes Provider Client**: The Provider Router determines the appropriate payment gateway and delegates to the Provider Client.
   - From: `payments_providerRouter`
   - To: `payments_providerClient`
   - Protocol: direct (internal method call)

4. **Provider Client calls external gateway**: The Provider Client sends the authorization request to the selected external payment gateway.
   - From: `payments_providerClient`
   - To: `paymentGateways`
   - Protocol: REST / API

5. **Gateway returns authorization result**: The external PSP processes the authorization and returns a result (approved/declined).
   - From: `paymentGateways`
   - To: `payments_providerClient`
   - Protocol: REST / API

6. **Provider Client returns result to Payments API**: The authorization result is passed back up through the component chain.
   - From: `payments_providerClient`
   - To: `payments_api`
   - Protocol: direct (internal)

7. **Payments API persists authorization**: The Payments API writes the authorization result to the Payments DB via the Payment Repository.
   - From: `payments_api`
   - To: `payments_repository`
   - Protocol: direct (JPA / JDBC)

8. **Authorization response returned to Orders Service**: The Payments API returns the authorization result to the calling Orders Service.
   - From: `payments_api`
   - To: `continuumOrdersService`
   - Protocol: REST (JSON/HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PSP authorization declined | Return decline result to Orders Service | Order collection fails; Orders Service may retry via daemon schedulers |
| PSP timeout / network error | > No evidence found in codebase for retry/fallback within Payments Service | Error propagated to Orders Service; retry handled by Orders daemons |
| Invalid payment data | Validation at Payments API layer | 400 error returned to caller |
| Payments DB write failure | > No evidence found in codebase | Authorization may succeed at PSP but fail to persist; requires investigation |

## Sequence Diagram

```
continuumOrdersService -> payments_api: POST /payments (authorize)
payments_api -> payments_providerRouter: Validate and route
payments_providerRouter -> payments_providerClient: Authorize with provider
payments_providerClient -> paymentGateways: PSP authorize
paymentGateways --> payments_providerClient: Authorization result
payments_providerClient --> payments_api: Auth result
payments_api -> payments_repository: Persist authorization
payments_api --> continuumOrdersService: Authorization response
```

## Related

- Architecture dynamic view: `dynamic-continuum-payments-service`
- Related flows: [Payment Capture](payment-capture.md)
- Cross-service flow: `dynamic-continuum-orders-service` (Orders Checkout & Fulfillment)

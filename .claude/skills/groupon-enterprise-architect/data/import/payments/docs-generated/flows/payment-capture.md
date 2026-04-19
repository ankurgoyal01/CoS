---
service: "payments"
title: "Payment Capture"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "payment-capture"
flow_type: synchronous
trigger: "API call from Orders Service after successful authorization"
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

# Payment Capture

## Summary

The payment capture flow is triggered when the Orders Service sends a capture request to the Payments Service for a previously authorized payment. The Payments API receives the request, routes it through the Provider Router to the Provider Client, which executes the capture call against the external PSP. The capture result is persisted to the Payments DB and returned synchronously to the caller. This is the second phase of the two-phase payment processing model (authorize then capture).

## Trigger

- **Type**: api-call
- **Source**: Orders Service (`continuumOrdersService`) after successful authorization and inventory reservation
- **Frequency**: Per-request (every successful order authorization)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders Service | Initiator; sends capture request after authorization | `continuumOrdersService` |
| Payments API | Entry point; receives HTTP capture request | `payments_api` |
| Provider Router | Routes capture to the same provider used for authorization | `payments_providerRouter` |
| Provider Client | Executes the PSP capture call | `payments_providerClient` |
| Payment Gateways | External PSP; processes the capture | `paymentGateways` |
| Payment Repository | Persists the capture result | `payments_repository` |

## Steps

1. **Orders Service sends capture request**: After a successful authorization and inventory reservation, the Orders Service sends a POST request to capture the authorized payment.
   - From: `continuumOrdersService`
   - To: `payments_api`
   - Protocol: REST (JSON/HTTPS)

2. **Payments API routes to Provider Router**: The Payments API validates the capture request (verifying a prior authorization exists) and forwards it to the Provider Router.
   - From: `payments_api`
   - To: `payments_providerRouter`
   - Protocol: direct (internal method call)

3. **Provider Router selects and invokes Provider Client**: The Provider Router identifies the gateway used for the original authorization and delegates to the Provider Client.
   - From: `payments_providerRouter`
   - To: `payments_providerClient`
   - Protocol: direct (internal method call)

4. **Provider Client calls external gateway for capture**: The Provider Client sends the capture request to the external payment gateway.
   - From: `payments_providerClient`
   - To: `paymentGateways`
   - Protocol: REST / API

5. **Gateway returns capture result**: The external PSP processes the capture and returns a result.
   - From: `paymentGateways`
   - To: `payments_providerClient`
   - Protocol: REST / API

6. **Provider Client returns result to Payments API**: The capture result is passed back through the component chain.
   - From: `payments_providerClient`
   - To: `payments_api`
   - Protocol: direct (internal)

7. **Payments API persists capture**: The Payments API writes the capture result to the Payments DB via the Payment Repository.
   - From: `payments_api`
   - To: `payments_repository`
   - Protocol: direct (JPA / JDBC)

8. **Capture response returned to Orders Service**: The Payments API returns the capture result to the calling Orders Service.
   - From: `payments_api`
   - To: `continuumOrdersService`
   - Protocol: REST (JSON/HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PSP capture failed | Return failure result to Orders Service | Orders Service handles failed capture; may retry via daemon schedulers |
| PSP timeout / network error | > No evidence found in codebase for retry/fallback within Payments Service | Error propagated to Orders Service; retry handled by Orders daemons |
| No prior authorization found | Validation at Payments API layer | 400/404 error returned to caller |
| Payments DB write failure | > No evidence found in codebase | Capture may succeed at PSP but fail to persist; requires investigation |

## Sequence Diagram

```
continuumOrdersService -> payments_api: POST /payments/{id}/capture
payments_api -> payments_providerRouter: Route capture
payments_providerRouter -> payments_providerClient: Capture with provider
payments_providerClient -> paymentGateways: PSP capture
paymentGateways --> payments_providerClient: Capture result
payments_providerClient --> payments_api: Capture result
payments_api -> payments_repository: Persist capture
payments_api --> continuumOrdersService: Capture response
```

## Related

- Architecture dynamic view: `dynamic-continuum-payments-service`
- Related flows: [Payment Authorization](payment-authorization.md)
- Cross-service flow: `dynamic-continuum-orders-service` (Orders Checkout & Fulfillment)

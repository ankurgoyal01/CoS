---
service: "killbill-subscription-programs-plugin"
title: "Manual Order Trigger and Refresh"
generated: "2026-03-03"
type: flow
flow_name: "manual-order-trigger"
flow_type: synchronous
trigger: "HTTP POST to /plugins/sp-plugin/orders/v1 or /plugins/sp-plugin/orders/v1/refresh"
participants:
  - "continuumSubscriptionProgramsPlugin"
  - "continuumApiLazloService"
  - "continuumOrdersService"
  - "continuumSubscriptionProgramsPluginDb"
architecture_ref: "dynamic-sp-plugin-order-processing"
---

# Manual Order Trigger and Refresh

## Summary

Operators and internal automation can manually trigger a new order for an existing Kill Bill invoice or refresh the payment state of an existing order. The trigger endpoint re-executes the same order creation logic as the automatic invoice event flow but without waiting for a billing cycle. The refresh endpoint calls the Orders service to pull the latest order/payment state and updates the Kill Bill invoice accordingly. Both operations are idempotent — triggering or refreshing the same invoice repeatedly produces the same result.

## Trigger

- **Type**: api-call (HTTP POST)
- **Source**: Operator tooling, internal automation, or debugging workflows via the Kill Bill plugin HTTP interface
- **Frequency**: On-demand; used for recovery after automatic order creation failures

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Internal Caller | Sends HTTP POST with invoice ID or order/consumer ID | External |
| API Resources (`spApiResources`) | Receives and validates the HTTP request | `continuumSubscriptionProgramsPlugin` |
| Kill Bill Event Handler (`spKillBillEventHandler`) | Re-executes order creation logic | `continuumSubscriptionProgramsPlugin` |
| Orders Gateway (`spOrdersGateway`) | Calls Orders service for refresh | `continuumSubscriptionProgramsPlugin` |
| GAPI Gateway (`spGapiGateway`) | Calls Lazlo GAPI for order creation | `continuumSubscriptionProgramsPlugin` |
| Lazlo GAPI | Creates the commerce order | `continuumApiLazloService` |
| Orders Service | Returns current order/payment status | `continuumOrdersService` |
| Token Repository | Persists new auth token for GAPI call | `continuumSubscriptionProgramsPluginDb` |

## Steps

### Trigger Order (POST /plugins/sp-plugin/orders/v1?invoiceId=)

1. **Receive HTTP Request**: `OrdersResource` receives `POST /plugins/sp-plugin/orders/v1?invoiceId={KB_INVOICE_ID}`.
   - From: Operator
   - To: `spApiResources`
   - Protocol: REST/HTTP

2. **Authenticate Request**: Kill Bill validates `X-Killbill-ApiKey`, `X-Killbill-ApiSecret`, and Basic Auth headers.
   - From: `spApiResources`
   - To: Kill Bill security layer (in-process)
   - Protocol: direct

3. **Delegate to Order Creation Logic**: `OrdersResource` calls `SPListener.createOrderForInvoice(invoiceId, context)` — the same logic as the event-driven flow.
   - From: `spApiResources`
   - To: `spKillBillEventHandler`
   - Protocol: direct (in-process)

4. **Execute Order Creation**: Steps 3–10 of the [Invoice-Driven Order Creation](invoice-order-creation.md) flow execute: lock, validate balance, check MANUAL_PAY tag, build metadata, generate token, call GAPI, write custom field.
   - From: `spKillBillEventHandler`
   - To: `continuumApiLazloService` / `continuumSubscriptionProgramsPluginDb`
   - Protocol: HTTPS/JSON / JDBC

5. **Return HTTP Response**: Returns HTTP 200 on success or appropriate error code on failure.
   - From: `spApiResources`
   - To: Operator
   - Protocol: REST/HTTP

### Refresh Order (POST /plugins/sp-plugin/orders/v1/refresh)

1. **Receive HTTP Request**: `OrdersResource` receives `POST /plugins/sp-plugin/orders/v1/refresh` with body `{"orderId": "...", "consumerId": "..."}` or query param `?invoiceId=`.
   - From: Operator
   - To: `spApiResources`
   - Protocol: REST/HTTP

2. **Locate Invoice**: Resolves the Kill Bill invoice using the provided `invoiceId` (directly) or by looking up the invoice associated with the given `orderId`/`consumerId`.
   - From: `spApiResources`
   - To: Kill Bill Invoice API (in-process)
   - Protocol: direct

3. **Call Orders Service**: `OrdersClient` calls the Orders service to retrieve current payment status for the order.
   - From: `spOrdersGateway`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

4. **Update Invoice State**: Reconciles the invoice with the Orders response — updates payment status, refunds, or chargebacks in Kill Bill.
   - From: `spApiResources`
   - To: Kill Bill Invoice/Payment API (in-process)
   - Protocol: direct

5. **Return HTTP Response**: Returns HTTP 200. The operation is idempotent — calling refresh multiple times for the same invoice is safe.
   - From: `spApiResources`
   - To: Operator
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invoice not found | Returns HTTP error from Kill Bill API | Operator must verify invoice ID |
| GAPI order creation fails | Writes `ORDER_FAILED` custom field on invoice | Operator must re-trigger after investigating root cause |
| Orders service unavailable (refresh) | HTTP error returned | Operator must retry after Orders service recovers |
| Lock contention (concurrent trigger) | `NotificationPluginApiRetryException` thrown | Kill Bill schedules retry via notification queue |

## Sequence Diagram

```
Operator -> spApiResources: POST /plugins/sp-plugin/orders/v1?invoiceId=<id>
spApiResources -> KillBillSecurity: validate ApiKey/ApiSecret/BasicAuth
spApiResources -> SPListener: createOrderForInvoice(invoiceId, context)
SPListener -> MySqlGlobalLocker: acquire lock
SPListener -> KillBillInvoiceAPI: getInvoice(invoiceId)
SPListener -> KillBillCreateOrderLogic: buildOrderItemForInvoice(invoice)
SPListener -> TokenManager: generateNewToken(userId, subscriptionId)
SPListener -> GAPIClient: POST /v2/users/{userId}/multi_item_orders
GAPIClient -> continuumApiLazloService: createOrder request
continuumApiLazloService --> GAPIClient: OrderResponse
GAPIClient --> SPListener: List<OrderResponse>
SPListener -> KillBillCustomFieldAPI: write ORDER_ID or ORDER_FAILED
SPListener -> MySqlGlobalLocker: release lock
spApiResources --> Operator: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-sp-plugin-order-processing`
- Related flows: [Invoice-Driven Order Creation](invoice-order-creation.md), [Ledger Event Payment Reconciliation](ledger-event-reconciliation.md)

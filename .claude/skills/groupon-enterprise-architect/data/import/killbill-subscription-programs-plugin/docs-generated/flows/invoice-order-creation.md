---
service: "killbill-subscription-programs-plugin"
title: "Invoice-Driven Order Creation"
generated: "2026-03-03"
type: flow
flow_name: "invoice-order-creation"
flow_type: event-driven
trigger: "Kill Bill INVOICE_CREATION internal event"
participants:
  - "continuumSubscriptionProgramsPlugin"
  - "continuumSubscriptionProgramsPluginDb"
  - "continuumApiLazloService"
architecture_ref: "dynamic-sp-plugin-order-processing"
---

# Invoice-Driven Order Creation

## Summary

When Kill Bill generates an invoice for a subscription, it publishes an `INVOICE_CREATION` event to the OSGI event dispatcher. The plugin receives this event, validates that the account is eligible (non-zero balance, `MANUAL_PAY` tag present, tenant listener enabled), generates a short-lived auth token, and calls the Lazlo GAPI `multi_item_orders` endpoint to create a Groupon commerce order. The result (order ID or error details) is recorded as a custom field on the Kill Bill invoice.

## Trigger

- **Type**: event (Kill Bill internal OSGI event bus)
- **Source**: Kill Bill billing engine generates `INVOICE_CREATION` event on each billing cycle
- **Frequency**: Per invoice — once per subscription billing period (monthly for most programs)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kill Bill Billing Engine | Generates `INVOICE_CREATION` event and delivers it in-process | Kill Bill platform (in-process) |
| Kill Bill Event Handler (`spKillBillEventHandler`) | Receives event, validates eligibility, orchestrates order creation | `continuumSubscriptionProgramsPlugin` |
| Token Manager (`spTokenManager`) | Generates short-lived auth token for the GAPI call | `continuumSubscriptionProgramsPlugin` |
| Token Repository (`spTokenRepository`) | Persists the generated token | `continuumSubscriptionProgramsPluginDb` |
| GAPI Gateway (`spGapiGateway`) | Sends order creation request to Lazlo | `continuumSubscriptionProgramsPlugin` |
| Lazlo GAPI | Creates the Groupon commerce order | `continuumApiLazloService` |

## Steps

1. **Receive Invoice Event**: Kill Bill delivers `INVOICE_CREATION` event to `SPListener.handleKillbillEvent()`.
   - From: Kill Bill OSGI event dispatcher
   - To: `SPListener` (in-process)
   - Protocol: In-process Java method call

2. **Check Tenant Listener Enabled**: Plugin reads `isListenerEnabled` from per-tenant configuration. If disabled, the event is ignored and processing stops.
   - From: `SPListener`
   - To: `SPConfigurationHandler`
   - Protocol: direct

3. **Acquire Per-Account Lock**: Plugin acquires a `GlobalLock` (MySQL-backed) keyed on `accountId` to prevent concurrent order creation for the same account.
   - From: `SPListener`
   - To: `continuumSubscriptionProgramsPluginDb`
   - Protocol: JDBC/MySQL

4. **Validate Invoice Balance**: Retrieves the invoice via Kill Bill API. If the balance is `$0`, the event is skipped (idempotency guard).
   - From: `SPListener`
   - To: Kill Bill Invoice API (in-process)
   - Protocol: direct

5. **Check MANUAL_PAY Tag**: Retrieves account tags via Kill Bill API. If the account does not have the `MANUAL_PAY` control tag, the event is skipped (migration gate).
   - From: `SPListener`
   - To: Kill Bill Tag API (in-process)
   - Protocol: direct

6. **Build Order Metadata**: `KillBillCreateOrderLogic` reads subscription custom fields (`DEAL_ID`, `OPTION_ID`, `BILLING_RECORD_ID`, `QUANTITY`) from Kill Bill to build the order item.
   - From: `SPListener`
   - To: Kill Bill CustomField and Subscription APIs (in-process)
   - Protocol: direct

7. **Generate Auth Token**: `TokenManager` generates a short-lived token for the user/subscription and persists it in `sp_token`.
   - From: `SPListener`
   - To: `spTokenManager` / `continuumSubscriptionProgramsPluginDb`
   - Protocol: direct / JDBC

8. **Call GAPI to Create Order**: `GAPIClient` posts to `POST /v2/users/{userId}/multi_item_orders?client_id={clientId}` with `X-SP-Auth-Token` header and the order payload.
   - From: `spGapiGateway`
   - To: `continuumApiLazloService`
   - Protocol: HTTPS/JSON

9. **Map Order Result to Invoice**: On success, writes `ORDER_ID` custom field to the Kill Bill invoice. On failure, writes `ORDER_FAILED` with error details.
   - From: `KillBillCreateOrderLogic`
   - To: Kill Bill CustomField API (in-process)
   - Protocol: direct

10. **Release Lock**: Releases the `GlobalLock` in the `finally` block.
    - From: `SPListener`
    - To: `continuumSubscriptionProgramsPluginDb`
    - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Tenant listener disabled | Event ignored immediately | No order created; no error logged |
| Invoice balance is $0 | Event skipped | No order created; logged as info |
| Account missing MANUAL_PAY tag | Event skipped | No order created; logged as info |
| No order metadata found (no custom fields) | Event skipped | No order created; logged as info |
| Lock acquisition fails | Throws `NotificationPluginApiRetryException` | Kill Bill schedules retry via `sp_notifications` queue |
| GAPI returns non-success HTTP | Writes `ORDER_FAILED` custom field | Manual re-trigger required via `POST /plugins/sp-plugin/orders/v1` |
| GAPI times out or throws I/O exception | Returns empty `OrderResponse`; logged as warn | `ORDER_FAILED` written; manual retry required |
| General exception with non-null accountId | Throws `NotificationPluginApiRetryException` | Kill Bill schedules retry via `sp_notifications` |

## Sequence Diagram

```
KillBill -> SPListener: INVOICE_CREATION event (invoiceId, accountId, tenantId)
SPListener -> SPConfigurationHandler: check isListenerEnabled for tenant
SPListener -> MySqlGlobalLocker: acquire lock for accountId
SPListener -> KillBillInvoiceAPI: getInvoice(invoiceId)
SPListener -> KillBillTagAPI: getTagsForAccountType(accountId)
SPListener -> KillBillCreateOrderLogic: buildOrderItemForInvoice(invoice)
SPListener -> TokenManager: generateNewToken(userId, subscriptionId)
TokenManager -> continuumSubscriptionProgramsPluginDb: insert sp_token record
SPListener -> GAPIClient: createOrder(userId, token, xRequestId, [orderMetadata])
GAPIClient -> continuumApiLazloService: POST /v2/users/{userId}/multi_item_orders
continuumApiLazloService --> GAPIClient: OrderResponse (orderId or error)
GAPIClient --> SPListener: List<OrderResponse>
SPListener -> KillBillCustomFieldAPI: write ORDER_ID or ORDER_FAILED custom field
SPListener -> MySqlGlobalLocker: release lock
```

## Related

- Architecture dynamic view: `dynamic-sp-plugin-order-processing`
- Related flows: [Ledger Event Payment Reconciliation](ledger-event-reconciliation.md), [Manual Order Trigger and Refresh](manual-order-trigger.md)

---
service: "getaways-payment-reconciliation"
title: "Invoice Reconciliation and Payment"
generated: "2026-03-03"
type: flow
flow_name: "invoice-reconciliation-and-payment"
flow_type: synchronous
trigger: "Internal user POST /products/{product}/invoices"
participants:
  - "webResources"
  - "invoicePaymentsService"
  - "getawaysPaymentReconciliation_accountingServiceClient"
  - "jdbiDaos"
  - "continuumGetawaysPaymentReconciliationDb"
architecture_ref: "components-getaways-payment-reconciliation-components"
---

# Invoice Reconciliation and Payment

## Summary

This synchronous flow is triggered when a finance operations user submits a payment for a reconciled EAN invoice via the REST API. The Web Resources layer receives the POST request, delegates total validation to the Invoice Payments Service (which reads reservation data from MySQL), and if validation passes, calls the Accounting Service Client to create a vendor invoice in the finance system. The resulting payment record is written back to MySQL and the response returned to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal user or internal tooling — `POST /products/{product}/invoices`
- **Frequency**: On-demand, driven by finance operations workflow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web Resources | Receives and routes the HTTP request | `webResources` |
| Invoice Payments Service | Validates invoice total against reservation data | `invoicePaymentsService` |
| Accounting Service Client | Creates vendor invoice via Accounting Service HTTP API | `getawaysPaymentReconciliation_accountingServiceClient` |
| JDBI DAOs | Reads reservation/invoice data; writes payment record | `jdbiDaos` |
| Getaways Payment Reconciliation DB | Persistent store | `continuumGetawaysPaymentReconciliationDb` |

## Steps

1. **Receive payment request**: `webResources` (JAX-RS resource) receives `POST /products/{product}/invoices` with a `PostPaymentRequest` body containing `merchantInvoiceId`, `total`, `currency`, `invoiceDate`, `provider`, `parentPaymentGroup`, `disputedReservationIds`, and `memo`.
   - From: Internal user / tooling
   - To: `webResources`
   - Protocol: HTTP POST

2. **Read invoice and reservation data**: `invoicePaymentsService` calls `jdbiDaos` to fetch the merchant invoice and associated reservation records for the specified product, provider, and payment group.
   - From: `invoicePaymentsService`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

3. **Validate invoice total**: `invoicePaymentsService` computes the expected total from reservation data (excluding any disputed reservation IDs) and compares it against `PostPaymentRequest.total`.
   - From: `invoicePaymentsService`
   - To: `invoicePaymentsService` (internal)
   - Protocol: direct

4. **Create vendor invoice (Accounting Service)**: `webResources` calls `getawaysPaymentReconciliation_accountingServiceClient.callAccountingServiceApi(...)` with the invoice number, date, total, memo, and currency. The client maps the currency to the correct vendor ID (`vendorExpediaUSD`, `vendorExpediaEUR`, `vendorExpediaGBP`), sets the due date to the following Monday (+1 week), and POSTs to the Accounting Service with the `as_api_token` header.
   - From: `getawaysPaymentReconciliation_accountingServiceClient`
   - To: Accounting Service API (`accountingServiceApi_unk_3a9f`)
   - Protocol: HTTP POST

5. **Write payment record**: On successful Accounting Service response, `webResources` calls `jdbiDaos` to update the merchant invoice record with the payment UUID and status.
   - From: `webResources`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

6. **Return response**: `webResources` returns a `PostPaymentResponse` (with a message field) to the caller.
   - From: `webResources`
   - To: Internal user / tooling
   - Protocol: HTTP 200

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (total mismatch) | `invoicePaymentsService` returns error; `webResources` returns error response | Invoice not paid; no Accounting Service call made |
| Accounting Service returns HTTP >= 300 | `AccountingServiceClient` throws `RuntimeException` | Payment not recorded; HTTP error returned to caller |
| `isAccountingServiceEnabled=false` | Accounting Service call skipped (feature flag) | Invoice validated but not submitted to Accounting Service |
| Unsupported currency | `IllegalArgumentException` thrown in client | HTTP error returned |
| DB read/write failure | JDBI exception propagates | HTTP 500 returned |

## Sequence Diagram

```
User -> webResources: POST /products/{product}/invoices (PostPaymentRequest)
webResources -> invoicePaymentsService: validate totals
invoicePaymentsService -> jdbiDaos: read invoice + reservations
jdbiDaos -> MySQL: SELECT merchant_invoice + reservations
MySQL --> jdbiDaos: invoice data, reservation data
jdbiDaos --> invoicePaymentsService: invoice + reservations
invoicePaymentsService --> webResources: validation result
webResources -> accountingServiceClient: callAccountingServiceApi(invoiceNumber, date, total, memo, currency)
accountingServiceClient -> AccountingServiceAPI: POST /invoices/{vendorId} (as_api_token header)
AccountingServiceAPI --> accountingServiceClient: APIResponse
accountingServiceClient --> webResources: response body
webResources -> jdbiDaos: write payment record
jdbiDaos -> MySQL: UPDATE merchant_invoice (paymentUuid, statusId)
MySQL --> jdbiDaos: OK
webResources --> User: PostPaymentResponse { message }
```

## Related

- Architecture dynamic view: `components-getaways-payment-reconciliation-components`
- Related flows: [Invoice Listing](invoice-listing.md), [Scheduled Reconciliation Worker](scheduled-reconciliation-worker.md)

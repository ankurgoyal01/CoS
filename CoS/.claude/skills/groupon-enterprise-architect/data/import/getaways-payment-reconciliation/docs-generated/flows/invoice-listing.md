---
service: "getaways-payment-reconciliation"
title: "Invoice Listing"
generated: "2026-03-03"
type: flow
flow_name: "invoice-listing"
flow_type: synchronous
trigger: "Internal user GET /products/{product}/invoices"
participants:
  - "webResources"
  - "jdbiDaos"
  - "continuumGetawaysPaymentReconciliationDb"
architecture_ref: "components-getaways-payment-reconciliation-components"
---

# Invoice Listing

## Summary

This synchronous read-only flow serves the primary data retrieval need of the finance web UI and any internal API consumers. When a user requests a list of invoices for a given product, the Web Resources JAX-RS handler queries MySQL via JDBI DAOs using the supplied filter parameters and returns an array of `MerchantInvoice` objects as JSON.

## Trigger

- **Type**: api-call
- **Source**: Internal user (web UI) or internal tooling — `GET /products/{product}/invoices`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web Resources | Receives and routes the HTTP GET request | `webResources` |
| JDBI DAOs | Executes the parameterised invoice query | `jdbiDaos` |
| Getaways Payment Reconciliation DB | Returns matching invoice records | `continuumGetawaysPaymentReconciliationDb` |

## Steps

1. **Receive list request**: `webResources` receives `GET /products/{product}/invoices` with optional query parameters: `provider` (string), `parentPaymentGroup` (integer), `type` (string).
   - From: Internal user / tooling
   - To: `webResources`
   - Protocol: HTTP GET

2. **Query invoices**: `webResources` calls `jdbiDaos` with the resolved filter parameters to retrieve matching `MerchantInvoice` records.
   - From: `webResources`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

3. **Return invoice list**: `webResources` serialises the result array to JSON and returns HTTP 200 with the invoice list.
   - From: `webResources`
   - To: Internal user / tooling
   - Protocol: HTTP 200 (application/json)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB query failure | JDBI exception propagates to JAX-RS error handler | HTTP 500 returned |
| No invoices found | Returns empty JSON array | HTTP 200 with `[]` |
| Invalid path/query parameters | JAX-RS validation | HTTP 400 |

## Sequence Diagram

```
User -> webResources: GET /products/{product}/invoices?provider=X&parentPaymentGroup=Y&type=Z
webResources -> jdbiDaos: getInvoices(product, provider, parentPaymentGroup, type)
jdbiDaos -> MySQL: SELECT * FROM merchant_invoice WHERE product=... AND ...
MySQL --> jdbiDaos: [MerchantInvoice rows]
jdbiDaos --> webResources: List<MerchantInvoice>
webResources --> User: HTTP 200 [{ merchantInvoiceId, merchantInvoiceNumber, invoiceDate, totalAmount, ... }]
```

## Related

- Architecture dynamic view: `components-getaways-payment-reconciliation-components`
- Related flows: [Invoice Reconciliation and Payment](invoice-reconciliation-and-payment.md)

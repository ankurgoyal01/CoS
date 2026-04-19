---
service: "general-ledger-gateway"
title: "Invoice Lookup"
generated: "2026-03-03"
type: flow
flow_name: "invoice-lookup"
flow_type: synchronous
trigger: "GET /v1/invoices/{invoiceUUID} HTTP call"
participants:
  - "accountingServiceExternalContainerUnknown_6d4b"
  - "continuumGeneralLedgerGatewayApi"
  - "continuumGeneralLedgerGatewayPostgres"
architecture_ref: "components-GeneralLedgerGatewayApiComponents"
---

# Invoice Lookup

## Summary

This flow handles synchronous lookup of a stored invoice record by UUID. A caller (Accounting Service) issues a `GET /v1/invoices/{invoiceUUID}` request; GLG queries its local PostgreSQL database for the matching record and returns the invoice details including `dueDate`, `setOfBooks`, and `vendorUUID`. No outbound NetSuite call is made — this is a pure local data retrieval.

## Trigger

- **Type**: api-call
- **Source**: Accounting Service (or any authorised internal caller)
- **Frequency**: Per request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Accounting Service | Initiates lookup by invoice UUID | `accountingServiceExternalContainerUnknown_6d4b` |
| Invoice Resource | Receives HTTP request and delegates to Data Access | `continuumGeneralLedgerGatewayApi` |
| Data Access | Queries PostgreSQL for invoice record by UUID | `continuumGeneralLedgerGatewayApi` |
| General Ledger Gateway DB | Source of invoice records | `continuumGeneralLedgerGatewayPostgres` |

## Steps

1. **Receives invoice lookup request**: Caller issues `GET /v1/invoices/{invoiceUUID}` with a valid UUID.
   - From: Accounting Service
   - To: `invoiceResource` (Invoice Resource)
   - Protocol: REST (HTTPS)

2. **Queries database for invoice**: Invoice Resource delegates to the Data Access layer, which issues a SELECT query against the `invoices` table via the read-only connection pool.
   - From: `invoiceResource`
   - To: `generalLedgerGateway_dataAccess` → `continuumGeneralLedgerGatewayPostgres`
   - Protocol: JDBC (read-only pool)

3. **Returns invoice response**: If found, Data Access maps the row to `InvoiceShowResponse` (containing `uuid`, `vendorUUID`, `dueDate`, `setOfBooks`). Invoice Resource serialises it to JSON and returns HTTP 200.
   - From: `invoiceResource`
   - To: Accounting Service
   - Protocol: REST (HTTPS)

4. **Returns 404 if not found**: If no record matches the UUID, Invoice Resource returns HTTP 404 with `{ "error": "..." }`.
   - From: `invoiceResource`
   - To: Accounting Service
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invoice UUID not found in DB | 404 with APIError response | HTTP 404 `{ "error": "..." }` returned to caller |
| Invalid UUID format | JAX-RS validation | HTTP 400 returned |
| PostgreSQL read failure | JDBI exception | HTTP 500 returned |

## Sequence Diagram

```
AccountingService -> InvoiceResource: GET /v1/invoices/{invoiceUUID}
InvoiceResource -> DataAccess: findByUUID(invoiceUUID)
DataAccess -> PostgreSQL: SELECT * FROM invoices WHERE uuid = ?
PostgreSQL --> DataAccess: invoice row (or empty)
DataAccess --> InvoiceResource: InvoiceShowResponse (or empty)
InvoiceResource --> AccountingService: 200 InvoiceShowResponse / 404 APIError
```

## Related

- Architecture dynamic view: `components-GeneralLedgerGatewayApiComponents`
- Related flows: [Ledger Entry Lookup](ledger-entry-lookup.md), [Send Invoice to NetSuite](send-invoice-to-netsuite.md)

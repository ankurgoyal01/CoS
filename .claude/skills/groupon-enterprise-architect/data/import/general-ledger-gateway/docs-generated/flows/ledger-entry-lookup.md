---
service: "general-ledger-gateway"
title: "Ledger Entry Lookup"
generated: "2026-03-03"
type: flow
flow_name: "ledger-entry-lookup"
flow_type: synchronous
trigger: "GET /v1/ledger-entries/{invoiceUUID} or GET /v1/ledger-entries/{ledger}/{ledgerID} HTTP call"
participants:
  - "accountingServiceExternalContainerUnknown_6d4b"
  - "continuumGeneralLedgerGatewayApi"
  - "continuumGeneralLedgerGatewayPostgres"
architecture_ref: "components-GeneralLedgerGatewayApiComponents"
---

# Ledger Entry Lookup

## Summary

This flow retrieves the payment status of an invoice as recorded in the GLG ledger entry map. Callers can query by internal invoice UUID or by a ledger-specific identifier (NetSuite ledger ID + ledger type). GLG returns the `ledgerStatus` (`PAID`, `UNPAID`, or `VOIDED`) along with the associated `invoiceUUID`. No outbound calls to NetSuite are made; this is a local database read against the `ledger_entry_maps` table.

## Trigger

- **Type**: api-call
- **Source**: Accounting Service (or any authorised internal caller)
- **Frequency**: Per request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Accounting Service | Initiates status lookup by invoice UUID or ledger ID | `accountingServiceExternalContainerUnknown_6d4b` |
| Ledger Entry Map Resource | Receives HTTP request and routes to Data Access | `continuumGeneralLedgerGatewayApi` |
| Data Access | Queries PostgreSQL `ledger_entry_maps` table | `continuumGeneralLedgerGatewayApi` |
| General Ledger Gateway DB | Source of ledger entry mapping records | `continuumGeneralLedgerGatewayPostgres` |

## Steps

1. **Receives ledger entry lookup request**: Caller issues one of:
   - `GET /v1/ledger-entries/{invoiceUUID}` — lookup by internal invoice UUID
   - `GET /v1/ledger-entries/{ledger}/{ledgerID}` — lookup by NetSuite ledger type and ledger-specific ID
   - From: Accounting Service
   - To: `ledgerEntryMapResource`
   - Protocol: REST (HTTPS)

2. **Queries ledger entry map**: Ledger Entry Map Resource delegates to Data Access, which queries the `ledger_entry_maps` table via the read-only connection pool using the appropriate key.
   - From: `ledgerEntryMapResource`
   - To: `generalLedgerGateway_dataAccess` → `continuumGeneralLedgerGatewayPostgres`
   - Protocol: JDBC (read-only pool)

3. **Returns ledger entry response**: If found, Data Access maps the result to `LedgerEntryShowResponse` containing `invoiceUUID` and `ledgerStatus` (PAID/UNPAID/VOIDED). Ledger Entry Map Resource returns HTTP 200.
   - From: `ledgerEntryMapResource`
   - To: Accounting Service
   - Protocol: REST (HTTPS)

4. **Returns 404 if not found**: If no mapping record exists, Ledger Entry Map Resource returns HTTP 404 with `{ "error": "..." }`.
   - From: `ledgerEntryMapResource`
   - To: Accounting Service
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ledger entry not found | 404 with APIError response | HTTP 404 `{ "error": "..." }` returned |
| Invalid `{ledger}` enum value | JAX-RS validation | HTTP 400 returned |
| PostgreSQL read failure | JDBI exception | HTTP 500 returned |

## Sequence Diagram

```
AccountingService -> LedgerEntryMapResource: GET /v1/ledger-entries/{invoiceUUID}
LedgerEntryMapResource -> DataAccess: findByInvoiceUUID(invoiceUUID)
DataAccess -> PostgreSQL: SELECT * FROM ledger_entry_maps WHERE invoice_uuid = ?
PostgreSQL --> DataAccess: ledger entry row (or empty)
DataAccess --> LedgerEntryMapResource: LedgerEntryShowResponse (or empty)
LedgerEntryMapResource --> AccountingService: 200 LedgerEntryShowResponse / 404 APIError
```

## Related

- Architecture dynamic view: `components-GeneralLedgerGatewayApiComponents`
- Related flows: [Invoice Lookup](invoice-lookup.md), [Import Applied Invoices Job](import-applied-invoices.md)

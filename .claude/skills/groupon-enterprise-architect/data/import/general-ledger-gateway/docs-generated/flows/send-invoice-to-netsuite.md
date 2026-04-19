---
service: "general-ledger-gateway"
title: "Send Invoice to NetSuite"
generated: "2026-03-03"
type: flow
flow_name: "send-invoice-to-netsuite"
flow_type: synchronous
trigger: "PUT /v1/invoices/{ledger}/send HTTP call from Accounting Service"
participants:
  - "accountingServiceExternalContainerUnknown_6d4b"
  - "continuumGeneralLedgerGatewayApi"
  - "continuumGeneralLedgerGatewayPostgres"
  - "netSuiteErpExternalContainerUnknown_1a2c"
architecture_ref: "components-GeneralLedgerGatewayApiComponents"
---

# Send Invoice to NetSuite

## Summary

This flow handles the outbound invoice creation path from Accounting Service to NetSuite. When Accounting Service needs to record a merchant liability in NetSuite, it sends a `PUT /v1/invoices/{ledger}/send` request to GLG with the full invoice payload. GLG selects the correct NetSuite instance, signs the request with OAuth 1.0 credentials, creates or updates a vendor bill in NetSuite, and persists the result in its local PostgreSQL database.

## Trigger

- **Type**: api-call
- **Source**: Accounting Service
- **Frequency**: Per request (on-demand, driven by Accounting Service business logic)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Accounting Service | Initiates invoice send; primary upstream caller | `accountingServiceExternalContainerUnknown_6d4b` |
| Invoice Resource | Receives the HTTP request and delegates to Invoice Service | `continuumGeneralLedgerGatewayApi` |
| Invoice Service | Selects ledger and coordinates NetSuite call | `continuumGeneralLedgerGatewayApi` |
| NetSuite Client Manager | Selects the correct NetSuite client for the requested ledger | `continuumGeneralLedgerGatewayApi` |
| NetSuite Client | Signs request with OAuth 1.0 and issues PUT to NetSuite RESTlet | `continuumGeneralLedgerGatewayApi` |
| NetSuite ERP | Receives vendor bill create/update; returns result | `netSuiteErpExternalContainerUnknown_1a2c` |
| Data Access | Persists the invoice record to PostgreSQL | `continuumGeneralLedgerGatewayApi` |
| General Ledger Gateway DB | Stores invoice record | `continuumGeneralLedgerGatewayPostgres` |

## Steps

1. **Receives invoice send request**: Accounting Service issues `PUT /v1/invoices/{ledger}/send` with `LedgerInvoice` JSON body.
   - From: Accounting Service
   - To: `invoiceResource` (Invoice Resource)
   - Protocol: REST (HTTPS)

2. **Delegates to Invoice Service**: Invoice Resource validates the `{ledger}` path parameter and passes the `LedgerInvoice` model to Invoice Service.
   - From: `invoiceResource`
   - To: `invoiceService`
   - Protocol: Direct (in-process)

3. **Selects NetSuite client**: Invoice Service requests the appropriate NetSuite client from NetSuite Client Manager based on the ledger type (`GOODS_NETSUITE`, `NETSUITE`, or `NORTH_AMERICA_LOCAL_NETSUITE`).
   - From: `invoiceService`
   - To: `netSuiteClientManager`
   - Protocol: Direct (in-process)

4. **Creates/updates vendor bill in NetSuite**: NetSuite Client serialises the `LedgerInvoice` to JSON, signs the request with OAuth 1.0 credentials via ScribeJava, and issues a `PUT` to the NetSuite RESTlet endpoint. Resilience4j retry wraps this call.
   - From: `netSuiteClientManager` / `NetSuiteClient`
   - To: NetSuite ERP (e.g., `4004600.restlets.api.netsuite.com`)
   - Protocol: HTTPS (OAuth 1.0)

5. **Persists invoice record**: Data Access DAO writes the invoice record to the `invoices` table in PostgreSQL via the read/write connection pool.
   - From: `invoiceService`
   - To: `generalLedgerGateway_dataAccess` → `continuumGeneralLedgerGatewayPostgres`
   - Protocol: JDBC

6. **Returns response to caller**: Invoice Resource returns the HTTP response (success or error) to Accounting Service.
   - From: `invoiceResource`
   - To: Accounting Service
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| NetSuite API failure (transient) | Resilience4j retry policy | Retried automatically; error returned to caller after max retries |
| Invalid `{ledger}` value | JAX-RS validation | HTTP 400 returned to caller |
| NetSuite OAuth credential invalid | Request failure returned by ScribeJava | Error response propagated to Accounting Service |
| PostgreSQL write failure | JDBI exception | HTTP 500 returned; NetSuite may have already been written |

## Sequence Diagram

```
AccountingService -> InvoiceResource: PUT /v1/invoices/{ledger}/send {LedgerInvoice}
InvoiceResource -> InvoiceService: send(ledger, ledgerInvoice)
InvoiceService -> NetSuiteClientManager: getClient(ledger)
NetSuiteClientManager --> InvoiceService: NetSuiteClient
InvoiceService -> NetSuiteClient: createInvoice(ledgerInvoice)
NetSuiteClient -> NetSuiteERP: PUT RESTlet (OAuth 1.0, JSON body)
NetSuiteERP --> NetSuiteClient: HTTP response
NetSuiteClient --> InvoiceService: ClientResponse
InvoiceService -> DataAccess: persist(invoice)
DataAccess -> PostgreSQL: INSERT invoices
PostgreSQL --> DataAccess: OK
InvoiceService --> InvoiceResource: result
InvoiceResource --> AccountingService: HTTP response
```

## Related

- Architecture dynamic view: `components-GeneralLedgerGatewayApiComponents`
- Related flows: [Invoice Lookup](invoice-lookup.md), [Import Applied Invoices Job](import-applied-invoices.md)

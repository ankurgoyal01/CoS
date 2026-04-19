---
service: "reporting-service"
title: "VAT Invoicing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "vat-invoicing"
flow_type: event-driven
trigger: "MBus VatInvoicing event and POST /vat/v1/invoices"
participants:
  - "reportingService_apiControllers"
  - "reportingService_mbusConsumers"
  - "reportGenerationService"
  - "reportingService_persistenceDaos"
  - "reportingService_externalApiClients"
  - "reportingService_s3Client"
  - "continuumVatDb"
  - "continuumEuVoucherDb"
  - "continuumFilesDb"
  - "reportingS3Bucket"
  - "mbus"
  - "fedVatApi"
architecture_ref: "Reporting-API-Components"
---

# VAT Invoicing

## Summary

The VAT invoicing flow handles the creation and retrieval of VAT invoices for merchants through two entry points: consuming `VatInvoicing` events from MBus (event-driven) and accepting `POST /vat/v1/invoices` API calls (synchronous). Both paths persist invoice data to the VAT Database, optionally generate a PDF invoice using Flying Saucer + FreeMarker, store the artifact in S3, and record file metadata. Existing invoices are retrievable via `GET /vat/v1/invoices`. EU voucher data is consulted for EU-specific tax calculation.

## Trigger

- **Type**: event and api-call
- **Source**: MBus `VatInvoicing` event from the FED/financial events domain, or direct API call `POST /vat/v1/invoices`
- **Frequency**: Per VAT event or API call; typically periodic (billing cycles)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Handles `POST /vat/v1/invoices` and `GET /vat/v1/invoices` HTTP requests | `reportingService_apiControllers` |
| MBus Consumers | Receives and processes `VatInvoicing` MBus events | `reportingService_mbusConsumers` |
| Report Generation | Renders VAT invoice PDFs using FreeMarker/Flying Saucer | `reportGenerationService` |
| Persistence Layer | Reads and writes VAT invoice and EU voucher data | `reportingService_persistenceDaos` |
| External API Clients | Fetches VAT-specific financial data from FED VAT API | `reportingService_externalApiClients` |
| S3 Client | Stores rendered VAT invoice PDF artifacts | `reportingService_s3Client` |
| VAT Database | Stores VAT invoice records | `continuumVatDb` |
| EU Voucher Database | Provides EU voucher data for tax calculations | `continuumEuVoucherDb` |
| Files Database | Stores S3 file metadata for invoice PDFs | `continuumFilesDb` |
| Report S3 Bucket | Persists rendered VAT invoice PDFs | `reportingS3Bucket` |
| MBus | Delivers VatInvoicing events | `mbus` |
| FED VAT API | Source of VAT-specific financial event data | `fedVatApi` |

## Steps

### Path A — Event-Driven (MBus VatInvoicing)

1. **Receive VatInvoicing event**: `reportingService_mbusConsumers` receives a `VatInvoicing` event from MBus.
   - From: `mbus`
   - To: `reportingService_mbusConsumers`
   - Protocol: MBus

2. **Fetch VAT financial data**: MBus Consumers delegates to External API Clients to fetch detailed VAT financial data from FED VAT API.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_externalApiClients` → `fedVatApi`
   - Protocol: REST

3. **Read EU voucher data**: Persistence Layer reads EU voucher records relevant to the invoice period.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_persistenceDaos` → `continuumEuVoucherDb`
   - Protocol: direct / JDBC

4. **Persist invoice record**: MBus Consumers writes the VAT invoice record to the VAT Database.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_persistenceDaos` → `continuumVatDb`
   - Protocol: direct / JDBC

5. **Trigger invoice PDF generation**: MBus Consumers delegates to `reportGenerationService` to render the invoice as a PDF.
   - From: `reportingService_mbusConsumers`
   - To: `reportGenerationService`
   - Protocol: direct

6. **Render PDF**: Report Generation uses FreeMarker templates and Flying Saucer to produce the VAT invoice PDF.
   - From: `reportGenerationService`
   - To: internal FreeMarker / Flying Saucer libraries
   - Protocol: direct

7. **Upload PDF to S3**: S3 Client uploads the invoice PDF to the S3 bucket.
   - From: `reportGenerationService`
   - To: `reportingService_s3Client` → `reportingS3Bucket`
   - Protocol: AWS SDK

8. **Persist file metadata**: Persistence Layer writes S3 key and file details to the Files Database.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumFilesDb`
   - Protocol: direct / JDBC

### Path B — Synchronous (POST /vat/v1/invoices)

1. **Receive invoice creation request**: Client sends `POST /vat/v1/invoices` with merchant and period details.
   - From: `external client`
   - To: `reportingService_apiControllers`
   - Protocol: REST

2. **Fetch VAT financial data**: Controllers delegate to External API Clients to fetch data from FED VAT API.
   - From: `reportingService_apiControllers`
   - To: `reportingService_externalApiClients` → `fedVatApi`
   - Protocol: REST

3. **Read EU voucher data, persist invoice, render PDF, upload to S3, persist metadata**: Same as steps 3–8 of Path A.

4. **Return invoice ID**: Controllers return the invoice ID and status to the caller.
   - From: `reportingService_apiControllers`
   - To: `external client`
   - Protocol: REST

### Path C — Retrieval (GET /vat/v1/invoices)

1. **Receive list request**: Client sends `GET /vat/v1/invoices`.
   - From: `external client`
   - To: `reportingService_apiControllers`
   - Protocol: REST

2. **Query VAT invoices**: Controllers query the VAT Database for invoice records matching filter criteria.
   - From: `reportingService_apiControllers`
   - To: `reportingService_persistenceDaos` → `continuumVatDb`
   - Protocol: direct / JDBC

3. **Return invoice list**: Controllers return the list of invoice records.
   - From: `reportingService_apiControllers`
   - To: `external client`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| FED VAT API unavailable | External API Clients exception | Invoice cannot be created; event processing or API call fails |
| VAT Database write failure | Hibernate exception | Invoice record not persisted; no PDF generated |
| S3 PDF upload failure | S3 Client exception | Invoice record persisted but PDF not available for download |
| VatInvoicing event malformed | Validation exception | Event dropped or DLQ (configuration not evidenced; confirm with service owner) |

## Sequence Diagram

```
mbus -> reportingService_mbusConsumers: VatInvoicing event
reportingService_mbusConsumers -> fedVatApi: GET VAT financial data
reportingService_mbusConsumers -> continuumEuVoucherDb: SELECT EU voucher records
reportingService_mbusConsumers -> continuumVatDb: INSERT invoice record
reportingService_mbusConsumers -> reportGenerationService: renderVatInvoicePdf(invoiceData)
reportGenerationService -> FreeMarker/FlyingSaucer: render PDF
reportGenerationService -> reportingService_s3Client: upload PDF
reportingService_s3Client -> reportingS3Bucket: PUT invoice PDF
reportGenerationService -> continuumFilesDb: INSERT file metadata

Client -> reportingService_apiControllers: GET /vat/v1/invoices
reportingService_apiControllers -> continuumVatDb: SELECT invoices
reportingService_apiControllers --> Client: 200 OK [invoice list]
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [Payment Event Consumption](payment-event-consumption.md)
- API endpoints: [API Surface](../api-surface.md) — `GET /vat/v1/invoices`, `POST /vat/v1/invoices`

---
service: "reporting-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Reporting Service (mx-merchant-reporting).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Report Generation](report-generation.md) | synchronous | API call — `POST /reports/v1/reports` | Merchant requests a report; service fetches data, renders file, stores to S3 |
| [Bulk Redemption Processing](bulk-redemption-processing.md) | asynchronous | API call — `POST /bulkredemption/v1/uploadcsvfile` + MBus | Merchant uploads CSV; service validates, publishes event, processes redemptions |
| [Deal Cap Enforcement](deal-cap-enforcement.md) | scheduled | Daily scheduler (`dealCapScheduler`) | Scheduled job checks deal cap status, updates state, enforces limits |
| [Payment Event Consumption](payment-event-consumption.md) | event-driven | MBus `PaymentNotification` event | Inbound payment notifications persisted and reporting workflows triggered |
| [Weekly Campaign Summary](weekly-campaign-summary.md) | scheduled | Weekly scheduler (`campaignScheduler`) | Automated weekly campaign performance report generation and distribution |
| [VAT Invoicing](vat-invoicing.md) | event-driven + synchronous | MBus `VatInvoicing` event and `POST /vat/v1/invoices` | VAT invoice creation from events and API; invoice retrieval via GET |
| [Report Retry Cleanup](report-retry-cleanup.md) | scheduled | Scheduled cleanup job | Detects and cleans up stale or failed report generation requests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 3 |
| Mixed (synchronous + asynchronous) | 1 |

## Cross-Service Flows

- **Report Generation** calls `continuumPricingApi` (live federated relationship) and multiple stub-only APIs (`dcApi`, `giaApi`, `m3Api`, `visApi`, `ordersApi`, `ugcApi`, `bookingToolApi`, `fedApi`, `taxonomyApi`, `rrApi`, `geoplacesApi`, `localizeApi`). See the central architecture model for cross-service container views.
- **Bulk Redemption Processing** publishes `BulkVoucherRedemption` to `mbus`; downstream voucher services consume this event outside this service's boundary.
- **Payment Event Consumption** consumes `PaymentNotification` from `mbus`; the publisher is outside this service's boundary.
- Architecture container view: `Reporting-reportGenerationService-Containers`
- Architecture component view: `Reporting-API-Components`

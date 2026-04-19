---
service: "getaways-payment-reconciliation"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-header]
---

# API Surface

## Overview

The service exposes a REST API via JAX-RS (RESTEasy) on port `8080`. The API is consumed by internal finance operations staff and any internal tooling that needs to list or pay reconciled invoices. A web UI (Freemarker/Dropwizard assets) is also served from the same port. The API is not publicly exposed; it is accessed via the internal VIP (`http://getaways-payment-reconciliation-vip.snc1`).

## Endpoints

### Invoice Endpoint

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/products/{product}/invoices` | List merchant invoices for a given product, with optional provider, parent payment group, and type filters | Internal (no public auth) |

### Invoice Payment Endpoint

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/products/{product}/invoices` | Submit payment for an invoice (pay an invoice); includes disputed reservation IDs, total, currency, memo | `x-remote-user` header (optional) |

## Request/Response Patterns

### Common headers

- `x-remote-user` — optional header identifying the remote user who initiates a payment action (used for audit/logging)
- `Content-Type: application/json` — required for POST requests

### Error format

> No evidence found in codebase of a standardised error envelope beyond HTTP status codes and raw response body strings from `APIResponse`.

### Pagination

> No evidence found in codebase of pagination on the invoice listing endpoint.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-level versioning is used. The API version is tracked in the OpenAPI schema (`1.0.0`) and the Maven artifact version (`1.0.x`).

## OpenAPI / Schema References

- OpenAPI 3.0 schema: `doc/schema.yaml` (in the service repository)
- Swagger 2.0 stub: `doc/swagger/swagger.yaml`

### MerchantInvoice response schema (key fields)

| Field | Type | Description |
|-------|------|-------------|
| `merchantInvoiceId` | integer | Internal invoice identifier |
| `merchantInvoiceNumber` | string | EAN invoice number |
| `invoiceDate` | date-time | Date the invoice was received |
| `totalAmount` | number | Total invoice amount |
| `currency` | string | Currency code (USD, EUR, GBP) |
| `statusId` | integer | Reconciliation status |
| `paymentGroupId` | integer | Payment group reference |
| `paymentUuid` | string | UUID of the associated payment |
| `merchantId` | string | Merchant (EAN affiliate) identifier |
| `memo` | string | Invoice memo |

### PostPaymentRequest schema (key fields)

| Field | Type | Description |
|-------|------|-------------|
| `merchantInvoiceId` | integer | Invoice to pay |
| `total` | number | Payment total |
| `currency` | string | Currency code |
| `invoiceDate` | string | Invoice date |
| `provider` | string | Provider identifier |
| `parentPaymentGroup` | integer | Parent payment group |
| `disputedReservationIds` | integer[] | IDs of reservations under dispute |
| `memo` | string | Payment memo |

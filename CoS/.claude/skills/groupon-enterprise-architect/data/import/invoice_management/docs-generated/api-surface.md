---
service: "invoice_management"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, oauth1a, api-key]
---

# API Surface

## Overview

invoice_management exposes a REST API for invoice lifecycle management, payment operations, vendor management, and data export. The API is consumed primarily by internal Goods platform tooling, finance operators, and the NetSuite webhook callback. All endpoints follow Play Framework routing conventions. The `/ns_callback` endpoint is a special inbound webhook from NetSuite and is authenticated via OAuth 1.0a signature verification.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service liveness check | None |
| GET | `/status` | Detailed service status | None |

### Invoice Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/list_invoices` | List invoices with filtering options | Internal auth |
| POST | `/create_invoices` | Trigger invoice creation for pending POs | Internal auth |
| GET | `/marketplace_invoice/:uuid` | Retrieve a specific marketplace invoice by UUID | Internal auth |
| POST | `/send_invoices` | Transmit pending invoices to NetSuite | Internal auth |
| POST | `/generate_3pl_invoices` | Generate invoices for 3PL partners | Internal auth |

### Payment Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/pull_payments` | Fetch and reconcile payments from NetSuite | Internal auth |
| GET | `/remittance_data` | Retrieve remittance data for a vendor | Internal auth |
| GET | `/export/payment_details` | Export payment details report | Internal auth |

### Purchase Orders

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/purchase_orders` | List purchase orders | Internal auth |

### Vendor / Receiver Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/create_receiver` | Create a new receiver record for a vendor | Internal auth |

### Shipment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/shipment_status` | Query shipment status for an invoice or PO | Internal auth |

### NetSuite Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/ns_callback` | Receive payment status callbacks from NetSuite | OAuth 1.0a signature |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON request bodies
- `Accept: application/json` for JSON responses
- NetSuite callback: `Authorization` header with OAuth 1.0a signature parameters

### Error format

> No evidence found in codebase. Standard Play Framework JSON error responses expected: HTTP status code + JSON body with `error` and `message` fields.

### Pagination

> No evidence found in codebase. `/list_invoices` and `/purchase_orders` likely support query parameter-based pagination given typical Goods platform conventions.

## Rate Limits

> No rate limiting configured. Endpoints are consumed by internal services and scheduled jobs.

## Versioning

No API versioning strategy in use. All routes are unversioned. Breaking changes are coordinated through internal service agreements.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or schema file identified in the inventory.

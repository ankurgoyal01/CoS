---
service: "accounting-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

Accounting Service exposes a versioned REST API used by internal Groupon services and operational tooling. The API covers vendor contract management, invoice lifecycle operations, merchant earnings queries, and transaction/statement retrieval. Three API versions are active: v3 (primary vendor/contract API), v2 (merchant earnings), and v1 (invoice workflow operations). Health and liveness probe endpoints are also available.

## Endpoints

### Health and Observability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v3/health` | Service health check with dependency status | None |
| GET | `/status` | Lightweight status probe | None |
| GET | `/heartbeat` | Liveness heartbeat for load balancer probing | None |

### Vendor Contracts (v3)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v3/vendors/{id}/contracts` | Retrieve contracts for a vendor | Internal |
| POST | `/api/v3/vendors/{id}/contracts` | Create or import a contract for a vendor | Internal |
| GET | `/api/v3/vendors/{id}/invoices` | List invoices for a vendor | Internal |
| GET | `/api/v3/vendors/{id}/transactions` | List transactions for a vendor | Internal |
| GET | `/api/v3/vendors/{id}/statements` | Retrieve statements for a vendor | Internal |
| GET | `/api/v3/vendors/{id}/payments` | Retrieve payments for a vendor | Internal |

### Merchant Earnings (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/merchants/{id}/earnings` | Retrieve earnings summary for a merchant | Internal |

### Invoice Workflow Operations (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v1/invoices/approve` | Approve a pending invoice | Internal |
| POST | `/api/v1/invoices/reject` | Reject a pending invoice | Internal |
| POST | `/api/v1/invoices/resubmit` | Resubmit a previously rejected invoice | Internal |
| POST | `/api/v1/workflows/make_decision` | Trigger a workflow decision step | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests
- Internal service-to-service auth headers as required by Continuum platform conventions

### Error format

> No evidence found in the inventory for a specific documented error response schema. Standard Rails JSON error responses are expected (HTTP status code with a JSON body containing an `error` or `errors` key).

### Pagination

> No evidence found in the inventory for a specific pagination strategy. List endpoints (transactions, invoices, statements) likely support offset or page-based pagination via query parameters — confirm with service owner.

## Rate Limits

> No rate limiting configured. This is an internal service not exposed to public traffic.

## Versioning

The API uses URL path versioning with three active versions:

- `/api/v3/` — primary vendor and contract API (current)
- `/api/v2/` — merchant earnings API
- `/api/v1/` — invoice workflow operations and legacy endpoints

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or GraphQL schema committed to this repository. Response serialization is handled via `rabl` templates.

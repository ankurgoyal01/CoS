---
service: "par-automation"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none-inbound]
---

# API Surface

## Overview

The PAR Automation API exposes two HTTP endpoints on port 8080. The primary endpoint (`POST /release/par`) is called by the Hybrid Boundary UI to initiate a PAR request. The secondary endpoint (`GET /release/healthcheck`) is used by Kubernetes readiness and liveness probes. The API accepts and returns `application/json`. There is no inbound authentication enforced by this service — access is controlled at the network level within the Hybrid Boundary/Conveyor service mesh.

## Endpoints

### PAR Request

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/release/par` | Submit and process a Policy Access Request | None (network-level) |
| `GET` | `/release/healthcheck` | Kubernetes readiness and liveness probe | None |

## Request/Response Patterns

### POST /release/par — Request

**Content-Type**: `application/json`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `FromService` | string | yes | The service requesting access (source principal) |
| `ToDomain` | string | yes | The Hybrid Boundary domain to which access is requested |
| `User` | string | yes | Okta username of the requester (without `@groupon.com`) |
| `Reason` | string | yes | Business justification for the access request |

**Example request body:**
```json
{
  "FromService": "my-service",
  "ToDomain": "payments--api",
  "User": "jsmith",
  "Reason": "Required to process order payments for new checkout flow"
}
```

### POST /release/par — Response (approvable, production)

**HTTP 200 OK** — Request was automatically approved and Hybrid Boundary was updated.

| Field | Type | Description |
|-------|------|-------------|
| `Description` | string | Human-readable approval or denial message |
| `PAR` | string | Jira PAR ticket key (production only, e.g., `PAR-1234`) |
| `GPROD` | string | Jira GPROD ticket key (production only, e.g., `GPROD-5678`) |

**HTTP 403 Forbidden** — Request was evaluated but denied by classification rules. `PAR` and `GPROD` are still populated in production (tickets are always created).

**Example response body (approved, production):**
```json
{
  "Description": "Access Approved: If the data classification of From Service is C1, then the To Service may be any one of C1, C2, C3 or unclassified.",
  "PAR": "PAR-1234",
  "GPROD": "GPROD-5678"
}
```

**Example response body (denied, production):**
```json
{
  "Description": "Access Denied: All combinations of services with PCI classifications are required to submit a PAR request.",
  "PAR": "PAR-1235",
  "GPROD": "GPROD-5679"
}
```

### POST /release/par — Response (staging/sandbox)

In non-production environments, the endpoint applies the Hybrid Boundary policy update regardless of approvability (to support testing), but returns `HTTP 200` or `HTTP 403` to indicate what would happen in production. `PAR` and `GPROD` fields are not included in non-production responses.

### GET /release/healthcheck — Response

**HTTP 200 OK** — Body: `OK` (plain text)

### Common headers

| Header | Direction | Value |
|--------|-----------|-------|
| `Content-Type` | Inbound (required) | `application/json` |
| `Content-Type` | Outbound | `application/json` |

### Error format

All errors return a JSON body with a single `Description` field:

```json
{
  "Description": "error message explaining what went wrong"
}
```

HTTP status codes used: `400 Bad Request` (missing/invalid payload, duplicate request, domain not found), `403 Forbidden` (classification rules deny access), `500 Internal Server Error` (upstream service failure).

### Pagination

> Not applicable — all endpoints return a single object.

## Rate Limits

> No rate limiting configured at the application layer. Network-level throttling is managed by the Hybrid Boundary service mesh.

## Versioning

The API uses a `/release/` path prefix. There is currently one API version; no versioning strategy beyond this prefix is implemented.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in the repository.

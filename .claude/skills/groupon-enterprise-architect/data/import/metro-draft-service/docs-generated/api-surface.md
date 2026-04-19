---
service: "metro-draft-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [rbac, session]
---

# API Surface

## Overview

Metro Draft Service exposes a REST HTTP API consumed by Metro internal tooling, merchant self-service portals, and partner onboarding flows. The API covers the full merchant deal drafting lifecycle: creating and editing deals, managing products, configuring redemption, uploading files, triggering publishing, and querying recommendations. All endpoints are routed through a Permission Filter (`continuumMetroDraftService_permissionFilter`) that enforces RBAC via `continuumRbacService` before reaching business logic.

## Endpoints

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/deals` | List draft deals | RBAC |
| POST | `/api/deals` | Create a new draft deal | RBAC |
| GET | `/api/deals/{id}` | Fetch a draft deal by ID | RBAC |
| PUT | `/api/deals/{id}` | Update a draft deal | RBAC |
| DELETE | `/api/deals/{id}` | Delete a draft deal | RBAC |
| POST | `/api/deals/{id}/clone` | Clone an existing draft deal | RBAC |
| GET | `/api/deals/{id}/eligibility` | Check deal eligibility for publishing | RBAC |
| POST | `/api/deals/{id}/publish` | Trigger publish orchestration for a deal | RBAC |

### MCM (Merchandising Change Management)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mcm/*` | Retrieve merchandising change logs and approvals | RBAC |
| POST | `/api/mcm/*` | Submit merchandising change sets | RBAC |
| PUT | `/api/mcm/*` | Update MCM records and approval states | RBAC |

### Merchants

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/merchants/*` | Retrieve merchant configuration and validation state | RBAC |
| POST | `/api/merchants/*` | Onboard or update merchant data | RBAC |

### Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/products/*` | Retrieve product and option definitions for a deal | RBAC |
| POST | `/api/products/*` | Create or update deal products including fine print and pricing steps | RBAC |

### Recommendations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/recommendations/*` | Fetch structure and deal recommendations | RBAC |

### Surveys

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/surveys/*` | Retrieve survey questions and responses | RBAC |
| POST | `/api/surveys/*` | Submit survey responses during drafting | RBAC |

### Code Pools

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/code-pools/*` | Look up redemption code pool availability | RBAC |

### File Upload

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/files/upload` | Upload documents and images; persists metadata to Document Data DAO and media to external services | RBAC |

### Vetting Flows

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/vetting-flows/*` | Retrieve vetting flow status and results | RBAC |
| POST | `/api/vetting-flows/*` | Submit vetting and checker actions for deals | RBAC |

### Places

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/places/*` | Look up and enrich merchant place data | RBAC |
| POST | `/api/places/*` | Create or update place records | RBAC |

### Redemption

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/redemption/*` | Retrieve redemption configuration for a deal | RBAC |
| PUT | `/api/redemption/*` | Update voucher delivery and redemption rules | RBAC |

## Request/Response Patterns

### Common headers

- `Authorization` — caller identity token used by the Permission Filter for RBAC evaluation
- `X-Feature-Country` — feature country context resolved by Header Backup Service for geo-specific behavior
- `Content-Type: application/json` — standard for all JSON request bodies

### Error format

Standard Dropwizard/JTier JSON error response:

```json
{
  "code": 400,
  "message": "Validation failed: deal title is required"
}
```

HTTP status codes follow REST conventions: 200/201 for success, 400 for validation errors, 403 for permission errors, 404 for not found, 500 for internal errors.

### Pagination

> No evidence found for a specific pagination scheme in the architecture model. Standard list endpoints likely accept query parameters; confirm with service owner.

## Rate Limits

> No rate limiting configured — no evidence in the architecture model.

## Versioning

The API uses path-based versioning implied by the `/api/` prefix. No explicit versioned path segments (e.g., `/v1/`) are evident from the architecture model.

## OpenAPI / Schema References

> No OpenAPI spec or schema files are present in the architecture model inventory. Contact the Metro Team (metro-dev-blr@groupon.com) for current API contracts.

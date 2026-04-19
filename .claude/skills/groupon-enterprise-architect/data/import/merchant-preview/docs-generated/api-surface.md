---
service: "merchant-preview"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

Merchant Preview exposes an HTTP interface built on Ruby on Rails MVC. Merchants access preview pages via a public URL fronted by Akamai CDN. Account managers access the same application via an internal gateway. The interface supports preview viewing, comment submission, and approval actions.

## Endpoints

### Preview Pages and Actions

> No evidence found in codebase for specific HTTP route paths. The `mpPreviewWebController` component handles Rails controllers and presenters for preview pages and user actions. Endpoint paths are not enumerated in the architecture DSL.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/preview/:deal_id` | Render deal creative preview page for merchant or account manager | Session / token in URL |
| POST | `/preview/:deal_id/comments` | Submit a new comment on deal creative | Session / token in URL |
| PATCH | `/preview/:deal_id/comments/:id` | Update or resolve an existing comment | Session / token in URL |
| POST | `/preview/:deal_id/approve` | Record merchant approval of deal creative | Session / token in URL |
| POST | `/preview/:deal_id/reject` | Record merchant rejection of deal creative | Session / token in URL |

> The specific route paths above are inferred from the component responsibilities described in the architecture model. Exact paths must be verified against the service's Rails routes file.

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific header requirements.

### Error format

> No evidence found in codebase for standardized error response shape.

### Pagination

> No evidence found in codebase for pagination patterns.

## Rate Limits

> No evidence found in codebase for rate limiting configuration.

No rate limiting configured at the architecture model level. Akamai CDN may apply edge-level rate controls.

## Versioning

> No evidence found in codebase for API versioning strategy. The service is a legacy Rails application without versioned API paths documented in the architecture model.

## OpenAPI / Schema References

> No evidence found in codebase for OpenAPI spec, proto files, or schema definitions.

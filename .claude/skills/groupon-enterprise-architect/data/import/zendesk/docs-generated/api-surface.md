---
service: "zendesk"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

Zendesk exposes a REST API that Groupon systems interact with through the `zendeskApi` integration component. Groupon's internal services use this API to create, read, update, and resolve support tickets and cases as part of the Global Support Systems workflows. The API integration layer acts as the sole ingress point between Groupon's Continuum Platform and Zendesk's managed SaaS environment.

> No evidence found in codebase of specific endpoint paths, request/response schemas, or client-side code. The Zendesk API is a third-party SaaS API. Official documentation is available at [https://developer.zendesk.com/api-reference/](https://developer.zendesk.com/api-reference/).

## Endpoints

### Ticket and Case Management (via Zendesk API)

> No evidence found in codebase of specific endpoint paths configured or called by Groupon-owned code. The following represent the Zendesk SaaS API capabilities consumed by the `zendeskApi` integration component, as described in the architecture DSL.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v2/tickets` | Create a new support ticket | API key |
| GET | `/api/v2/tickets/{id}` | Retrieve a ticket by ID | API key |
| PUT | `/api/v2/tickets/{id}` | Update an existing ticket | API key |
| DELETE | `/api/v2/tickets/{id}` | Delete or close a ticket | API key |
| GET | `/api/v2/tickets` | List tickets (with filters) | API key |

## Request/Response Patterns

### Common headers

> No evidence found in codebase of specific headers configured in Groupon-owned code. Standard Zendesk API headers include `Authorization: Basic {base64(email:api_token)}` and `Content-Type: application/json`.

### Error format

> No evidence found in codebase of error handling patterns for Zendesk API responses in Groupon-owned code.

### Pagination

> No evidence found in codebase. Zendesk uses cursor-based pagination via `after_cursor` and `before_cursor` fields in list responses.

## Rate Limits

> No evidence found in codebase of rate limit configuration. Zendesk SaaS rate limits are governed by the Groupon account tier with Zendesk.

## Versioning

The Zendesk REST API uses URL path versioning (`/api/v2/`). Groupon integrates against API v2 as indicated by the SaaS API integration component in the architecture model.

## OpenAPI / Schema References

> No evidence found in codebase of an OpenAPI spec or schema file in this repository. Refer to the Zendesk official API reference and the architecture documentation linked in `.service.yml`: [https://drive.google.com/file/d/1uO-0QtNuia0ikGC3ZwJzibfJ4zoQZYJj/view](https://drive.google.com/file/d/1uO-0QtNuia0ikGC3ZwJzibfJ4zoQZYJj/view).

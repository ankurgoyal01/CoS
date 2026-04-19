---
service: "darwin-groupon-deals"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

The Darwin Aggregator Service exposes a REST/HTTP API via Dropwizard (JAX-RS/Jersey). Consumers submit deal search and discovery requests; the service fans out to upstream data sources, applies relevance ranking, and returns ranked deal cards. The API is versioned by URL path prefix (`/v2/`, `/cards/v1/`, `/batch/`). An admin endpoint provides Hystrix circuit-breaker stream access for operational monitoring.

## Endpoints

### Deal Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/deals/search` | Full deal search with relevance ranking and personalization | Internal service auth |
| GET | `/v1/deals/local` | Local deals search, filtered and ranked by geo context | Internal service auth |

### Card Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cards/v1/search` | Card-format deal search for UI rendering | Internal service auth |
| GET | `/batch/cards/v1/search` | Batch card search for bulk retrieval | Internal service auth |

### A/B Experiment Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/booster_ab_experiments` | Retrieve current booster A/B experiment configurations | Internal service auth |
| PUT | `/booster_ab_experiments` | Update booster A/B experiment configurations | Internal service auth |

### Admin / Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/hystrix` | Hystrix event stream for circuit-breaker monitoring | Admin / internal only |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all JSON request and response bodies
- `Accept: application/json` — expected by all endpoints
- Internal caller identity headers as required by Groupon service-to-service auth conventions

### Error format

> No evidence found in the inventory for a specific error response schema. Standard Dropwizard error responses return JSON with `code` and `message` fields. Consult the service owner for the exact error contract.

### Pagination

> No evidence found in the inventory for a specific pagination contract. Search endpoints typically accept query parameters such as `offset` and `limit`; confirm with the service owner for the exact parameter names.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning:
- `/v1/` — first-generation local deals endpoint
- `/v2/` — second-generation full deal search endpoint
- `/cards/v1/` — card-format search, versioned independently
- `/batch/cards/v1/` — batch variant of card search

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec or proto files committed to the repository. Consult the service owner (relevance-engineering@groupon.com) for schema documentation.

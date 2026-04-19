---
service: "mdi-dashboard-v2"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, itier-user-auth]
---

# API Surface

## Overview

mdi-dashboard-v2 exposes an HTTP API consumed primarily by its own browser-based frontend (server-rendered pages and AJAX calls). All routes are protected by Groupon internal user authentication via itier-user-auth. The API surface covers deal search, cluster analytics, merchant insights, API key management, feed builder operations, taxonomy/city/location lookups, relevance scoring, and deal options retrieval.

## Endpoints

### Deal Browser

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/browser` | Search and browse deals from the Marketing Deal Service | itier-user-auth session |

### Deal Cluster Analytics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clusters` | Retrieve deal clustering and grouping analytics | itier-user-auth session |

### Merchant Insights

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchantInsights` | Retrieve merchant performance metrics and insights | itier-user-auth session |

### API Key Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/keys` | List API keys | itier-user-auth session |
| POST | `/keys` | Create a new API key | itier-user-auth session |
| DELETE | `/keys` | Revoke an API key | itier-user-auth session |

### Feed Builder

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/feeds` | List feed configurations | itier-user-auth session |
| POST | `/feeds` | Create a new feed configuration | itier-user-auth session |
| PUT | `/feeds` | Update an existing feed configuration | itier-user-auth session |
| DELETE | `/feeds` | Delete a feed configuration | itier-user-auth session |
| POST | `/feeds/generate` | Trigger feed generation via MDS Feed Service | itier-user-auth session |

### Search (Taxonomy / City / Location)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/search/*` | Search taxonomy categories, cities, and locations | itier-user-auth session |

### Relevance API Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rapi` | Proxy relevance scoring queries to the Relevance API | itier-user-auth session |

### Deal Options

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/options/:id` | Retrieve deal options for a given deal ID from Deal Catalog | itier-user-auth session |

## Request/Response Patterns

### Common headers

- `Cookie` — session cookie used by itier-user-auth for identity propagation
- `Content-Type: application/json` — required on POST/PUT requests with JSON bodies
- `Accept: application/json` — used by AJAX callers expecting JSON responses

### Error format

> No evidence found of a standardized error response schema in the inventory. Error responses follow Express default error handling behavior. HTTP status codes indicate error class (4xx for client errors, 5xx for server errors).

### Pagination

> No evidence found of a standardized pagination pattern. Deal browser and search results may return paginated data proxied from upstream services (Marketing Deal Service, Taxonomy Service).

## Rate Limits

> No rate limiting configured at the dashboard layer. Rate limiting for downstream services is managed by the API Proxy.

## Versioning

No API versioning strategy is applied. The dashboard is an internal tool; breaking changes are coordinated directly with the consuming UI.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or GraphQL schema in the inventory.

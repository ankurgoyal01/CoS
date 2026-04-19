---
service: "wolfhound-api"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-auth]
---

# API Surface

## Overview

Wolfhound API exposes a REST HTTP API for SEO content management. Consumers use it to create, read, update, delete, and publish SEO pages, manage templates, define schedules, bootstrap taxonomies, manage traffic rules and redirects, tag content, and retrieve mobile page payloads. The API is versioned via URL path prefix (`/wh/v2` and `/wh/v3`).

## Endpoints

### Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/pages` | List/search pages | Internal |
| POST | `/wh/v2/pages` | Create a new page | Internal |
| GET | `/wh/v2/pages/{id}` | Retrieve a page by ID | Internal |
| PUT | `/wh/v2/pages/{id}` | Update a page | Internal |
| DELETE | `/wh/v2/pages/{id}` | Delete a page | Internal |
| POST | `/wh/v2/pages/{id}/publish` | Publish a page version | Internal |
| GET | `/wh/v3/pages` | List/search pages (v3 schema) | Internal |
| POST | `/wh/v3/pages` | Create a new page (v3 schema) | Internal |
| GET | `/wh/v3/pages/{id}` | Retrieve a page by ID (v3 schema) | Internal |
| PUT | `/wh/v3/pages/{id}` | Update a page (v3 schema) | Internal |
| DELETE | `/wh/v3/pages/{id}` | Delete a page (v3 schema) | Internal |
| POST | `/wh/v3/pages/{id}/publish` | Publish a page version (v3) | Internal |

### Mobile

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/mobile` | Retrieve mobile page payload (Relevance API enriched) | Internal |

### Bloggers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/bloggers` | List blogger records | Internal |
| POST | `/wh/v2/bloggers` | Create a blogger record | Internal |
| GET | `/wh/v2/bloggers/{id}` | Retrieve a blogger by ID | Internal |
| PUT | `/wh/v2/bloggers/{id}` | Update a blogger | Internal |
| DELETE | `/wh/v2/bloggers/{id}` | Delete a blogger | Internal |

### Schedules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/schedules` | List publish schedules | Internal |
| POST | `/wh/v2/schedules` | Create a publish schedule | Internal |
| GET | `/wh/v2/schedules/{id}` | Retrieve a schedule by ID | Internal |
| PUT | `/wh/v2/schedules/{id}` | Update a schedule | Internal |
| DELETE | `/wh/v2/schedules/{id}` | Delete a schedule | Internal |

### Taxonomies

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/taxonomies` | List taxonomy entries | Internal |
| POST | `/wh/v2/taxonomies` | Bootstrap/create taxonomy entries | Internal |
| GET | `/wh/v2/taxonomies/{id}` | Retrieve a taxonomy entry | Internal |
| PUT | `/wh/v2/taxonomies/{id}` | Update a taxonomy entry | Internal |
| DELETE | `/wh/v2/taxonomies/{id}` | Delete a taxonomy entry | Internal |

### Clusters

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/clusters` | Fetch cluster navigation and top-cluster content | Internal |

### Templates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/templates` | List Handlebars page templates | Internal |
| POST | `/wh/v2/templates` | Create a template | Internal |
| GET | `/wh/v2/templates/{id}` | Retrieve a template by ID | Internal |
| PUT | `/wh/v2/templates/{id}` | Update a template | Internal |
| DELETE | `/wh/v2/templates/{id}` | Delete a template | Internal |

### Rules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/rules` | List content rules | Internal |
| POST | `/wh/v2/rules` | Create a content rule | Internal |
| PUT | `/wh/v2/rules/{id}` | Update a content rule | Internal |
| DELETE | `/wh/v2/rules/{id}` | Delete a content rule | Internal |

### Tags

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/tags` | List tags | Internal |
| POST | `/wh/v2/tags` | Create a tag | Internal |
| GET | `/wh/v2/tags/{id}` | Retrieve a tag by ID | Internal |
| PUT | `/wh/v2/tags/{id}` | Update a tag | Internal |
| DELETE | `/wh/v2/tags/{id}` | Delete a tag | Internal |

### Traffic

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/traffic` | List traffic rules | Internal |
| POST | `/wh/v2/traffic` | Create a traffic rule | Internal |
| PUT | `/wh/v2/traffic/{id}` | Update a traffic rule | Internal |
| DELETE | `/wh/v2/traffic/{id}` | Delete a traffic rule | Internal |

### Redirects

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/redirects` | List redirect rules | Internal |
| POST | `/wh/v2/redirects` | Create a redirect rule | Internal |
| PUT | `/wh/v2/redirects/{id}` | Update a redirect rule | Internal |
| DELETE | `/wh/v2/redirects/{id}` | Delete a redirect rule | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all write operations
- `Accept: application/json` — expected for all responses

### Error format

> No evidence found in architecture inventory. Error response format is defined at the Dropwizard/JTier framework level.

### Pagination

> No evidence found in architecture inventory. Pagination patterns are not explicitly defined in the DSL model.

## Rate Limits

No rate limiting configured.

## Versioning

API versioning uses URL path prefixes. `/wh/v2/` is the primary version; `/wh/v3/pages` provides an updated pages schema. Both versions are actively served.

## OpenAPI / Schema References

> No evidence found in architecture inventory. OpenAPI specification location is not declared in the DSL model. Consult the wolfhound-api source repository.

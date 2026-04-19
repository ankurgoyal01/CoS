---
service: "seo-admin-ui"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, graphql]
auth_mechanisms: [session]
---

# API Surface

## Overview

seo-admin-ui is primarily a browser-facing admin UI rather than a machine-to-machine API service. Its HTTP surface consists of server-rendered page routes for admin operators and a `/status.json` health endpoint consumed by infrastructure tooling. The service acts as an API consumer (not a provider) for its downstream integrations. All routes require I-Tier session authentication.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status.json` | Service liveness and health check | None |

### Landing Page Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/landing-pages` | List landing page routes | I-Tier session |
| POST | `/landing-pages` | Create a new landing page route | I-Tier session |
| PUT | `/landing-pages/:id` | Update an existing landing page route | I-Tier session |
| DELETE | `/landing-pages/:id` | Delete a landing page route | I-Tier session |

### Canonical Updates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/canonical-updates` | List pending canonical update tasks | I-Tier session |
| POST | `/canonical-updates` | Submit a new canonical URL update | I-Tier session |

### SEO Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/seo-deals` | List SEO deal pages and attributes | I-Tier session |
| POST | `/seo-deals` | Create or update SEO deal attributes | I-Tier session |

### URL Removal Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/url-removals` | List submitted URL removal requests | I-Tier session |
| POST | `/url-removals` | Submit a new URL removal request | I-Tier session |

### Page Route Auditing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/route-audit` | Run or view a page route audit report | I-Tier session |

### Crosslinks Analysis

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/crosslinks` | View crosslinks graph for a given page | I-Tier session |

### Auto-Index Worker

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/auto-index/trigger` | Manually trigger the auto-index worker | I-Tier session |

## Request/Response Patterns

### Common headers

- `Cookie`: I-Tier session cookie required on all authenticated routes
- `Content-Type: application/json` for JSON POST/PUT bodies
- `Accept: application/json` for JSON response negotiation

### Error format

> No evidence found in codebase. Standard I-Tier error responses expected (HTTP status code + JSON error body).

### Pagination

> No evidence found in codebase. List endpoints likely return full result sets given admin-only usage patterns.

## Rate Limits

> No rate limiting configured. This is an internal admin UI with a limited operator user base.

## Versioning

No API versioning strategy in use. All routes are unversioned; breaking changes are coordinated with the operator team directly.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or GraphQL schema file identified in the inventory.

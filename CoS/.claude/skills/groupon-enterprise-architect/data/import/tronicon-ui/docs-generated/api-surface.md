---
service: "tronicon-ui"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, http-proxy]
auth_mechanisms: [session, oauth2]
---

# API Surface

## Overview

Tronicon UI exposes an HTTP interface via web.py routes served by Gunicorn. All endpoints are designed for consumption by internal browser-based users (merchandising and campaign operations staff). The surface covers four functional areas: campaign card management (Cardatron), CMS content management, business group/campaign group administration, and a transparent proxy to the Campaign Service. Configuration is also exposed via a JSON endpoint consumed at application bootstrap.

## Endpoints

### Application Bootstrap

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Main dashboard — entry point for the tool | session |
| GET | `/config.json` | Returns application runtime configuration used by the frontend | session |

### Business Group and Campaign Group Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/businessgroups` | List all business groups | session |
| POST | `/businessgroups` | Create or update a business group | session |
| POST | `/cpgnGroups/add` | Create a new campaign group | session |

### Campaign Service Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/c/:path` | Transparent proxy to Campaign Service; all methods and sub-paths forwarded | session |

### Cardatron — Card Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cardatron/cards` | List all cards | session |
| POST | `/cardatron/cards` | Create a new card | session |
| GET | `/cardatron/card/:id` | Retrieve a single card by ID | session |
| POST | `/cardatron/card/:id` | Update an existing card | session |
| PUT | `/cardatron/card/:id` | Full replacement update of a card | session |
| GET | `/cardatron/card/preview/:id` | Render a preview of the card | session |

### Cardatron — Deck Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cardatron/decks` | List all decks | session |
| POST | `/cardatron/decks` | Create a new deck | session |

### Cardatron — Template Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cardatron/templates` | List all card templates | session |
| POST | `/cardatron/templates` | Create or update a card template | session |

### Cardatron — Geo Polygons

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cardatron/geo-polygons` | List all geographic boundary definitions | session |
| POST | `/cardatron/geo-polygons` | Create or update a geo polygon | session |

### CMS Content Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cms` | List CMS content entries | session |
| POST | `/cms` | Create, edit, version, archive, or audit CMS content entries | session |

### Theme Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/themes` | List configured UI themes | session |
| POST | `/themes` | Create or update a UI theme (supports CSV upload and scheduling) | session |

## Request/Response Patterns

### Common headers

> No evidence found in codebase for specific required headers beyond standard browser session cookies.

### Error format

> No evidence found in codebase for a standardized error response envelope. Errors are expected to follow web.py default HTTP error responses.

### Pagination

> No evidence found in codebase for a standardized pagination contract on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy is in use. All routes are unversioned. The `/c/:path` proxy defers versioning to the downstream Campaign Service.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in the repository.

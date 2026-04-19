---
service: "Deal-Estate"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, api-key]
---

# API Surface

## Overview

Deal-Estate exposes a REST API served by the `continuumDealEstateWeb` Rails/Unicorn container. The API covers two route namespaces: the primary `/deals` resource for full deal CRUD and lifecycle state operations, and a versioned `/api/v1/deals` namespace for scheduling and importability operations. Internal tooling and other Continuum services are the primary consumers.

## Endpoints

### Deal CRUD and Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals` | List / search deals | session / api-key |
| POST | `/deals` | Create a new deal | session / api-key |
| GET | `/deals/:id` | Retrieve a deal by ID | session / api-key |
| PUT | `/deals/:id` | Update a deal | session / api-key |
| DELETE | `/deals/:id` | Delete a deal | session / api-key |

### Deal State Transitions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/deals/:id/import` | Trigger import of deal data from an external source | session / api-key |
| POST | `/deals/:id/schedule` | Schedule a deal for publication | session / api-key |
| POST | `/deals/:id/unschedule` | Remove a deal from the publication schedule | session / api-key |
| POST | `/deals/:id/close` | Close a live deal | session / api-key |
| POST | `/deals/:id/unpause` | Unpause a paused deal | session / api-key |
| POST | `/deals/:id/archive` | Archive a deal | session / api-key |
| POST | `/deals/:id/sync_data` | Trigger manual data sync for a deal | session / api-key |

### Deal Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/search` | Search deals with filters | session / api-key |

### Versioned API (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v1/deals/:id/schedule` | Schedule a deal (versioned endpoint) | session / api-key |
| GET | `/api/v1/deals/:id/schedulable` | Check whether a deal is schedulable | session / api-key |
| GET | `/api/v1/deals/:id/imported` | Check whether a deal has been imported | session / api-key |
| GET | `/api/v1/deals/:id/distribution_windows` | Retrieve distribution windows for a deal | session / api-key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all JSON request bodies
- `Accept: application/json` for JSON responses

### Error format

> No evidence found for a documented standard error schema. Follows Rails default JSON error responses. Consult service owner for exact error envelope format.

### Pagination

> No evidence found for a documented pagination contract. Assumed standard Rails params (`page`, `per_page`) based on common Continuum conventions.

## Rate Limits

> No rate limiting configured.

## Versioning

Two versioning strategies are in use:
- **Unversioned** routes: `/deals` and nested state-transition actions — legacy primary namespace.
- **URL-path versioned** routes: `/api/v1/deals/:id/...` — introduced for scheduling and importability checks.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema found in the federated model. API contract is defined implicitly by Rails routes and controllers.

---
service: "cs-api"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt, cs-token]
---

# API Surface

## Overview

CS API exposes a synchronous REST API over HTTPS/JSON consumed by the Cyclops customer support agent web application. All endpoints are agent-facing: they surface customer data, enable case management actions, and proxy interactions with external support platforms. Authentication is enforced via JWT tokens validated by the `authModule` component, with CS-specific tokens issued by `continuumCsTokenService`.

## Endpoints

### Agent Capabilities and Roles

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/abilities` | Returns the set of abilities available to the authenticated agent | JWT |
| GET | `/agent-info` | Returns profile and metadata for the authenticated agent | JWT |
| GET | `/agent-roles` | Lists all agent roles | JWT |
| POST | `/agent-roles` | Creates a new agent role | JWT |
| PUT | `/agent-roles/{id}` | Updates an existing agent role | JWT |
| DELETE | `/agent-roles/{id}` | Deletes an agent role | JWT |

### Sessions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/sessions` | Creates a new agent session; issues and caches session token | JWT |
| DELETE | `/sessions/{id}` | Terminates an agent session | JWT |

### Customer Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/customer-attributes` | Returns aggregated customer attributes from consumer data and audience management | JWT |
| GET | `/customer-notifications` | Returns notification history for a customer | JWT |

### Orders and Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/orders` | Returns order history for a customer; queries Orders Service | JWT |
| GET | `/deals` | Returns deal details; queries Deal Catalog and inventory services | JWT |

### Case Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/memos` | Lists case memos for a customer or case | JWT |
| POST | `/memos` | Creates a new case memo | JWT |
| PUT | `/memos/{id}` | Updates an existing memo | JWT |
| DELETE | `/memos/{id}` | Deletes a memo | JWT |
| GET | `/snippets` | Lists reusable response snippets | JWT |
| POST | `/snippets` | Creates a new snippet | JWT |
| PUT | `/snippets/{id}` | Updates a snippet | JWT |
| DELETE | `/snippets/{id}` | Deletes a snippet | JWT |

### Features and Flags

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/features` | Returns feature flag state for the agent or customer context | JWT |

### Refunds and Incentives

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/convert-to-cash` | Converts a refund to Groupon Bucks via Incentives Service | JWT |

### Merchants

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants` | Returns merchant information for a given deal or order | JWT |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <jwt-token>` — required on all endpoints
- `Content-Type: application/json` — required for POST/PUT requests
- `Accept: application/json` — expected on all requests

### Error format

> No evidence found in the DSL model for a specific error envelope schema. Assumed standard Dropwizard JSON error format: `{ "code": <int>, "message": "<string>" }`.

### Pagination

> No evidence found for a specific pagination strategy in the inventory. Pagination details to be confirmed with the service owner.

## Rate Limits

> No rate limiting configured. Rate control is managed at the API gateway / JTier platform level.

## Versioning

> No URL-path versioning evidence found. Versioning strategy to be confirmed with service owner; assumed implicit (single unversioned API surface).

## OpenAPI / Schema References

> No OpenAPI spec or proto files were identified in the repository inventory. Schema definitions are embedded in Jersey resource classes and model objects within the service codebase.

---
service: "openmetadata-server"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [saml, jwt]
---

# API Surface

## Overview

OpenMetadata Server exposes a REST API following the OpenMetadata open standard. Consumers use it to discover, create, update, and govern metadata entities (tables, pipelines, dashboards, glossary terms, etc.), run data quality tests, and manage ingestion pipelines. The API is versioned under `/api/v1/`. Both the `server` component (port 8585) and the `api` component (separately routed) serve the same API surface with different deployment boundary configurations.

## Endpoints

### System and Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Readiness check (HTTP 200 if service is up) | None |
| GET | `/healthcheck` | Liveness check served on admin port 8586 | None |
| GET | `/prometheus` | Prometheus metrics scrape endpoint | None |
| GET | `/api/v1/system/config/jwks` | Exposes JWT public key set (JWKS) for token verification | None |

### SAML / Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/saml/login` | Initiates SAML SSO login flow with Okta | None |
| GET | `/api/v1/saml/metadata` | Exposes SAML Service Provider metadata | None |
| POST | `/api/v1/saml/acs` | SAML Assertion Consumer Service — processes Okta assertion | None |
| GET | `/saml/callback` | Post-login redirect callback URI | None |

### Metadata Entities (representative — OpenMetadata REST API standard)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/tables` | List and search table metadata entities | JWT / SAML session |
| POST | `/api/v1/tables` | Create a new table metadata entity | JWT / SAML session |
| GET | `/api/v1/tables/{id}` | Retrieve a specific table entity by ID | JWT / SAML session |
| PUT | `/api/v1/tables/{id}` | Update a table metadata entity | JWT / SAML session |
| DELETE | `/api/v1/tables/{id}` | Delete a table metadata entity | JWT / SAML session |
| GET | `/api/v1/search/query` | Execute metadata search queries | JWT / SAML session |
| GET | `/api/v1/lineage/{entity}/{id}` | Retrieve lineage graph for an entity | JWT / SAML session |
| GET | `/api/v1/glossaryTerms` | List glossary terms | JWT / SAML session |
| POST | `/api/v1/glossaryTerms` | Create a glossary term | JWT / SAML session |
| GET | `/api/v1/dataQuality/testCases` | List data quality test cases | JWT / SAML session |
| POST | `/api/v1/ingestion` | Create or trigger an ingestion pipeline | JWT / SAML session |

> The above metadata endpoints follow the OpenMetadata open API specification. The full endpoint set is defined by the upstream OpenMetadata project at the configured version (1.6.9).

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <jwt-token>` — required for authenticated endpoints
- `Content-Type: application/json` — for POST/PUT/PATCH requests

### Error format

Follows OpenMetadata standard error responses with HTTP status codes and JSON body:
```json
{
  "code": 404,
  "message": "Entity not found for query ...",
  "entity": "Table"
}
```

### Pagination

OpenMetadata REST API uses cursor/offset-based pagination with `limit` and `before`/`after` query parameters:
- `GET /api/v1/tables?limit=10&after=<cursor>`

## Rate Limits

> No rate limiting configured at the application level. Kubernetes HPA scales pods based on CPU utilization (target 95%) to handle load. Server component: min 2, max 20 replicas. API component: min 2, max 25 replicas.

## Versioning

All OpenMetadata REST endpoints are served under the `/api/v1/` path prefix. No header-based or query-parameter versioning is used. Version upgrades are managed by deploying a new base image version (e.g., `openmetadata/server:1.6.9`) and running Flyway migrations.

## OpenAPI / Schema References

- OpenMetadata upstream API specification: [https://docs.open-metadata.org/latest/main-concepts/metadata-standard/apis](https://docs.open-metadata.org/latest/main-concepts/metadata-standard/apis)
- JWKS endpoint for JWT verification: `https://datacatalog.groupondev.com/api/v1/system/config/jwks` (production)
- SAML SP metadata: `https://datacatalog.groupondev.com/api/v1/saml/metadata` (production)

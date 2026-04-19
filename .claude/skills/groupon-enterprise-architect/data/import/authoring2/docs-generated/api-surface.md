---
service: "authoring2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, role-based]
---

# API Surface

## Overview

Authoring2 exposes a REST API built with Jersey/JAX-RS. All endpoints are mounted under the servlet context root `/` (cloud deployment) or `/v1/` (embedded local Tomcat). The API is consumed primarily by the bundled Ember.js UI. JSON is the primary content type for all data endpoints; CSV and XLS responses are produced by export endpoints. Authentication and access control are handled by a `AuthorizationFilter` JAX-RS filter that enforces role-based permissions stored in the database.

Internal base URLs:
- Production (on-prem snc1): `https://taxonomy-authoringv2-app-vip.snc1`
- Staging (on-prem snc1): `https://taxonomy-authoringv2-app-staging-vip.snc1`
- Production (GCP us-central1): `authoring2.us-central1.conveyor.prod.gcp.groupondev.com`
- Production (GCP us-west-1): `authoring2.us-west-1.conveyor.prod.gcp.groupondev.com`

## Endpoints

### Taxonomies

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/taxonomies` | Create a new taxonomy | Role-based |
| `PUT` | `/taxonomies` | Update an existing taxonomy | Role-based |
| `DELETE` | `/taxonomies/{id}` | Delete a taxonomy by numeric ID | Role-based |
| `GET` | `/taxonomies/{id}` | Retrieve a taxonomy with last-updated-by audit info | Role-based |
| `GET` | `/taxonomies/{id}/children` | List first-level categories of a taxonomy | Role-based |
| `GET` | `/taxonomies/all/children` | List all taxonomies with their full child data | Role-based |
| `GET` | `/taxonomies/cft_taxonomies` | List all taxonomies as BO list | Role-based |
| `GET` | `/taxonomies/cft_tree/{guid}` | Retrieve taxonomy tree in D3 format by GUID | Role-based |
| `GET` | `/taxonomies/cft_relations_tree/{guid}` | Retrieve category relationship tree with breadcrumbs | Role-based |
| `GET` | `/taxonomies/csv/{guid}` | Export taxonomy as CSV attachment | Role-based |
| `GET` | `/taxonomies/pdstocft` | Export PDS-to-CFT cross-reference CSV | Role-based |
| `GET` | `/taxonomies/cfttopds` | Export CFT-to-PDS cross-reference CSV | Role-based |
| `GET` | `/taxonomies/mrttoattribute` | Export MRT-to-attribute mapping CSV | Role-based |
| `GET` | `/taxonomies/mrttopds` | Export MRT-to-PDS mapping CSV | Role-based |
| `GET` | `/taxonomies/bttopds` | Export BT-to-PDS mapping CSV | Role-based |
| `PUT` | `/taxonomies/move/{guid}/to/{parent}` | Move a root category to a different taxonomy | Role-based |
| `GET` | `/taxonomies/partial/{from}` | Retrieve taxonomies modified after epoch timestamp | Role-based |

### Categories

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/categories` | Create a category (en_US locale default) | Role-based |
| `PUT` | `/categories` | Update a category | Role-based |
| `DELETE` | `/categories/{id}` | Delete a category and all related records by numeric ID | Role-based |
| `GET` | `/categories/{id}` | Retrieve a category with audit info | Role-based |
| `GET` | `/categories/{id}/children` | List direct child categories | Role-based |
| `GET` | `/categories/search?q={query}` | Search categories by name or GUID | Role-based |
| `GET` | `/categories/{guid}/locale/{localeId}` | Retrieve category in a specific locale | Role-based |
| `GET` | `/categories/delete/{id}` | Preview impact of deleting a category | Role-based |
| `GET` | `/categories/breadcrumb/{id}` | Retrieve category breadcrumb by numeric ID | Role-based |
| `GET` | `/categories/breadcrumb/sp/{guid}` | Retrieve breadcrumb string via stored procedure by GUID | Role-based |
| `GET` | `/categories/breadcrumb/guid/{guid}` | Retrieve category breadcrumb by GUID | Role-based |
| `PUT` | `/categories/move/{guid}/to/{parent}` | Move a category to a new parent category | Role-based |
| `POST` | `/categories/createwithlocale` | Create a category with locale assignment | Role-based |
| `PUT` | `/categories/createwithlocale` | Update a category with locale assignment | Role-based |
| `POST` | `/categories/createaschildren` | Create a category as a child of an existing category | Role-based |
| `GET` | `/categories/xlscategorylocales/{taxonomyGuid}` | Export category locale data as XLSX | Role-based |
| `GET` | `/categories/csvcategorylocales/{taxonomyGuid}` | Export category locale data as ZIP/CSV (max 2 concurrent) | Role-based |
| `GET` | `/categories/partial/{from}` | Retrieve categories modified after epoch timestamp | Role-based |

### Relationships

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/relationships` | Create a category relationship | Role-based |
| `PUT` | `/relationships` | Update a category relationship | Role-based |
| `DELETE` | `/relationships/{id}` | Delete a relationship by numeric ID | Role-based |
| `GET` | `/relationships/{id}` | Retrieve a relationship by numeric ID | Role-based |
| `GET` | `/relationships` | List all relationships | Role-based |
| `GET` | `/relationships/{max}/{first}` | List relationships with pagination | Role-based |
| `GET` | `/relationships/count` | Count total relationships | Role-based |
| `GET` | `/relationships/guid/{guid}` | List relationships where the category is the source | Role-based |
| `GET` | `/relationships/idcategory/{id}` | List relationships by category numeric ID (source) | Role-based |
| `GET` | `/relationships/idcategory/{id}/target` | List non-parent-child relationships where category is target | Role-based |
| `GET` | `/relationships/mapping/{guid}` | Retrieve relationship type mapping for a category | Role-based |
| `GET` | `/relationships/csv` | Export all relationships as CSV | Role-based |
| `GET` | `/relationships/partial/{from}` | Retrieve relationships modified after epoch timestamp | Role-based |

### Snapshots

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/snapshots/create` | Create and enqueue a full taxonomy snapshot | Role-based |
| `GET` | `/snapshots/all` | List all snapshots (without content body) | Role-based |
| `GET` | `/snapshots/{id}` | Get snapshot status by numeric ID | Role-based |
| `GET` | `/snapshots/content/{id}` | Download snapshot XML content by numeric ID | Role-based |
| `GET` | `/snapshots/validate/{uuid}` | Run content validation rules against a snapshot by UUID | Role-based |
| `GET` | `/snapshots/deploy_status/{guid}` | Get current deployment status of a snapshot by GUID | Role-based |
| `POST` | `/snapshots/deploy_test/{guid}` | Promote a snapshot to test/staging environment | Role-based |
| `POST` | `/snapshots/deploy_live/{guid}` | Activate a test-certified snapshot to live TaxonomyV2 | Role-based |
| `POST` | `/snapshots/test_certify/{guid}` | Certify a staging-deployed snapshot as production-ready | Role-based |

### Partial Snapshots

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/partialsnapshots/mappings` | Fetch taxonomy-to-snapshot mappings for all taxonomies | Role-based |
| `POST` | `/partialsnapshots/create` | Create a partial snapshot for a selected set of taxonomy GUIDs | Role-based |

### Bulk Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/bulk/{guid}` | Get status and results of a bulk job by GUID | Role-based |
| `POST` | `/bulk/edit-attributes` | Enqueue a bulk attribute update from CSV data | Role-based |
| `POST` | `/bulk/create-categories` | Enqueue a bulk category creation from CSV data | Role-based |
| `POST` | `/bulk/update-categories-and-headers` | Enqueue a bulk category + header update from CSV data | Role-based |
| `POST` | `/bulk/translations` | Enqueue a bulk locale translation update | Role-based |
| `POST` | `/bulk/relationships` | Enqueue a bulk relationship create/update from CSV data | Role-based |

### Health and Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Load-balancer health check (also `/heartbeat.txt`) | None |
| `GET` | `/status.json` | Application status and health check results | None |
| `GET` | `/git-status.json` | Git commit info for deployed build | None |
| `GET` | `/props` | Display loaded properties (used as readiness probe) | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json;charset=UTF-8` — required for all JSON POST/PUT requests
- `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` — produced by XLSX export endpoints
- `Content-Type: application/zip` — produced by CSV ZIP export endpoints

### Error format

All JSON error responses use the shape:

```json
{"error": "<error message string>"}
```

HTTP status codes used: `200` (success), `400` (bad request / validation failure), `403` (forbidden), `404` (not found), `500` (internal error).

### Pagination

The relationships list endpoint supports cursor-style range pagination via `GET /relationships/{max}/{first}`. All other list endpoints return full result sets.

## Rate Limits

> No rate limiting configured at the application layer. The CSV export endpoint enforces a concurrency limit of 2 simultaneous downloads via a `Semaphore`.

## Versioning

No explicit API version prefix is used in the deployed WAR path (context root `/`). The `web.xml` maps Jersey resources to the context root directly. Local embedded Tomcat development uses `/v1/` as the servlet mapping for ember app compatibility.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI/Swagger specification file is present in this repository.

---
service: "refresh-api-v2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [ldap-basic, role-based]
---

# API Surface

## Overview

Refresh API V2 exposes a REST API consumed primarily by the Optimus Prime UI and by Tableau Server via webhooks. All endpoints produce and consume `application/json`. The API is versioned via URL path prefix (`/api/v2/`). A legacy v1-compatibility endpoint is also present at `/ExtractAPI/extractData`. Authentication uses LDAP-backed user credentials; authorization is role-based (`USER`, `SUPER_USER`, `ADMIN`). The OpenAPI spec is maintained at `doc/swagger/swagger.yaml`.

## Endpoints

### Backward Compatibility (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/ExtractAPI/extractData` | Trigger extract refresh (v1 backward compatibility, accepts `id` and `user` query params) | Required |

### Datasources

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/datasources` | List all datasources for a given environment (`PROD`/`STAGING`) | Required |
| `GET` | `/api/v2/datasources/{datasource_id}/connections` | Retrieve data connections for a datasource | Required |
| `GET` | `/api/v2/datasources/{datasource_id}/recommendation-configs` | Get source configuration | Required |
| `POST` | `/api/v2/datasources/{datasource_id}/recommendation-configs` | Create source configuration | Required |
| `PUT` | `/api/v2/datasources/{datasource_id}/recommendation-configs` | Update source configuration | Required |
| `GET` | `/api/v2/datasources/{datasource_id}/refreshes` | List refresh jobs for a datasource | Required |
| `POST` | `/api/v2/datasources/{datasource_id}/refreshes` | Trigger a datasource refresh (optional `remote` query param) | Required |
| `GET` | `/api/v2/datasources/{datasource_id}/refreshes/{job_id}` | Retrieve a specific refresh job | Required |
| `DELETE` | `/api/v2/datasources/{datasource_id}/refreshes/{job_id}` | Cancel a running refresh job | Required |

### Projects

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/projects` | List all projects for a given environment | Required |
| `GET` | `/api/v2/projects/{project_id}/batchUsers` | List batch users for a project | Required |
| `GET` | `/api/v2/projects/{project_id}/datasources` | List datasources for a project | Required |
| `GET` | `/api/v2/projects/{project_id}/jobs` | List all jobs for a project | Required |
| `GET` | `/api/v2/projects/{project_id}/sources` | List sources for a project | Required |
| `GET` | `/api/v2/projects/{project_id}/workbooks` | List workbooks for a project | Required |

### Workbook Refreshes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/workbooks/{workbook_id}/refreshes` | List refresh jobs for a workbook | Required |
| `POST` | `/api/v2/workbooks/{workbook_id}/refreshes` | Trigger a workbook refresh | Required |
| `GET` | `/api/v2/workbooks/{workbook_id}/refreshes/{job_id}` | Retrieve a specific workbook refresh job | Required |
| `DELETE` | `/api/v2/workbooks/{workbook_id}/refreshes/{job_id}` | Cancel a running workbook refresh job | Required |

### Publish Jobs (Promotions)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/promotions` | List publish jobs (filtered by `production_source_id`) | Required |
| `POST` | `/api/v2/promotions` | Create a new publish job to promote a workbook or datasource | Required |
| `GET` | `/api/v2/promotions/{publish_id}` | Retrieve a specific publish job | Required |

### Batch Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/batchUsers` | List all project batch users | Required |
| `POST` | `/api/v2/batchUsers` | Create a project batch user | Required |
| `POST` | `/api/v2/batchUsers/testConnection` | Test a batch user connection | Required |
| `PUT` | `/api/v2/batchUsers/{project_id}` | Update a project batch user | Required |
| `DELETE` | `/api/v2/batchUsers/{project_id}` | Delete a project batch user | Required |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/users` | Search users from LDAP or DB | Required |
| `GET` | `/api/v2/users/{userName}/role` | Retrieve role of a specific user | Required |
| `PUT` | `/api/v2/users/{userName}/role` | Update a user's role (`USER`, `SUPER_USER`, `ADMIN`) | Required (ADMIN) |
| `GET` | `/api/v2/usersByRole` | List users filtered by role | Required |

### User License Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/v2/licenses/cleanup` | Change Tableau viewer licenses to unlicensed based on threshold | Required (ADMIN) |

### Subscriptions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/subscriptions` | List subscriptions | Required |
| `POST` | `/api/v2/subscriptions` | Create a subscription | Required |
| `PUT` | `/api/v2/subscriptions/{subscription_id}` | Update a subscription | Required |
| `DELETE` | `/api/v2/subscriptions/{subscription_id}` | Delete a subscription | Required |

### Views

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v2/views` | List views for a given environment | Required |

### Webhook Events

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/v2/events/tableau` | Receive Tableau server webhook events | None (internal network) |
| `POST` | `/api/v2/events/analytics` | Receive Analytics environment webhook events | None (internal network) |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json`
- `Accept: application/json`
- `X-Forwarded-For` — optional, accepted on publish job creation

### Error format
Standard Dropwizard error response body for validation and HTTP errors:
```json
{ "code": 400, "message": "..." }
```
Custom response wrappers used: `SuccessResponseWrapper`, `MessageResponseWrapper`, `ResourceNotFoundResponseWrapper`.

### Pagination
Some list endpoints accept a `limit` query parameter (defaults vary: `5` for refresh jobs, `7` for users and publish jobs). Full cursor-based pagination is not implemented.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning: `/api/v2/` prefix for all current endpoints. The legacy `/ExtractAPI/extractData` path is retained for v1 backward compatibility.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`
Swagger UI config: `doc/swagger/config.yml`

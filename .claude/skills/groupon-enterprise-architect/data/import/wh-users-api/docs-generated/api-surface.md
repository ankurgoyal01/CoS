---
service: "wh-users-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

The wh-users-api exposes a REST API under the `/wh/v2/` path prefix. It provides full CRUD operations for three entity types: users, groups, and resources. All requests and responses use `application/json`. The API is versioned via the URL path (`v2`). A live Swagger UI is available in each deployed environment.

## Endpoints

### Group Resource

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/group` | List groups (paginated) | Not configured |
| POST | `/wh/v2/group` | Create a new group | Not configured |
| GET | `/wh/v2/group/{uuid}` | Retrieve a group by UUID | Not configured |
| PUT | `/wh/v2/group/{uuid}` | Update a group by UUID | Not configured |
| DELETE | `/wh/v2/group/{uuid}` | Delete a group by UUID | Not configured |

### Resource Resource

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/resource` | List resources (paginated) | Not configured |
| POST | `/wh/v2/resource` | Create a new resource | Not configured |
| GET | `/wh/v2/resource/{uuid}` | Retrieve a resource by UUID | Not configured |
| PUT | `/wh/v2/resource/{uuid}` | Update a resource by UUID | Not configured |
| DELETE | `/wh/v2/resource/{uuid}` | Delete a resource by UUID | Not configured |

### User Resource

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/wh/v2/user` | Find users by filter parameters (paginated) | Not configured |
| POST | `/wh/v2/user` | Create a new user | Not configured |
| GET | `/wh/v2/user/{uuid}` | Retrieve a user by UUID | Not configured |
| PUT | `/wh/v2/user/{uuid}` | Update a user by UUID | Not configured |
| DELETE | `/wh/v2/user/{uuid}` | Delete a user by UUID | Not configured |
| GET | `/wh/v2/user/username/{username}` | Retrieve a user by username (optionally filtered by `platform` query param) | Not configured |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST and PUT requests
- `Accept: application/json` — expected for all responses

### Error format

All error responses follow the Dropwizard `ErrorMessage` schema:

```json
{
  "code": 400,
  "message": "string",
  "details": "string"
}
```

HTTP status codes in use:

| Status | Meaning |
|--------|---------|
| 200 | Success (GET, POST, PUT) |
| 204 | Success — no content (DELETE) |
| 400 | Validation failure — invalid entity body |
| 404 | Entity not found for the provided UUID or username |
| 409 | Conflict — entity with the provided UUID already exists |
| 422 | Unprocessable — entity could not be created or updated |
| 500 | Internal server error |

### Pagination

List endpoints (`GET /wh/v2/group`, `GET /wh/v2/resource`, `GET /wh/v2/user`) support offset-based pagination via query parameters:

| Parameter | Type | Default | Constraints |
|-----------|------|---------|-------------|
| `skip` | integer | 0 | minimum: 0 |
| `limit` | integer | 20 | minimum: 1, maximum: 1000 |

List responses include a `count` field (total matching records) and an `items` array.

### User search filters

`GET /wh/v2/user` supports additional query parameters:

| Parameter | Type | Purpose |
|-----------|------|---------|
| `username` | string | Filter by username |
| `locale` | string | Filter by locale |
| `group_id` | uuid | Filter by group membership |
| `sort_field` | enum (`CREATED_AT`, `UPDATED_AT`, `USERNAME`) | Sort dimension |
| `sort_order` | enum (`ASC`, `DESC`) | Sort direction |

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning. All endpoints are served under the `/wh/v2/` prefix. No header- or query-parameter-based versioning is used.

## OpenAPI / Schema References

The OpenAPI 2.0 (Swagger) specification is located at `doc/swagger/swagger.yaml` in the repository.

Live Swagger UI is available per environment:

| Environment | Region | Swagger UI |
|-------------|--------|-----------|
| Staging | europe-west1 | `https://wh-users-api.staging.service.europe-west1.gcp.groupondev.com/swagger/` |
| Staging | us-central1 | `https://wh-users-api.staging.service.us-central1.gcp.groupondev.com/swagger/` |
| Production | eu-west-1 | `https://wh-users-api.production.service.eu-west-1.aws.groupondev.com/swagger/` |
| Production | europe-west1 | `https://wh-users-api.production.service.europe-west1.gcp.groupondev.com/swagger/` |
| Production | us-central1 | `https://wh-users-api.production.service.us-central1.gcp.groupondev.com/swagger/` |

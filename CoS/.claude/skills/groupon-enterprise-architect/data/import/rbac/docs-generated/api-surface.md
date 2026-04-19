---
service: "rbac"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [header-user-id, internal-permission-check]
---

# API Surface

## Overview

The RBAC service exposes a versioned REST API (all paths under `/v2/`). Callers identify themselves via the `requester_user_id` HTTP header (a UUID), which the service uses to perform internal authorization checks against the stored RBAC data. There is no external OAuth or JWT verification — authorization is enforced by the service itself using the `@RequiredPermission` AOP aspect and `AuthorizationUtil`. The API is consumed exclusively by internal Groupon services and tooling.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Liveness health check; returns `"OK"` | None |

### Roles

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/roles` | List roles with optional filters (categoryIds, permissionIds, createdBy, roleName, dateRange, show=deleted) — paginated | `requester_user_id` header |
| GET | `/v2/roles/{roleId}` | Get a single role by ID; supports `?show=minimal` for reduced payload | `requester_user_id` header |
| POST | `/v2/roles` | Create a new role | `RBAC:ROLE:CREATE` permission |
| PATCH | `/v2/roles/{roleId}` | Update an existing role | `RBAC:ROLE:UPDATE` permission |
| DELETE | `/v2/roles/{roleId}` | Soft-delete a role | `RBAC:ROLE:DELETE` permission |
| DELETE | `/v2/roles/{roleId}/categories/{categoryId}` | Remove a category from a role | `RBAC:ROLE_CATEGORY:DELETE` permission |
| DELETE | `/v2/roles/{roleId}/permissions/{permissionId}` | Remove a permission from a role | `RBAC:ROLE_PERMISSION:DELETE` permission |

### Permissions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/permissions` | List permissions with optional filters (categoryIds, createdBy, permissionCode, dateRange, show=deleted) — paginated | `RBAC:PERMISSION:CREATE` (internal check) |
| GET | `/v2/permissions/{permissionId}` | Get a single permission by ID | `requester_user_id` header |
| POST | `/v2/permissions` | Create a new permission | `RBAC:PERMISSION:CREATE` permission |
| PATCH | `/v2/permissions/{permissionId}` | Update an existing permission | `requester_user_id` header |
| DELETE | `/v2/permissions/{permissionId}` | Soft-delete a permission | `RBAC:PERMISSION:DELETE` permission |
| DELETE | `/v2/permissions/{permissionId}/categories/{categoryId}` | Remove a category from a permission | `requester_user_id` header |

### Categories

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/categories` | List all categories (with optional createdBy, dateRange filters) | `requester_user_id` header |
| GET | `/v2/categories/{categoryId}` | Get a single category by ID | `RBAC:CATEGORY:READ` permission |
| POST | `/v2/categories` | Create a new category | `RBAC:CATEGORY:CREATE` permission |
| PATCH | `/v2/categories/{categoryId}` | Update category description | `RBAC:CATEGORY:UPDATE` permission |
| DELETE | `/v2/categories/{categoryId}` | Remove a category | `RBAC:CATEGORY:DELETE` permission |

### Scope Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/scope_types` | List all scope types | `requester_user_id` header |
| GET | `/v2/scope_types/{scopeType}` | Get a specific scope type by name | `requester_user_id` header |
| POST | `/v2/scope_types` | Create a new scope type | `RBAC:SCOPE_TYPE:CREATE` permission |
| PATCH | `/v2/scope_types/{scopeType}` | Update scope type description | `RBAC:SCOPE_TYPE:UPDATE` permission |

### User Roles

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/users/roles` | List user-role assignments with optional filters — paginated | `RBAC:USER_ROLE:READ` or self-lookup or role owner |
| GET | `/v2/users/{userId}/permissions` | List all roles and permissions for a user in a given scope | `requester_user_id` header |
| GET | `/v2/users/{userId}/permissions/check` | Check if a user holds a specific permission in a given scope | `requester_user_id` header |
| POST | `/v2/users/{userId}/roles` | Assign one or more roles to a user (with scope) | `RBAC:ROLE_ASSIGNMENT:CREATE` or role owner |
| DELETE | `/v2/users/{userId}/roles/{roleId}/{scopeType}` | Remove a role from a user (with optional scopeValue) | `RBAC:ROLE_ASSIGNMENT:DELETE` or role owner |

### Role Ownership

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/roles/owners` | List role ownership records (filter by roleIds, ownerIds, dateRange, createdBy) | `requester_user_id` header |
| GET | `/v2/roles/{roleId}/owners/{ownerId}` | Get a specific role-owner relationship | `requester_user_id` header |
| POST | `/v2/roles/owners` | Assign an owner to a role | `RBAC:ROLE_ASSIGNMENT:CREATE` permission |
| DELETE | `/v2/roles/{roleId}/owners/{ownerId}` | Remove an owner from a role | `RBAC:ROLE_ASSIGNMENT:DELETE` permission |

### Role Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/roles/requests` | List role requests (filter by requesterId, roleId, roleOwnerId, status) — paginated | Requester self, role owner, or `RBAC:ROLE_REQUEST:LIST` |
| POST | `/v2/roles/requests` | Submit a role access request | `requester_user_id` header |
| PUT | `/v2/roles/requests/{requestId}` | Approve, reject, or cancel a role request | Role owner / admin or requester (cancel only) |

### Audit Log

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/audit` | Query audit log (filter by roleId, permissionId, userId, affectedUserId, type, dateRange, region) — paginated | `RBAC:AUDIT:READ` permission (or role owner for USERS_ROLES_ASSIGNMENTS) |

### Salesforce Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/v2/salesforce/profile` | Trigger role assignment from a Salesforce user profile (NA only; returns 501 for EMEA) | `RBAC:SF_ROLE_ASSIGNMENT:CREATE` permission |

## Request/Response Patterns

### Common headers

- `requester_user_id` (UUID, required on most endpoints): identifies the acting user for authorization checks
- `Content-Type: application/json` (required on POST/PUT/PATCH requests)
- `X-API-KEY` (internal, used by the Users Service client for outbound calls)
- `X-HB-Region` (internal, used for cross-region Users Service calls)

### Error format

> No evidence found in codebase of a standardized error envelope. Errors are thrown as `CustomException` with an HTTP status and message string; Spring Boot returns the default error response shape.

### Pagination

All list endpoints that return large collections use Spring Data `Pageable` convention. Query parameters: `page` (0-based), `size`, `sort`. Responses are wrapped in the `Paginated<T>` envelope containing the page content and total element count.

## Rate Limits

> No rate limiting is configured on inbound API endpoints. The outbound Users Service client applies a Guava `RateLimiter` (configured via `external-clients.usersService.rateLimitPerSecond` and `crossRegionRateLimitPerSecond` in application config).

## Versioning

All endpoints are prefixed with `/v2/`. No `v1` endpoints exist in the codebase; `v2` is the current and only active version.

## OpenAPI / Schema References

> No evidence found in codebase of an OpenAPI spec or Swagger configuration. Request/response shapes are defined by the DTO classes in `src/main/java/com/groupon/access/api/dto/`.

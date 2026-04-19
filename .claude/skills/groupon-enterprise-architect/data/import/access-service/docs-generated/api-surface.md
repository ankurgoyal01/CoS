---
service: "mx-merchant-access"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, basic-auth]
---

# API Surface

## Overview

The Merchant Access Service exposes a REST API under the `/v1` path prefix. All endpoints require the `X_API_KEY` header for authentication. The `future_contact` index endpoint additionally requires HTTP Basic Auth (`Authorization` header). All mutating operations accept `audit_user_id` and `audit_user_type` query parameters for audit trail tracking. The API is documented internally via the service-portal, generated from JSON descriptor files in `access-webapp/doc/endpoints/`.

## Endpoints

### Contact Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/contact` | Create a new merchant contact and grant initial rights | API key |
| `GET` | `/v1/contact` | List merchant contacts by `account_uuid` and/or `merchant_uuid` | API key |
| `GET` | `/v1/contact/{account_uuid}/{merchant_uuid}` | Get a specific contact by account UUID and merchant UUID | API key |
| `DELETE` | `/v1/contact/{account_uuid}/{merchant_uuid}` | Delete a merchant contact and revoke all merchant rights | API key |

### Access / Role Assignment

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/contact/{account_uuid}/{merchant_uuid}/application/{application_name}/access` | Assign or update the role of a contact for a specific application | API key |

### Notification Group

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PATCH` | `/v1/contact/{account_uuid}/{merchant_uuid}/notification_group` | Enable or disable a notification group for a merchant contact | API key |

### Primary Contact

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/merchant/{merchant_identifier}/primary_contact` | Get the primary contact for a merchant | API key |
| `PUT` | `/v1/merchant/{merchant_identifier}/primary_contact` | Set or change the primary contact for a merchant | API key |

### Role Catalog

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/role` | List all roles, applications, and access rights defined in MAS | API key |

### Future Contacts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/future_contact` | Create a future contact (invited user not yet registered) | API key |
| `GET` | `/v1/future_contact` | List future contacts for a merchant (by `merchant_uuid`) | Basic Auth + API key |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/health` | Service health status (used by service-portal) | None |
| `GET` | `/ping` | Kubernetes readiness and liveness probe | None |

## Request/Response Patterns

### Common headers

- `X_API_KEY` (header, required): API key for all endpoints. Contact the MX team to obtain one.
- `Authorization` (header, Basic Auth): Required only for `GET /v1/future_contact`.
- `audit_user_id` (query, required on writes): ID of the user performing the operation, for auditing.
- `audit_user_type` (query, required on writes): Type of the user performing the operation, for auditing.

### Error format

Error responses follow the standard MX commons error format. The service documents known client-error codes per endpoint (e.g., contact creation errors, access creation/update errors, contact deletion errors) in the internal service wiki.

### Pagination

> No evidence found in codebase for pagination on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are versioned under the `/v1` URL path prefix. No additional versioning mechanism is used.

## OpenAPI / Schema References

- Internal service-portal schema: `doc/service_discovery/resources.json` (generated from `access-webapp/doc/endpoints/*.json` during Maven build)
- Swagger spec: `doc/swagger/swagger.json`
- Service portal: `https://service-portal-staging.groupondev.com/services/mx-merchant-access`

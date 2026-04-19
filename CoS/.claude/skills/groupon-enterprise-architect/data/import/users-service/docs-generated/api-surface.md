---
service: "users-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt, oauth2, api-key]
---

# API Surface

## Overview

Users Service exposes a versioned REST API over HTTPS. All account and identity operations are grouped under `/v1/`. Callers are web and mobile clients authenticating users, as well as internal Continuum services triggering GDPR erasure and account management operations. The API issues and validates JWT-style tokens for session continuity and 2FA enforcement.

## Endpoints

### Accounts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/accounts` | Look up one or more accounts by identifier | API key / internal |
| POST | `/v1/accounts` | Create a new account (registration) | None (public) |
| GET | `/v1/accounts/:id` | Retrieve account by ID | JWT token |
| PUT | `/v1/accounts/:id` | Update account attributes | JWT token |
| DELETE | `/v1/accounts/:id` | Deactivate account | JWT token / internal |
| POST | `/v1/accounts/:id/2fa` | Enroll account in two-factor authentication | JWT token |

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/authentication` | Authenticate via password, OTP, or social OAuth (Google / Facebook / Apple) and receive session token | None (credentials in body) |

### Email Verifications

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/email_verifications` | Initiate email verification (sends nonce via email) | JWT token |
| PUT | `/v1/email_verifications/:nonce` | Complete email verification using nonce | Nonce |

### Password Resets

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/password_resets` | Initiate self-service password reset (sends email) | None |
| PUT | `/v1/password_resets/:token` | Complete password reset using reset token | Reset token |

### GDPR Erasure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/erasure` | Trigger GDPR erasure for an account | Internal / service credential |

### Third-Party Links

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/third_party_links` | List external identity links for an account | JWT token |
| POST | `/v1/third_party_links` | Link an external identity (Google / Facebook / Apple) to an account | JWT token |
| DELETE | `/v1/third_party_links/:id` | Unlink an external identity | JWT token |
| POST | `/v1/third_party_links/sync` | Synchronize external identity attributes | JWT token |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all requests with a body
- `Accept: application/json` — expected on all requests
- `Authorization: Bearer <token>` — JWT token for authenticated endpoints

### Error format

Errors are returned as JSON with an `error` key and a human-readable `message`. HTTP status codes follow REST conventions: `400` for validation errors, `401` for authentication failures, `403` for authorization failures, `404` for missing resources, `422` for unprocessable entity, `500` for internal errors.

### Pagination

> No evidence found of a standardized pagination pattern. Collection endpoints such as `GET /v1/accounts` accept query parameters for filtering by identifier.

## Rate Limits

> No rate limiting configuration discoverable from the architecture inventory. Rate limiting may be enforced upstream (Akamai / API gateway).

## Versioning

All endpoints are prefixed with `/v1/`. The GDPR erasure endpoint (`/erasure`) is unversioned. Version is communicated via URL path prefix.

## OpenAPI / Schema References

> No OpenAPI spec or schema file discovered in the architecture inventory. Consult the users-service repository directly for any contract files.

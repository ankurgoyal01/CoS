---
service: "file-sharing-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [user-uuid, oauth2]
---

# API Surface

## Overview

File Sharing Service exposes a REST API over HTTP. Consumers identify themselves by passing a `user-uuid` parameter (query param, multipart field, form field, or header) that maps to a registered user record holding valid Google OAuth2 tokens. The service also supports system/service-account uploads without a `user-uuid`. All responses are JSON. Binary file downloads return the raw file content stream with appropriate `Content-Type` and `Filename` headers.

The Swagger specification is located at `doc/swagger/swagger.json`. The service discovery resource descriptor is at `doc/service_discovery/resources.json` and `public/resources.json`.

## Endpoints

### Files

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/files` | Upload file content; persists locally and saves blob to MySQL `file_contents` (does not upload to Google Drive) | `user-uuid` (optional) |
| `POST` | `/files/upload` | Upload file locally and immediately forward to Google Drive; returns `file-uuid` | `user-uuid` (optional) |
| `POST` | `/files/share` | Share an already-uploaded file on Google Drive with one or more email addresses | `file-uuid` in body |
| `GET` | `/files/{fileUuid}` | Retrieve a file — returns Google Drive metadata if externally stored, raw binary content if stored in MySQL, or error if cleared | None |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/users/auth-url` | Returns the Google OAuth2 authorization URL for initiating user registration | None |
| `POST` | `/users/register` | Exchange a Google OAuth2 authorization code for tokens; creates a user record; returns `uuid` | None |

### Tasks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/tasks/start` | Start or restart the cronj scheduled task scheduler | None |
| `GET` | `/tasks/status` | Return current scheduler status (running, uptime, task list) | None |
| `GET` | `/tasks/stop` | Stop the scheduled task scheduler | None |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Kubernetes readiness/liveness health check; returns HTTP 200 with empty JSON body | None |

## Request/Response Patterns

### Common headers

- `user-uuid` — can be passed as an HTTP header, query param, multipart field, or form field; the handler checks all four locations in order
- `Content-Type: application/json` — required for JSON body endpoints (`/files/share`, `/users/register`)
- `Content-Type: multipart/form-data` — required for file upload endpoints (`/files`, `/files/upload`)

### Error format

Errors are returned as JSON with an `error` key:

```json
{ "error": "Token was previously used or invalid." }
```

HTTP status codes used:
- `400` — invalid token, duplicate user, or bad request parameters
- `404` — file not found in MySQL or Google Drive
- `410` — file content has been cleared (blob deleted)
- `500` — internal JSON generation error

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning. The API is unversioned. The Swagger spec field `"version": ""` confirms this.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.json`
- Service discovery descriptor: `doc/service_discovery/resources.json`, `public/resources.json`
- Host (production): `file-sharing-service.production.service`

---
service: "calcom"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [https, rest]
auth_mechanisms: [session, nextauth, 2fa]
---

# API Surface

## Overview

Calcom is a wrapper around the upstream Cal.com open-source product. The API surface is provided entirely by the Cal.com application running inside the `continuumCalcomService` container. Consumers access the service via HTTPS through the public domain `https://meet.groupon.com` (production) or the internal hybrid boundary domain `https://calcom.staging.service.us-west-1.aws.groupondev.com` (staging). Groupon does not own or extend the API specification — it is defined and versioned by the upstream Cal.com project.

## Endpoints

### Public Web Interface

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Landing page and scheduling home | None |
| GET | `/:username` | User's public booking page | None |
| GET | `/:username/:eventType` | Specific event type booking page | None |
| POST | `/api/book/event` | Submit a booking request | Session / None (public) |
| GET | `/api/availability` | Query user availability slots | Session |

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/auth/login` | Login page | None |
| POST | `/auth/login` | Submit login credentials | None |
| GET | `/auth/logout` | Log out and invalidate session | Session |

### Admin Interface

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/settings/admin` | Admin settings panel | Session + Admin role + 2FA |

### API v2

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `*` | `/api/v2/*` | Cal.com v2 REST API (base URL: `NEXT_PUBLIC_API_V2_URL`) | Session / API key |

> Endpoint paths above are derived from the Cal.com open-source product standard routes. Groupon does not maintain a custom OpenAPI spec. For the full API reference see the upstream Cal.com documentation at https://cal.com/docs.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON API requests
- `Cookie` header carries the NextAuth.js session token for authenticated requests

### Error format

> No evidence found in codebase. Error format follows Cal.com upstream conventions (standard HTTP status codes with JSON error body).

### Pagination

> No evidence found in codebase. Pagination follows Cal.com upstream conventions.

## Rate Limits

> No rate limiting configured at the Groupon deployment layer. The `ALLOWED_HOSTNAMES` environment variable restricts which hostnames are permitted to interact with the service.

## Versioning

The public URL uses `NEXT_PUBLIC_API_V2_URL` pointing to `https://meet.groupon.com` for the Cal.com v2 API surface. URL path versioning (`/api/v2/`) is used by the upstream Cal.com project.

## OpenAPI / Schema References

> No Groupon-owned OpenAPI spec or schema files found in the repository. The upstream Cal.com API specification is available at the [Cal.com developer documentation](https://cal.com/docs/api-reference).

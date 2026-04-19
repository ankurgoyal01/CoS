---
service: "garvis"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, webhook]
auth_mechanisms: [session, google-oauth]
---

# API Surface

## Overview

Garvis exposes a small set of HTTP endpoints served by the `continuumJarvisWebApp` Django container via Gunicorn. The surface is divided into operational/health endpoints, the Django admin UI, the RQ monitoring dashboard, and the Google Chat webhook ingress. Google Chat delivers bot events by calling the webhook endpoint; all other HTTP endpoints are for operators and monitoring systems.

## Endpoints

### Health and Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Standard Groupon liveness/readiness health check | None |

### Admin and Monitoring

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / POST | `/admin/` | Django admin interface for operators to inspect and manage application data | Django session (staff login) |
| GET / POST | `/django-rq/` | RQ dashboard for monitoring job queues, workers, and failed jobs | Django session (staff login) |

### Application Root

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Home / landing page for the Garvis web interface | Django session |

### Google Chat Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/` (or configured webhook path) | Receives Google Chat event payloads delivered by Google's infrastructure; entry point for all bot interactions | Google-signed JWT / bearer token |

> Note: The exact webhook path for Google Chat event delivery is configured in the Google Chat API console and mapped through Django URL routing via `webHttpControllers`.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for webhook POST requests from Google Chat
- Django CSRF tokens are required for browser-originated POST requests to admin endpoints

### Error format

> No evidence found of a custom error response schema. Django default error responses (HTML for browser requests, JSON for API clients) apply.

### Pagination

> Not applicable for the current endpoint surface.

## Rate Limits

> No rate limiting configured at the application layer. Google Chat API quotas apply to outbound calls made by `continuumJarvisBot`.

## Versioning

No API versioning strategy is applied. The `/grpn/healthcheck` path follows the Groupon platform convention for health probes.

## OpenAPI / Schema References

> No evidence found of an OpenAPI specification or schema file in this service's architecture definition.

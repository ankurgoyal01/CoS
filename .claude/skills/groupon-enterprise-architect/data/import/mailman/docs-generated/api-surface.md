---
service: "mailman"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [spring-security]
---

# API Surface

## Overview

Mailman exposes a REST API for transactional email submission, duplicate checking, retry operations, context management, and client registration. All business endpoints are prefixed with `/mailman/`. A management endpoint at `/manage/info` is provided by Spring Boot Actuator for health and service information. The API is consumed by internal Continuum services and operators. Contract documentation is available via SpringFox Swagger 2.6.1.

## Endpoints

### Mail Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/mailman/mail` | Submit a new transactional email request for orchestration and delivery | Spring Security |
| POST | `/mailman/duplicate-check` | Check whether an equivalent request has already been processed (deduplication) | Spring Security |
| POST | `/mailman/retry` | Manually trigger retry of a previously failed email request | Spring Security |

### Context and Client Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/mailman/context` | Register or update contextual metadata associated with a mail request | Spring Security |
| POST | `/mailman/client` | Register or update a mail client definition | Spring Security |

### Management / Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/manage/info` | Returns service health, build info, and operational metadata | Internal / Actuator |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all POST request bodies are JSON
- `Accept: application/json` — all responses are JSON

### Error format

> No evidence found in inventory. Standard Spring Boot error response structure is expected (`timestamp`, `status`, `error`, `message`, `path`).

### Pagination

> Not applicable — endpoints operate on individual requests, not paginated collections.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning is present in the discovered endpoint paths. All endpoints are unversioned under the `/mailman/` prefix.

## OpenAPI / Schema References

SpringFox Swagger 2.6.1 is included as a dependency. Swagger UI is expected to be available at `/swagger-ui.html` when the service is running. No static OpenAPI spec file is committed to this repository.

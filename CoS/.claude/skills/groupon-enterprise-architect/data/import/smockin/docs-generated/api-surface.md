---
service: "smockin"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "websocket"]
auth_mechanisms: ["jwt"]
---

# API Surface

## Overview

sMockin exposes two distinct HTTP surfaces on separate ports. The **Admin API** (port 8000) is a Spring MVC REST API used by the AngularJS UI and any automation tooling to manage users, projects, mock definitions, server lifecycle, import/export, and key/value data. The **Mock Server** (port 8001) is a Spark-based HTTP server that responds to client requests using the stored mock definitions — this is what services under test call. All admin API endpoints accept and return `application/json` unless otherwise noted. Authentication uses a JWT bearer token obtained from `POST /auth`.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/auth` | Authenticate with username/password; returns JWT token | None |
| `POST` | `/logout` | Invalidates the current session token | JWT |

### REST Mock Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/restmock` | List all REST mock endpoints | JWT (optional) |
| `GET` | `/restmock/{extId}` | Get a specific REST mock endpoint by external ID | JWT (optional) |
| `POST` | `/restmock` | Create a new REST mock endpoint | JWT (optional) |
| `PUT` | `/restmock/{extId}` | Update an existing REST mock endpoint | JWT (optional) |
| `DELETE` | `/restmock/{extId}` | Delete a REST mock endpoint | JWT (optional) |

### Mock Server Engine Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/mockedserver/rest/start` | Start the REST mock server | JWT (optional) |
| `POST` | `/mockedserver/rest/stop` | Stop the REST mock server | JWT (optional) |
| `POST` | `/mockedserver/rest/restart` | Restart the REST mock server | JWT (optional) |
| `GET` | `/mockedserver/rest/status` | Get current REST mock server state | None |
| `GET` | `/mockedserver/config/{serverType}` | Retrieve mock server configuration for a given server type | None |
| `PUT` | `/mockedserver/config/{serverType}` | Update mock server configuration for a given server type | JWT (optional) |

### API Definition Import

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/{type}/import` | Import mock definitions from an API spec file (RAML or OpenAPI); `{type}` specifies format | JWT (optional) |

### Mock Definition Import / Export

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/mock/import` | Import mock definitions from a ZIP archive | JWT (optional) |
| `POST` | `/mock/export/{serverType}` | Export selected mock definitions as a ZIP archive | JWT (optional) |

### HTTP Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/proxy/{extId}` | Add a proxied response entry for a mock endpoint | JWT (optional) |
| `PATCH` | `/proxy/{extId}/clear` | Clear the proxy response session for a mock endpoint | JWT (optional) |

### Stateful REST

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/stateful/{extId}/clear` | Reset the cached JSON state for a stateful mock endpoint | JWT (optional) |

### Project Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/project` | List all projects | JWT (optional) |
| `POST` | `/project` | Create a new project | JWT (optional) |
| `PUT` | `/project/{extId}` | Update a project | JWT (optional) |
| `DELETE` | `/project/{extId}` | Delete a project | JWT (optional) |

### User Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/user` | List all users | JWT |
| `GET` | `/user/mode` | Get current user mode (single/multi) | None |
| `POST` | `/user` | Create a new user | JWT |
| `PUT` | `/user/{extId}` | Update a user | JWT |
| `DELETE` | `/user/{extId}` | Delete a user | JWT |
| `PATCH` | `/user/password` | Change the authenticated user's password | JWT |
| `GET` | `/user/{extId}/password/reset` | Issue a password reset token for a user | JWT |
| `GET` | `/password/reset/token/{token}` | Validate a password reset token | None |
| `POST` | `/password/reset/token/{token}` | Apply a new password using a reset token | None |

### Key / Value Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/keyvaluedata` | List all key/value pairs | JWT (optional) |
| `GET` | `/keyvaluedata/{extId}` | Get a specific key/value pair | JWT (optional) |
| `POST` | `/keyvaluedata` | Create one or more key/value pairs | JWT (optional) |
| `PUT` | `/keyvaluedata/{extId}` | Update a key/value pair | JWT (optional) |
| `DELETE` | `/keyvaluedata/{extId}` | Delete a key/value pair | JWT (optional) |

### HTTP Client (Test Utility)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/httpclientcall` | Make a test HTTP call through the admin UI's built-in client | None |

### WebSocket Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/ws/{id}/client` | List active WebSocket client connections for a mock endpoint | JWT (optional) |
| `POST` | `/ws/{id}` | Push a message to a connected WebSocket client | None |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <token>` — JWT token obtained from `POST /auth`. Required on most admin endpoints; optional in single-user mode.
- `Keep-Existing: true|false` — Required on import endpoints (`/mock/import`, `/api/{type}/import`). When `true`, conflicting mock names are renamed rather than overwritten.
- `Content-Type: application/json` — Required for all JSON request bodies.
- `Content-Type: multipart/form-data` — Required for file upload endpoints.

### Error format

> No evidence found in codebase for a standardised error response envelope. Errors are surfaced via standard Spring Boot exception handling through `ExceptionHandlerController`.

### Pagination

> No evidence found in codebase. All list endpoints return full arrays.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning is applied. All endpoints are served without a version prefix. The application version is tracked via `app.version` system property and `release.properties`.

## OpenAPI / Schema References

> No OpenAPI specification file is published by this service. RAML and OpenAPI files are consumed as inputs to the import flow, not produced by sMockin itself.

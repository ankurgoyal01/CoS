---
service: "releasegen"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-only]
---

# API Surface

## Overview

Releasegen exposes a REST API over HTTP (port 8080) using JAX-RS via Dropwizard/Jersey. The API is internal-only; it is not exposed on the public internet. It provides endpoints for querying Deploybot deployment records, triggering deployment publication (release creation), querying JIRA release tickets, managing the background polling worker lifecycle, and an HTML admin UI for manual reprocessing.

## Endpoints

### Admin UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Renders the HTML admin dashboard showing deployment stats | Internal |
| `GET` | `/list/{org}/{repo}` | Lists deployment records for a given GitHub org/repo with optional environment and region filters; returns HTML | Internal |

### Deploybot

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/deploybot/{org}/{project}/{id}` | Looks up a specific Deploybot deployment record by org, project, and ID; returns `DeploymentId` JSON | Internal |

### Deployment Publication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/deployment/{org}/{repo}/{id}` | Triggers full release/deployment-status publication for a given Deploybot deployment ID; returns `DeploymentStatusInfo` JSON | Internal |

### JIRA

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/jira/releases` | Returns a list of JIRA release issue records; optionally filtered with `?since=<ISO-8601>` | Internal |

### Worker Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/worker` | Starts the background deployment polling worker | Internal |
| `DELETE` | `/worker` | Stops the background deployment polling worker | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON endpoints
- `Accept: text/html` for admin UI endpoints (rendered via Mustache)

### Error format

User errors map to HTTP 4xx responses. The `UserErrorExceptionMapper` converts `UserError` exceptions into JSON bodies. System errors result in standard Dropwizard 500 responses.

### Pagination

The `/list/{org}/{repo}` admin UI endpoint supports `start` (int32, zero-based offset) and `limit` (int32) query parameters for paginated browsing of deployment records.

## Rate Limits

> No rate limiting configured on the Releasegen API itself. Downstream GitHub and JIRA API calls are subject to those systems' own rate limits.

## Versioning

No API versioning strategy is applied. The API surface is internal and versioned via service deployment.

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`

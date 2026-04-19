---
service: "argus"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [bearer-token, x-auth-token]
---

# API Surface

## Overview

Argus does not expose an inbound API. It is a batch CLI tool that acts exclusively as an **API client** of the Wavefront REST API at `https://groupon.wavefront.com`. The following documents the outbound API calls Argus makes to Wavefront.

## Wavefront API Calls (Outbound)

### Alert Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/v2/search/alert` | Search for an existing alert by exact name match | Bearer token (`Authorization: Bearer <token>`) |
| `POST` | `/api/v2/alert` | Create a new alert when no match is found | Bearer token |
| `PUT` | `/api/v2/alert/:id` | Update an existing alert when the definition has changed | Bearer token |

### Dashboard Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/dashboard` | Create or replace a Wavefront dashboard payload | `X-AUTH-TOKEN` header |

### Metrics Query

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/chart/api` | Query live Wavefront metric time series for dashboard chart assembly | `X-AUTH-TOKEN` header |
| `GET` | `/chart/api` | Query `flapping(1w, -1*ts(~alert.isfiring.<alertId>))` for alert summary reporting | `X-AUTH-TOKEN` header |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <token>` — used for alert CRUD operations (`/api/v2/alert`, `/api/v2/search/alert`)
- `X-AUTH-TOKEN: <token>` — used for dashboard and chart API operations (`/api/dashboard`, `/chart/api`)
- `Accept: application/json` — set on all alert operations

### Alert search request body

```json
{
  "query": [
    { "key": "name", "value": "<alert-name>", "matchingMethod": "EXACT" }
  ]
}
```

### Alert create/update body fields

| Field | Description |
|-------|-------------|
| `name` | Fully prefixed alert name, e.g. `DUB1 SMA Lazlo /deals GET response 5XX error percentage` |
| `condition` | Rendered Wavefront TS query expression |
| `displayExpression` | Rendered display query using `collect(...)` wrapper |
| `minutes` | Minutes the condition must be true before firing (`minutesToFire`) |
| `severity` | `WARN` or `SEVERE` |
| `target` | Comma-separated Wavefront webhook IDs, e.g. `webhook:UXcN0ynhr2fq7OYm,...` |
| `tags.customerTags` | Array of tag strings, e.g. `["argus.prod.dub1.sma.api_lazlo"]` |
| `resolveAfterMinutes` | Optional — minutes to wait before auto-resolving |
| `id` | Populated only on update (PUT) |

### Change detection

Before updating an alert, Argus compares the following fields between the new definition and the existing Wavefront alert: `name`, `condition`, `minutes`, `target`, `severity`, `tags`, `displayExpression`, `resolveAfterMinutes`. An update is only issued if at least one field differs.

### Error format

Errors are logged to standard output in the form:
```
Failure: create failed <HTTP_STATUS>
Request body: <response-body>
```

No structured error envelope is enforced — Argus exits non-zero on unhandled exceptions.

### Pagination

> No evidence found in codebase. Alert search returns all matching items in a single response; Argus throws an exception if more than one alert matches a name.

## Rate Limits

> No rate limiting configured on Argus's outbound calls. Wavefront API rate limits apply server-side.

## Versioning

Argus targets the Wavefront v2 alert API (`/api/v2/alert`) and the unversioned dashboard API (`/api/dashboard`). No versioning strategy is applied to Argus itself — it is a CLI tool released via Gradle tasks.

## OpenAPI / Schema References

> No evidence found in codebase. Wavefront API schema is external to this repository.

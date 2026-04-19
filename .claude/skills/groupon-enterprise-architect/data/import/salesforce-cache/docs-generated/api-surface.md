---
service: "salesforce-cache"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [basic-auth]
---

# API Surface

## Overview

The Salesforce Cache API (`salesforceCacheApi`) exposes a read-only REST interface at the `/v0` prefix. Consumers use it to retrieve cached Salesforce CRM records by object type, with optional filtering, field projection, and pagination. All endpoints require HTTP Basic Auth with a provisioned client ID and password. The API is the successor to the legacy Reading Rainbow service and serves data from the internal PostgreSQL cache rather than querying Salesforce directly.

## Endpoints

### Object Collection

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v0/{object-name}` | Returns a paged collection of cached Salesforce records of the given object type | Basic Auth |
| GET | `/v0/{object-name}/{salesforce-id}` | Returns a single cached Salesforce record by Salesforce ID | Basic Auth |

#### Query Parameters for `/v0/{object-name}`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `filter` | string | No | Filter expression in custom DSL or JSON array format (e.g., `SystemModstamp > "2013"`, `["AND", ["=", "Groupon_Nows__c", 1], ["!=", "ParentId", null]]`) |
| `fields` | string | No | Comma-separated list of field names to project; if omitted all accessible fields are returned |

#### Example Requests

- Filter RecordTypes by name: `GET /v0/RecordType?filter=Name%20=%20%22POS%22`
- Filter Tasks by AccountId: `GET /v0/Task?filter=AccountId%20=%20%22001C0000017EJuJIAW%22`
- Single record: `GET /v0/Account/001abcdefghijklmno`

## Request/Response Patterns

### Common headers

- `Authorization: Basic <base64(client-id:password)>` — required on all requests

### Response format — single record

```json
{"record": {"Id": "001abcdefghijklmno", "Something__c": "else", ...}}
```

### Response format — collection

```json
{
  "records": [{"Id": "001abcdefghijklmno", "Something__c": "else"}, ...],
  "next-page": "/v0/..."
}
```

The `next-page` key is present only when additional pages exist. Clients follow it to retrieve the next page.

### Error format

- `404 Not Found` — returned when the requested Salesforce ID does not exist in the cache
- `401 Unauthorized` — returned when credentials are invalid or missing
- `5xx` — returned for server-side errors; monitored via High API Failure Rate alert

### Pagination

Cursor-based pagination via the `next-page` field in collection responses. Clients follow the `next-page` path to retrieve subsequent pages until no `next-page` key is present in the response.

## Rate Limits

> No rate limiting configured. Clients experiencing high request volumes are expected to coordinate with the Salesforce Integration team.

## Versioning

The API uses a URL path version prefix (`/v0/`). The current and only version is `v0`. Clients are expected to pin to this prefix.

## OpenAPI / Schema References

- OpenAPI spec: `src/main/resources/openapi3.yml` (within the service repo)
- Legacy swagger doc: `doc/swagger/swagger.yaml`
- Service portal API schema path: `src/main/resources/openapi3.yml` (registered in `.service.yml`)

## Service Endpoints

| Environment | Base URL |
|-------------|----------|
| Staging | `salesforce-cache.staging.service` |
| Production | `salesforce-cache.production.service` |
| Production (Hybrid Boundary UI) | `https://hybrid-boundary-ui.prod.us-west-1.aws.groupondev.com/services/salesforce-cache/salesforce-cache` |
| Staging (Hybrid Boundary UI) | `https://hybrid-boundary-ui.staging.stable.us-west-1.aws.groupondev.com/services/salesforce-cache/salesforce-cache` |

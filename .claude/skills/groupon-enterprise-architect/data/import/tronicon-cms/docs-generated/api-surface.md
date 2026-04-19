---
service: "tronicon-cms"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

The Tronicon CMS REST API provides two groups of endpoints: `cms` for content lifecycle management and `cms_stats` for usability statistics. Consumers use it to create, retrieve, publish, archive, and delete CMS content items keyed by path, locale, brand, and version. The API is documented in an OpenAPI 2.0 (Swagger) specification at `doc/swagger/swagger.yaml`. No authentication mechanism is configured at the API level — access control is assumed to be handled at the network/infrastructure layer.

## Endpoints

### CMS Content (`/cms/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cms/all` | Retrieve all CMS content with optional pagination and filters (team, brand, locale) | None configured |
| GET | `/cms/all-paths` | Find all unique content paths; supports search by `subPath`, `path`, `team`, `brand`, `modifiedBy`, `locale`, `status` | None configured |
| GET | `/cms/id/{id}` | Retrieve a single CMS content item by integer ID | None configured |
| DELETE | `/cms/id/{id}` | Delete a CMS content item by integer ID | None configured |
| GET | `/cms/path/{path}` | Find all content items for a path filtered by `locale` (required), `X-Brand` header (required), and optional `status` | None configured |
| GET | `/cms/path/{path}/key/{key}` | Retrieve a specific content item by path and content key for a given locale and brand | None configured |
| GET | `/cms/path/{path}/version/{version}` | Find content by path and version with optional locale and brand filters | None configured |
| GET | `/cms/metadata/path/{path}/version/{version}` | Find content metadata by path and version, omitting the `content` body column | None configured |
| GET | `/cms/path/{path}/brand-locale-versions` | List all brands, locales, and versions available for a given path | None configured |
| GET | `/cms/path/{path}/audit-log` | Retrieve a specific audit log entry by path, brand, locale, version, minor version, and content key | None configured |
| GET | `/cms/path/{path}/audit-logs` | List audit log entries for a path by brand, locale, and version | None configured |
| GET | `/cms/pathlist` | Retrieve content for multiple paths simultaneously by locale and brand (multi-value `path` query param) | None configured |
| GET | `/cms/paths/team/{team}` | Find content items for a given team and locale | None configured |
| POST | `/cms/update-all` | Upsert one or more CMS content items (create if no ID present; update if ID provided) | None configured |
| POST | `/cms/path/{path}/clone` | Clone an existing path/locale/brand/version as a new DRAFT; auto-increments version | None configured |
| POST | `/cms/publish/path/{path}` | Publish a DRAFT to VALIDATED state; demotes any existing VALIDATED to ARCHIVED | None configured |
| POST | `/cms/archive/path/{path}` | Archive a VALIDATED path by locale and brand | None configured |
| DELETE | `/cms/delete-draft` | Delete a DRAFT content item by path, locale, brand, and version | None configured |

### CMS Usability Statistics (`/cms-stats/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/cms-stats/id/{cms_content_id}` | Retrieve usability statistics for a content item by CMS content ID | None configured |
| GET | `/cms-stats/show-stats/id/{cms_content_id}` | Retrieve a content item together with its usability statistics by ID | None configured |
| POST | `/cms-stats/save` | Create or update usability statistics for one or more content items | None configured |
| DELETE | `/cms-stats/delete/id/{cms_content_id}` | Delete usability statistics for a content item by CMS content ID | None configured |

## Request/Response Patterns

### Common headers

- `X-Brand` (required on path-based content reads) — identifies the brand; default `groupon`. Accepted values: `groupon`, `livingsocial`, `test`
- `X-request-id` (optional) — correlation ID for request tracing
- `ACCEPT-LANGUAGE` (optional) — language preference header (forwarded, not used for routing)

### Error format

Errors are returned as JSON with the `CMSError` schema:

```json
{
  "error": true,
  "message": "<error description>"
}
```

Common HTTP status codes:
- `200` — Success with response body
- `204` — Deleted (no content returned)
- `400` — Validation failure (e.g., invalid locale, contentType, brand, or null content ID)
- `404` — Content item not found
- `406` — Draft already exists (clone conflict)
- `500` — Internal server error

### Pagination

The `/cms/all` and `/cms/all-paths` endpoints support offset/limit pagination:
- `offset` — integer, default `0`, minimum `0`
- `limit` — integer, default `100`, minimum `1`

### Content lifecycle states

Content items progress through a defined state machine managed by the service:
- `DRAFT` — work in progress; editable; only one draft allowed per path/locale/brand combination
- `VALIDATED` — published and live; becomes the active version served to consumers
- `ARCHIVED` — superseded by a newer VALIDATED version; retained for history and audit

### Content types

The `contentType` field must be either `json` or `html`.

### Content versioning

Versioning is maintained internally. New paths start at version `1`; clone operations auto-increment to the highest existing version. Explicit version arguments in upsert (`/cms/update-all`) payloads are ignored by the service.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path API versioning strategy. The API is unversioned at the HTTP level. The Swagger spec declares API version `1.0.local-SNAPSHOT`. The `locale` parameter minimum length is 5 characters.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml`
- Service discovery manifest: `doc/service_discovery/resources.json`
- Swagger UI (staging us-central1): `https://tronicon-cms.staging.service.us-central1.gcp.groupondev.com/swagger/?url=https://tronicon-cms.staging.service.us-central1.gcp.groupondev.com/swagger.json`
- Swagger UI (staging europe-west1): `https://tronicon-cms.staging.service.europe-west1.gcp.groupondev.com/swagger/?url=https://tronicon-cms.staging.service.europe-west1.gcp.groupondev.com/swagger.json`
- Swagger UI (production us-central1): `https://tronicon-cms.production.service.us-central1.gcp.groupondev.com/swagger/?url=https://tronicon-cms.production.service.us-central1.gcp.groupondev.com/swagger.json`
- Swagger UI (production eu-west-1): `https://tronicon-cms.production.service.eu-west-1.aws.groupondev.com/swagger/?url=https://tronicon-cms.production.service.eu-west-1.aws.groupondev.com/swagger.json`

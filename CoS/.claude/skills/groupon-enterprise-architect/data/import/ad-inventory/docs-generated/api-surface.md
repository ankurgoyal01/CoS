---
service: "ad-inventory"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

Ad Inventory exposes a REST API over HTTP on port 8080. Two groups of endpoints exist: the public ad API (`aiapiv1` tag) for placement serving and click tracking, and the admin API (`adminv1` tag) for operational tasks. The admin endpoints require an `amsecret` query parameter as an access control mechanism. The OpenAPI specification is located at `doc/openapi.yml`.

## Endpoints

### Ad API (aiapiv1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/ai/api/v1/placement` | Serves an ad placement for a given page, platform, locale, and audience context | None (public) |
| `GET` | `/ai/api/v1/placement/test` | Test variant of the placement endpoint for QA and pre-production validation | None (public) |
| `GET` | `/ai/api/v1/slc/{id}` | Reports a Sponsored Listing click; forwards to CitrusAd and persists in MySQL | None (public) |
| `GET` | `/ai/api/v1/test` | Ad placement test endpoint (alternative test path) | None (public) |

### Admin API (adminv1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `DELETE` | `/admin/v1/caches` | Refreshes all in-memory and Redis audience caches | `amsecret` query param |
| `PUT` | `/admin/v1/reset/config` | Reloads service configuration from source | `amsecret` query param |
| `GET` | `/admin/v1/test/exception` | Test endpoint for triggering exception handling paths | `amsecret` query param |

### Health / Heartbeat

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/heartbeat.txt` | Liveness probe for load balancers and deployment verification | None |
| `GET` | `/grpn/status` | JTier status endpoint (commitId key) — disabled in v4 service portal poller | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for admin responses
- Placement responses may return ad markup directly (content varies by placement type)

### Error format

> No evidence found in codebase for a standardized error response envelope beyond HTTP status codes.

### Pagination

> Not applicable — placement responses return a single ad unit per call; no paginated resources exposed.

## Rate Limits

> No rate limiting configured. Evidence: no rate-limit configuration found in `pom.xml`, `development.yml`, or deployment manifests.

## Versioning

URL path versioning is used. The current public ad API version is `v1` (prefix `/ai/api/v1/`). Admin endpoints use `/admin/v1/`. Version is part of the path segment.

## OpenAPI / Schema References

- OpenAPI 3.0.1 specification: `doc/openapi.yml`
- Swagger JSON/YAML: `doc/swagger/swagger.json` and `doc/swagger/swagger.yaml`
- Published Swagger link: `https://github.groupondev.com/sox-inscope/ad-inventory/blob/main/doc/swagger/swagger.yaml`

## Placement Endpoint Parameters

The `/ai/api/v1/placement` endpoint accepts the following query parameters:

| Parameter | Required | Data Class | Description |
|-----------|----------|------------|-------------|
| `page` | yes | unclassified | Page context for placement selection |
| `platform` | yes | unclassified | Client platform (web, mobile, etc.) |
| `locale` | yes | unclassified | Locale code for targeting |
| `placements` | yes | unclassified | Placement identifier(s) requested |
| `country` | yes | unclassified | Country code for geo targeting |
| `division` | yes | unclassified | Groupon division for targeting |
| `app` | yes | unclassified | App identifier |
| `c_cookie` | no | class3 | Groupon c_cookie for audience membership lookup |
| `b_cookie` | no | class3 | Groupon b_cookie for audience membership lookup |

## Click Endpoint Parameters

The `/ai/api/v1/slc/{id}` endpoint accepts:

| Parameter | Required | Data Class | Description |
|-----------|----------|------------|-------------|
| `id` | yes (path) | unclassified | Placement or campaign identifier |
| `bc` | yes | unclassified | Bid context |
| `cc` | no | class3 | Cookie context |
| `dealuuid` | no | class3 | Deal UUID associated with the sponsored listing click |

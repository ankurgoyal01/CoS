---
service: "deals-cluster-api-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [jtier-auth]
---

# API Surface

## Overview

The Deals Cluster API exposes a JSON REST API consumed by the Deals Cluster Spark Job, marketing tooling, and navigation surfaces. The API provides four resource groups: clusters (read-only), cluster rules (CRUD), top clusters (read-only with in-memory cache), top cluster rules (CRUD), tagging use cases, and a tagging audit trail. A Swagger UI is available in each environment at `/swagger`.

## Endpoints

### Clusters

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clusters` | List all available clusters with pagination and filter support | JTier auth |
| GET | `/clusters/{id}` | Get details and deal list for a specific cluster by UUID | JTier auth |

**Query parameters for `GET /clusters`:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `limit` | integer | Number of objects to return |
| `offset` | integer | Pagination start point |
| `ruleName` | string | Filter by rule name |
| `ruleId` | string | Filter by rule id |
| `deal` | string (CSV) | Filter by deal UUIDs |
| `minDealsCount` | string | Minimum deals in cluster |
| `country` | string | Filter by country code |
| `city` | string (CSV) | Filter by cities |
| `division_id` | string (CSV) | Filter by division IDs |
| `channel` | string (CSV) | Filter by channels |
| `pds_id` | string (CSV) | Filter by PDS UUIDs |
| `category` | string (CSV) | Filter by CFT category UUIDs (any level) |
| `clusterUuid` | string | Return all history for a specific cluster UUID |
| `subchannel` | string (CSV) | Filter by sub-channels |

### Cluster Rules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rules` | List all cluster rule definitions (with pagination) | JTier auth |
| GET | `/rules/{id}` | Get details for a specific rule | JTier auth |
| POST | `/rules` | Create a new rule or update an existing rule | JTier auth |
| DELETE | `/rules/{id}` | Delete an existing rule by id | JTier auth |

### Top Clusters

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/topclusters` | List top-performing clusters for a given type, country, and optional filters | JTier auth |

**Query parameters for `GET /topclusters`:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `type` | mandatory | Top cluster rule name (e.g., `NAVIGATION_L2`, `DIVISION_L3_CR`, `DIVISION_L4_CR`) |
| `country` | mandatory | Country code filter |
| `division` | optional | Division ID filter |
| `category` | optional | Category UUID filter (level 2) |
| `debug` | optional | Enable debug mode (bypasses cache) |

### Top Cluster Rules

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/topclustersrules` | List all top cluster rule definitions (with pagination) | JTier auth |
| GET | `/topclustersrules/{id}` | Get details for a specific top cluster rule | JTier auth |
| POST | `/topclustersrules` | Create or update a top cluster rule | JTier auth |
| DELETE | `/topclustersrules/{id}` | Delete a top cluster rule by id | JTier auth |

### Tagging Audit

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mts/taggingaudit` | Query tagging audit records by page, size, tagDate, tagName, or tagUuid | JTier auth |

### Health / Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/status` | Service health status (JTier standard) | None |
| GET | `/swagger` | Swagger UI | None |
| GET | `/swagger.json` | OpenAPI spec (JSON) | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` required for POST request bodies
- `Accept: application/json` for all endpoints

### Error format

> No evidence found in codebase of a custom error envelope. Standard Dropwizard/JTier error responses apply (HTTP status code with JSON error body).

### Pagination

`GET /clusters`, `GET /rules`, `GET /topclustersrules`, and `GET /mts/taggingaudit` support pagination via `limit`/`offset` (or `page`/`size` for tagging audit).

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning. The API version is embedded in the Swagger metadata as `1.0.local-SNAPSHOT`. No versioning strategy beyond the service release tag.

## OpenAPI / Schema References

- OpenAPI spec (YAML): `doc/swagger/swagger.yaml`
- OpenAPI spec (JSON): `doc/swagger/swagger.json`
- Swagger config: `doc/swagger/config.yml`
- Service discovery resources: `doc/service_discovery/resources.json`
- Staging Swagger UI: `http://deals-cluster-staging.snc1/swagger`
- Production Swagger UI: `http://deals-cluster-vip.snc1/swagger/?url=http://deals-cluster-vip.snc1/swagger.json`

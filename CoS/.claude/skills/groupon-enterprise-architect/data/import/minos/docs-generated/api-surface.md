---
service: "minos"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

Minos exposes a JSON REST API over HTTP (port 8080 application, port 8081 admin) under the `/v1` path prefix. The API is consumed internally by the 3PIP ingestion pipeline and tooling. All endpoints produce and consume `application/json`. The OpenAPI 2.0 (Swagger) specification is available at `doc/swagger/swagger.yaml`.

## Endpoints

### Duplicate Detection

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/duplicates` | Accepts an ingestion deal and returns a list of duplicate deal catalog deal IDs | Internal |

### Duplicate Score Overrides

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/duplicates/overrides` | Creates or updates duplicate score overrides for ingestion/deal combinations | Internal |
| `GET` | `/v1/duplicates/overrides/{ingestionId}` | Returns all duplicate score overrides for a given ingestion deal UUID | Internal |
| `DELETE` | `/v1/duplicates/overrides/{ingestionGrouponDealId}?duplicateGrouponDealId={uuid}` | Removes a specific duplicate score override | Internal |

### Flux Report

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/flux/report` | Accepts a list of ingestion/Groupon deal UUID pairs and returns a Flux-formatted JSON payload | Internal |

### Quartz Scheduler

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/v1/quartz` | Manually initializes and triggers the Flux processing (scoring refresh) job | Internal |

### Recall Lookup

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/recallLookup` | Returns the recall lookup list for all PDS IDs | Internal |
| `GET` | `/v1/recallLookup/{pdsId}` | Returns the recall lookup entry for a specific PDS ID (UUID) | Internal |
| `PUT` | `/v1/recallLookup/update` | Triggers an update of the recall lookup list from Cerebro | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` required for `POST` request bodies
- `Accept: application/json` expected by all endpoints that produce JSON responses

### Error format

- `404 Not Found` returned when a referenced deal ID does not exist
- `204 No Content` returned by successful delete and job-trigger operations
- Response bodies for successful operations follow the `DuplicateResponse` or `DuplicateScoreOverrideResponse` schemas defined in the OpenAPI spec

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints are versioned under `/v1/`. No additional versioning mechanism (header or query param) is in use.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml`
- Swagger JSON: `doc/swagger/swagger.json`
- Swagger UI config: `doc/swagger/config.yml`
- Service discovery resources: `doc/service_discovery/resources.json`
- Base URL (staging): `http://minos-staging-vip.snc1`
- Base URL (production, snc1): `http://minos-vip.snc1`
- Base URL (production, cloud): `minos.us-central1.conveyor.prod.gcp.groupondev.com`

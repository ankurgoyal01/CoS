---
service: "gcp-aiaas-terraform"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

All externally accessible endpoints are exposed via GCP API Gateway, which fronts both Cloud Functions (Gen 2) and Cloud Run services. The gateway enforces API key authentication on every route. Backends are addressed by direct Cloud Functions HTTPS URLs in the `prj-grp-aiaas-prod-0052` project. All paths are prefixed with `/v1/` and all responses are JSON. The OpenAPI specification is defined in `doc/swagger.yml` (Swagger 2.0 format, `openapi2-functions.yaml` style).

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/healthCheck` | Platform health probe | API Key |

### Merchant Performance Platform (MPP)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/mppGoogleReviews` | Analyse Google Reviews for merchant quality scoring | API Key |
| POST | `/v1/mppImageUrls` | Generate image quality scores from URLs | API Key |
| POST | `/v1/mppGrouponReviews` | Analyse Groupon-native merchant reviews | API Key |

### Content Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/uspGen` | Generate Unique Selling Propositions for a merchant | API Key |
| POST | `/v1/contentGen` | Generate merchant content copy | API Key |
| POST | `/v1/genai` | General GenAI inference (open-ended generation) | API Key |

### Model Inference

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/infer-pds` | PDS model inference | API Key |
| POST | `/v1/infer-ece` | ECE model inference | API Key |

### Background Processing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/submitRequest` | Submit a request for asynchronous background ML processing | API Key |

### Image CDN Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/getCDNurls` | Retrieve CDN image URLs for a merchant | API Key |
| POST | `/v1/deleteCDNurl` | Remove a CDN image URL entry | API Key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests; gateway returns HTTP 415 if absent
- API key header as configured by GCP API Gateway (enforced at gateway layer)

### Error format

| HTTP Status | Meaning |
|-------------|---------|
| 200 | Successful response (schema: `array` or `string` per endpoint) |
| 400 | Bad Request — missing or malformed request parameters |
| 403 | Forbidden — missing or invalid API key |
| 415 | Unsupported Media Type — inference endpoints require `application/json` |
| 424 | Gateway Model Error — Cloud Run returned an application-level error |
| 503 | Service Unavailable — backend unreachable or capacity limit reached |

### Pagination

> No evidence found in codebase. Responses are returned as arrays; no pagination scheme is defined in `doc/swagger.yml`.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Gateway throttle | Configurable via GCP API Gateway | Per API config |

> Specific numeric rate limits are not hardcoded in this repository. The API Gateway throttle setting is tunable in the GCP console when endpoint capacity issues occur (see `doc/owners_manual.md` — "Cloud Run Endpoint Failures" section).

## Versioning

All routes are prefixed with `/v1/`, establishing a URL-path versioning strategy. No v2 routes are defined in the current `doc/swagger.yml`.

## OpenAPI / Schema References

- OpenAPI spec: `doc/swagger.yml` (Swagger 2.0, `openapi2-functions.yaml`)
- Backend base URL (prod): `https://us-central1-prj-grp-aiaas-prod-0052.cloudfunctions.net/`
- All endpoints have a backend deadline of `600.0` seconds (10 minutes) configured via `x-google-backend.deadline`

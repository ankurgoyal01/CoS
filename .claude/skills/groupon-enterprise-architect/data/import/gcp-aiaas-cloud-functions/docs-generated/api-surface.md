---
service: "gcp-aiaas-cloud-functions"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, none]
---

# API Surface

## Overview

All functions and Cloud Run services expose synchronous HTTP REST endpoints. Cloud Functions use Flask HTTP handlers registered with the GCP functions-framework; Cloud Run services use FastAPI routers served by uvicorn. All endpoints accept and return JSON. Callers are internal Groupon tooling and merchant advisor integrations.

## Endpoints

### AIDG Cloud Function — AI Deal Structure Generator

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` (Cloud Function entry: `ai_deal_structure_v3`) | Generate AI deal structure for a merchant, PDS category, city, and area tier | None (network-level) |

**Required query parameters**: `pds_cat_id`, `city`, `area_tier`, `account_id`

**Success response** (`200`): JSON array containing a deal structure object with title, options, pricing, and content fields.

**Error codes**: `400 VALIDATION_MISSING_FIELD`, `400 JSON_INVALID`, `422 PDS_NOT_ALLOWED`, `422 BUSINESS_RULE_VIOLATION`, `500 INTERNAL_ERROR`

---

### Deal Score Cloud Function

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/` (Cloud Function entry: `deal_score_v1`) | Score a deal and predict expected revenue label | None (network-level) |
| `GET` | `/health` (Cloud Function entry: `health_check`) | Health check returning service status and Vertex AI endpoint config | None |

**Required query parameters**: `pds` (PDS category name)

**Optional query parameters**: `accountId`

**Required JSON body fields**: `title` (string), `content` (string)

**Optional JSON body fields**: `Unit_Value__c`, `Discount__c`, `marginPercent`, `fiveStar`

**Success response** (`200`):
```json
{
  "title": "...",
  "predictedRevenue": 125.5,
  "label": "Ace | King | Queen | Jack | Do not show",
  "pds": "...",
  "summary": "...",
  "extractedFeatures": {
    "wordCount": 0.0,
    "titleLengthWords": 0.0,
    "readabilityStructureQuality": 0.0,
    "readabilityInformationClarity": 0.0,
    "redFlags": 0.0
  },
  "metadata": {
    "processingService": "cloud_function",
    "mlService": "vertex_ai",
    "thresholdsUsed": {}
  },
  "error": { "statusCode": null, "success": true }
}
```

**Error codes**: `400 MISSING_PDS_PARAMETER`, `400 INVALID_PAYLOAD`, `400 MISSING_CONTENT`, `500 FEATURE_EXTRACTION_ERROR`, `500 MODEL_PREDICTION_ERROR`, `500 SUMMARY_GENERATION_ERROR`, `500 DEAL_SCORE_INTERNAL_ERROR`

---

### Google Scraper Cloud Function

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/google-scraper` | Scrape Google merchant data and compute merchant potential | None (network-level) |

**Query parameters**: `accountId` (or `url` + `merchantName` + `city`), `url`, `merchantName`, `city`, `state`, `postalCode` (default `""`), `countryCode` (default `"us"`), `pds`, `test` (default `"false"` — enables LightGBM mode instead of Vertex AI)

**Validation rule**: Either `accountId` must be provided OR (`url` or `merchantName` + `city`) must be provided.

**Success response** (`200`): JSON object with `pds` array and `scrapedData` array.

**Error codes**: `400 GOOGLESCRAPER_MISSING_INPUT`, `500 error`

---

### InferPDS Cloud Run API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/extract-services` | Extract and match PDS services from a merchant website | None (network-level) |
| `GET` | `/health` | Health check | None |

**Request body fields** (JSON): `accountId` or `url` (one required), plus optional scraping and model configuration parameters.

**Success response** (`200`): JSON with arrays `pds`, `newServices`, `existingServices`, `scrapedData`, and a `summary` object.

---

### MAD InferPDS Cloud Run API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/extract-services` | Authenticated variant of InferPDS extraction | API key (MAD-specific) |
| `GET` | `/health` | Health check | None |

The MAD variant adds API-key authentication and feedback endpoints for the Merchant Advisor Dashboard integration.

---

### Infer PDS V3 Cloud Function (Legacy)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` (Cloud Function entry: `infer_pds_sf_v5`) | Legacy scrape-and-match PDS inference | None (network-level) |

**Query parameters**: `accountId`, `url`, `returnSegregated` (bool, default `true`), `forceNewMatching` (bool, default `false`), `forceNewScraping` (bool, default `false`), `similarityThreshold` (float, default `0.25`), `maxPagesToScrape` (int, default `8`), `gptModel` (string, default `"gpt-4.1-mini-2025-04-14"`), `fastMode` (bool, default `false`)

**Success response** (`200`): JSON with `pds`, `newServices`, `existingServices`, `summary`, `scrapedData` fields.

**Error codes**: `400 INFERPDS_MISSING_INPUT`, `500 INFERPDS_INTERNAL_ERROR`

---

### PDS Priority Cloud Function

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` or `POST` | `/` (Cloud Function entry: `pds_priority`) | Query prioritized PDS records from BigQuery | None (network-level) |

**Accepted filters** (query params or JSON body): `accountId`, `city`, `country`, `consolidatedCity`, `pdsCatName`, `pdsCatId`, `merchantPotential`, `customerPercentileBucket`, `slEligible`, `tg`

At least one filter is required. Results are returned in camelCase.

**Success response** (`200`): JSON array of PDS records from `prj-grp-dataview-prod-1ff9.supply.acc_information_pds` with camelCase keys.

**Error codes**: `400 MISSING_FILTERS`, `400 PARAMETER_PARSING_ERROR`, `404 NO_DATA_FOUND`, `500 BIGQUERY_ERROR`

---

### Social Link Scraper Cloud Function

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` or `POST` | `/` (Cloud Function entry: `social_link_scraper`) | Discover social media links from a merchant website | None (network-level) |

**Parameters** (query params or JSON body): `merchantUrl` or `merchant_url` (required), `maxPages` / `max_pages` (default `3`), `timeout` (default `5`), `scrapeInstagram` / `scrape_instagram` (default `false`), `apifyToken` / `apify_token`, `apifyMaxProfiles` / `apify_max_profiles` (default `2`), `includePostsData` / `include_posts_data` (default `false`)

**Success response** (`200`): JSON object keyed by social platform name (`facebook`, `instagram`, `twitter`, `x`, `linkedin`, `youtube`, `tiktok`, `pinterest`, `threads`, `snapchat`, etc.) each containing an array of discovered URLs, plus `_meta`, `success`, and `message` fields.

**Error codes**: `400` (missing `merchantUrl`), `400` (invalid parameter value), `500` (scraping error)

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` on all POST requests
- `Access-Control-Allow-Origin: *` on Deal Score and Social Link Scraper (CORS enabled)

### Error format
All functions return a consistent error envelope:
```json
{
  "status_code": 400,
  "success": false,
  "status": "ERROR_CODE_STRING",
  "message": "Human readable message",
  "details": "Additional context string"
}
```
The Deal Score function wraps errors in an `"error"` key nested inside the full response object to always return structured output even on failure.

### Pagination
> No pagination configured. All queries return full result sets for the given filter criteria.

## Rate Limits
> No rate limiting configured at the application layer. GCP Cloud Functions and Cloud Run impose concurrency and invocation limits at the platform level.

## Versioning
URL-path versioning is used informally: the AIDG function entry point is `ai_deal_structure_v3`, the InferPDS V3 function uses `infer_pds_sf_v5` internally. The Cloud Run APIs do not use versioned URL paths. No formal API versioning strategy is enforced.

## OpenAPI / Schema References
> No OpenAPI spec files found in the repository. FastAPI auto-generates an OpenAPI schema at `/docs` and `/openapi.json` on the Cloud Run services when running.

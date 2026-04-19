---
service: "ugc-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id, internal-header]
---

# API Surface

## Overview

The UGC API exposes a versioned REST API over HTTP (port 8080). All business endpoints fall under versioned path prefixes (`/v1.0/`, `/ugc/v1.0/`, `/{var}v1.0/`) with a separate modal-provider path (`/modal_provider/v1/`). Clients must pass a `client_id` query parameter on most public read endpoints. The API returns JSON for all business endpoints. The service is documented via an OpenAPI 2.0 spec at `doc/swagger/swagger.yaml`.

## Endpoints

### Health and Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service health check | None |
| GET | `/heartbeat.txt` | Load-balancer heartbeat | None |
| GET | `/ping` | Liveness ping | None |
| GET | `/grpn/status` | JTier status endpoint (port 8080) | None |

### Modal Provider

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/modal_provider/v1/modals` | Retrieve eligible survey modals by consumer, locale, platform, and workflow context | `client_id` |
| POST | `/modal_provider/v1/modals/events` | Record a modal interaction event | Internal |

### Reviews and Answers (Merchant)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ugc/v1.0/merchants` | Get merchant reviews or summary by merchant UUID (`method=reviews\|summary`) | `client_id` |
| GET | `/ugc/v1.0/merchants/{merchantId}/reviews` | Get paginated reviews for a specific merchant | `client_id` |
| GET | `/ugc/v1.0/merchants/{merchantId}/summary` | Get rating summary for a specific merchant | `client_id` |
| GET | `/{var}v1.0/merchants/{merchantId}/answers/breakdown` | Get answer breakdown by deal, date range, and tag for a merchant | `client_id` |

### Reviews and Answers (Places)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ugc/v1.0/places` | Get place reviews or summary by place UUID (`method=reviews\|summary`) | `client_id` |
| GET | `/v1.0/places/{placeId}/reviews` | Get paginated reviews for a specific place | `client_id` |
| GET | `/v1.0/places/{placeId}/summary` | Get rating summary for a specific place | `client_id` |

### Answers (Submit / Delete / Action)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/{var}v1.0/answers` | Submit a new answer (review/rating) | Internal |
| PUT | `/{var}v1.0/answers` | Submit or update an answer | Internal |
| GET | `/{var}v1.0/answers/{id}` | Retrieve a single answer by ID | Internal |
| DELETE | `/{var}v1.0/answers/{id}` | Delete an answer by ID | Internal |
| POST | `/{var}v1.0/answers/{id}/action` | Record an AnswerAction (like, dislike, flag) on an answer | Internal |
| PUT | `/{var}v1.0/answers/{id}/action` | Update an AnswerAction | Internal |
| DELETE | `/{var}v1.0/answers/{id}/action/by/{userId}` | Remove a user's AnswerAction on an answer | Internal |
| POST | `/{var}v1.0/answers/{answerId}/replies` | Add a reply to an answer | Internal |
| PUT | `/{var}v1.0/answers/{answerId}/replies` | Add or update a reply to an answer | Internal |
| DELETE | `/{var}v1.0/answers/{answerId}/replies/{id}` | Delete a specific reply | Internal |

### Images

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/{var}v1.0/images` | Search images by merchant, place, deal, user, or survey | `client_id` |
| POST | `/{var}v1.0/images` | Submit an ImageAction (upload, like, flag) | Internal |
| PUT | `/{var}v1.0/images` | Submit or update an ImageAction | Internal |

### Videos

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/videos` | Search videos by merchant, place, deal, user, or survey | `client_id` |
| POST | `/v1.0/videos` | Submit a VideoAction on a video | Internal |
| GET | `/v1.0/influencer/video/search` | Search influencer videos by merchant, deal, or permalink | `client_id` |
| GET | `/v1.0/influencer/video/{id}` | Get influencer video details by ID | `client_id` |
| PUT | `/v1.0/influencer/video/{id}` | Update an influencer video | Internal |
| POST | `/v1.0/influencer/video/presinged-urls/{user-id}` | Generate pre-signed S3 upload URLs for video upload | Internal |

### Surveys

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1.0/surveys` | Get eligible surveys by surveyVersion, grouponCode, surveyId, voucherId, or surveyKey | Internal |
| POST | `/v1.0/surveys` | Create a new survey | Internal |
| GET | `/ugc/v1.0/surveys` | Get eligible surveys (alternate path) | Internal |
| POST | `/ugc/v1.0/surveys` | Mark a survey viewed or completed | Internal |
| POST | `/v1.0/surveys/{surveyId}/replies` | Submit a reply to a survey | Internal |
| PUT | `/v1.0/surveys/{surveyId}/replies` | Submit or update a survey reply | Internal |
| DELETE | `/v1.0/surveys/{surveyId}/replies/{id}` | Delete a survey reply | Internal |
| POST | `/v1.0/surveys/{surveyId}/viewed` | Mark a survey as viewed | Internal |
| PUT | `/v1.0/surveys/{surveyId}/viewed` | Mark a survey as viewed (PUT variant) | Internal |
| POST | `/v1.0/surveys/{surveyId}/completed` | Mark a survey as completed | Internal |
| GET | `/v1.0/surveys/{surveyId}/uploadUrls` | Get pre-signed S3 URLs for survey file upload | Internal |
| GET | `/ugc/v1.0/surveys/{surveyId}/uploadUrls` | Get pre-signed S3 URLs (alternate path) | Internal |
| POST | `/ugc/v1.0/surveys/{surveyId}/viewed` | Mark survey viewed (alternate path) | Internal |

### Admin / Moderation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/{var}v1.0/admin/reviews/search` | Search reviews/answers by date, merchant, place, user, status, source | Admin |
| GET | `/{var}v1.0/admin/answers/search` | Search answer ratings by date, merchant, deal | Admin |
| PUT | `/{var}v1.0/admin/answers/{id}/ratings` | Update answer ratings | Admin |
| GET | `/{var}v1.0/admin/grouponCode/{grouponCode}/answers` | Get answers by groupon code | Admin |
| GET | `/{var}v1.0/admin/surveys/{id}/answers` | Get answers for a survey | Admin |
| DELETE | `/{var}v1.0/admin/surveys/{id}/answers` | Delete all answers for a survey | Admin |
| DELETE | `/{var}v1.0/admin/user/{id}/answers` | Delete all reviews and ratings for a user | Admin |
| DELETE | `/{var}v1.0/admin/{id}` | Delete an answer by ID (admin) | Admin |
| POST | `/{var}v1.0/admin/{id}/action` | Store an AnswerAction (admin) | Admin |
| PUT | `/{var}v1.0/admin/{id}/action` | Update an AnswerAction (admin) | Admin |
| GET | `/{var}v1.0/admin/images/search` | Search images with moderation filters (status, date, merchant, place, user) | Admin |
| GET | `/{var}v1.0/admin/videos/search` | Search videos with moderation filters (status, date, merchant, place, user) | Admin |
| POST | `/{var}v1.0/admin/videos/action` | Submit a video action (admin) | Admin |
| GET | `/{var}v1.0/admin/contentOptOut` | Retrieve content opt-out record for an entity | Admin |
| POST | `/{var}v1.0/admin/contentOptOut` | Create or update a content opt-out | Admin |
| POST | `/{var}v1.0/admin/survey` | Create a post-redemption (moderation) survey | Admin |
| PUT | `/{var}v1.0/admin/survey` | Create or update a moderation survey | Admin |

### UGC Transfer / Copy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/ugc/copy` | Copy UGC from one merchant to new merchants | Admin |
| PUT | `/ugc/copy/rollback` | Rollback a previously copied UGC | Admin |
| PUT | `/ugc/transfer` | Transfer UGC from an old merchant to a new merchant | Admin |

## Request/Response Patterns

### Common headers

- `x-request-id` (string, optional) — Correlation ID for distributed tracing
- `x-brand` (string, optional, default: `groupon`) — Brand context for multi-brand support
- `x-country-code` (string, optional) — Country context for locale-specific queries
- `x-forwarded-for` (string, optional) — Client IP, used for rate limiting on submission endpoints

### Error format

> No evidence found in codebase for a documented error response schema. Based on `ErrorMessage.java` in the codebase, errors are returned as JSON with an error message field.

### Pagination

All list endpoints support `offset` (default `0`) and `limit` (default `20`) query parameters. Responses include a `Page` wrapper with total count and content array.

## Rate Limits

> No explicit rate limit tiers are documented in config. Rate limiting is enforced via the `continuumUgcRedis` store using Jedis. Specific limits are configured at runtime and are not present in the source files in this repository.

## Versioning

URL path versioning is used. All business endpoints are prefixed with `/v1.0/`. The `{var}` prefix placeholder in swagger paths resolves to either `ugc/` or `mpp-service/` depending on the caller context. A `surveyVersion` query parameter is available on survey endpoints (default `v1.0`).

## OpenAPI / Schema References

- OpenAPI 2.0 spec: `doc/swagger/swagger.yaml`
- Swagger UI config: `doc/swagger/config.yml`
- Service discovery resources: `doc/service_discovery/resources.json`

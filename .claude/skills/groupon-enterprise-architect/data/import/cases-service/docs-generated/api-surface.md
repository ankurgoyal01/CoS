---
service: "cases-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The MCS REST API is consumed by the Merchant Center frontend to manage merchant support cases and access knowledge management content. All paths are prefixed with `/v1`. Authentication is enforced via the `X-Api-Key` header using a client ID scheme configured per environment. Most merchant-scoped endpoints require a `{merchantuuid}` path parameter. The API is documented in OpenAPI 2.0 (Swagger) format at `doc/swagger/swagger.yaml` and in the service discovery resource descriptor at `doc/service_discovery/resources.json`.

## Endpoints

### Case Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/merchants/{merchantuuid}/cases` | List merchant cases with pagination, date-range, sort, and status filters | `X-Api-Key` |
| `POST` | `/v1/merchants/{merchantuuid}/cases` | Create a new support case for a merchant | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/cases/{caseNum}` | Retrieve a single case by case number | `X-Api-Key` |
| `PUT` | `/v1/merchants/{merchantuuid}/cases/{caseNum}/status/{status}` | Update the status of a case (e.g., CLOSED) | `X-Api-Key` |
| `POST` | `/v1/merchants/{merchantuuid}/cases/{caseNum}/reply` | Post a reply to an existing case | `X-Api-Key` + `X-User-ID` |
| `PUT` | `/v1/merchants/{merchantuuid}/cases/{caseNum}/read` | Mark a case as read | `X-Api-Key` + `X-User-Type` |
| `GET` | `/v1/merchants/{merchantuuid}/case_counts/unread` | Get the count of unread cases for a merchant | `X-Api-Key` |

### Email Attachments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/merchants/{merchantuuid}/cases/{caseNum}/emails/{emailId}/attachments` | Upload an attachment to a case email | `X-Api-Key` + `Content-Type` + `File-Name` headers |
| `GET` | `/v1/merchants/{merchantuuid}/cases/{caseNum}/emails/{emailId}/attachments/{attId}/data` | Download an attachment by ID | `X-Api-Key` |

### Refund Cases

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/merchants/{merchantuuid}/refundcases` | List refund cases with pagination, date-range, sort, status, and isClosed filters | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/refundcases/{caseNum}` | Retrieve a single refund case | `X-Api-Key` |
| `PUT` | `/v1/merchants/{merchantuuid}/refundcases/{caseId}/{refundStatus}` | Update refund case status with rejection comments | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/refund_counts/unread` | Get count of unread refund cases | `X-Api-Key` |

### Deal Approval Cases

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/merchants/{merchantuuid}/deals/{dealuuid}/edits` | Create a deal-edit approval case | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/deals/{dealuuid}/edits/{caseId}` | Retrieve a deal-edit approval case | `X-Api-Key` |
| `PUT` | `/v1/merchants/{merchantuuid}/deals/{dealuuid}/edits/{caseId}` | Update deal-edit approval case status | `X-Api-Key` |

### Callback and RRDP (DAC7) Cases

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/merchants/{merchantuuid}/callbackcase` | Create a callback request case | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/callbackcase/count` | Get count of open callback cases | `X-Api-Key` |
| `POST` | `/v1/merchants/{merchantuuid}/rrdpcase` | Create a DAC7/RRDP completion case | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/rrdpcase/count` | Get count of open RRDP cases | `X-Api-Key` |

### Feedback / General Case Creation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/merchants/{merchantuuid}/feedback` | Create a feedback/general case (echo-type classification) | `X-Api-Key` + `X-User-ID` + `X-User-Type` + `X-User-Roles` |

### Knowledge Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/km/bootstrap` | Bootstrap knowledge management session | `X-Auth-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/topics` | List knowledge topics | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/topics/{topicId}` | Get a single topic by ID | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/topics/{topicId}/articles` | List articles in a topic | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/topics/{topicId}/articles/{articleId}` | Get a single article | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/topics/{topicId}/articles/{articleId}/related` | Get related articles | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/articles/popular` | Get popular articles | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/articles/suggested` | Get suggested articles by issue sub-category | `X-Api-Key` + `X-User-ID` |
| `GET` | `/v1/merchants/{merchantuuid}/km/search` | Full-text search across knowledge articles | `X-Api-Key` + `X-User-ID` |

### Merchant Configuration and Support

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/merchants/{merchantuuid}/issues` | List issue categories for case creation | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/issues/{id}` | List sub-categories for an issue category | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/contacts` | Get merchant support contact details | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/options` | Get merchant case options/configuration | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/support_tree` | Get support tree configuration by client category and case owner type | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/bankinginfostatus` | Get banking/payment information status | `X-Api-Key` |
| `GET` | `/v1/merchants/{merchantuuid}/features` | Get feature flags for a merchant | `X-Api-Key` + `X-User-ID` + `X-User-Type` + `X-User-Roles` |
| `GET` | `/v1/merchants/{merchantuuid}/is_eligible_for_inbox` | Check if merchant is eligible for inbox (deprecated) | `X-Api-Key` + `X-User-ID` |

## Request/Response Patterns

### Common headers

- `X-Api-Key` — required on all endpoints; identifies the calling client by role (`read` or `write`)
- `X-User-ID` — UUID of the acting user; required on reply, feedback, and knowledge management endpoints
- `X-User-Type` — type of user (merchant, internal); required on read-mark and feature endpoints
- `X-User-Roles` — CSV list of user roles; required on features and feedback endpoints
- `X-Auth-ID` — UUID for knowledge bootstrap authentication

### Error format

> No evidence found in codebase of a standardised error envelope beyond standard Dropwizard/JTier HTTP error responses.

### Pagination

List endpoints (`/cases`, `/refundcases`) support:
- `page` (integer, 1-based)
- `perPage` (integer)
- `startDate` / `endDate` (string date filters)
- `sort` (string field name)
- `status` (string)

Knowledge management search supports `page`, `per_page` (default 1000), `include_meta`, and `addArticleDescription`.

## Rate Limits

> No rate limiting configured in the discovered codebase.

## Versioning

URL path versioning is used: all endpoints are prefixed with `/v1`. No evidence of multiple active API versions.

## OpenAPI / Schema References

- OpenAPI 2.0 spec: `doc/swagger/swagger.yaml`
- Service discovery resource descriptor: `doc/service_discovery/resources.json`
- Server stub spec (Maven source): `src/main/resources/api/server/echo-service.yaml`
- Salesforce client spec (Maven source): `src/main/resources/api/clients/force.yaml`
- Issues translations client spec (Maven source): `src/main/resources/api/clients/issuesTranslations.yaml`

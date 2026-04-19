---
service: "groupon-monorepo"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, websocket, stomp]
auth_mechanisms: [oauth2, jwt, cookie-session, api-key, hmac]
---

# API Surface

## Overview

The Encore Platform exposes a large, auto-generated REST API surface through the Encore framework. Each backend service defines its APIs using Encore's `api()` decorator, which auto-generates OpenAPI specs and typed TypeScript clients consumed by the frontend applications. The platform uses a layered authentication model: Google OAuth for user login, JWT tokens for session management, cookie-based auth for browser clients, and HMAC-signed API tokens for service-to-service calls. The Go backend provides separate REST endpoints for search and recommendations. Python microservices expose FastAPI endpoints behind a shared nginx reverse proxy.

## Endpoints

### Authentication & Authorization

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/authentication.login` | Initiate Google OAuth login flow | Public |
| POST | `/authentication.callback` | OAuth callback and JWT issuance | Public |
| GET | `/authentication.me` | Get current user profile | Cookie/JWT |
| POST | `/authorization.checkPermission` | Check user permission for resource | Cookie/JWT |
| POST | `/api_tokens.create` | Issue HMAC-signed API token | Cookie/JWT |
| POST | `/api_tokens.validate` | Validate API token | API Key |

### Deal Management (B2B)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deal.list` | List deals with filtering and pagination | Cookie/JWT |
| GET | `/deal.get` | Get deal details by ID | Cookie/JWT |
| POST | `/deal.create` | Create new deal | Cookie/JWT |
| PUT | `/deal.update` | Update deal properties | Cookie/JWT |
| POST | `/deal.publish` | Publish deal version | Cookie/JWT |
| POST | `/deal_sync.sync` | Synchronize deal to Continuum DMAPI | Cookie/JWT |
| GET | `/deal_performance.metrics` | Get deal performance metrics | Cookie/JWT |
| GET | `/deal_alerts.list` | List deal performance alerts | Cookie/JWT |

### Account & Merchant Management (B2B)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/accounts.list` | List merchant accounts | Cookie/JWT |
| GET | `/accounts.get` | Get account details | Cookie/JWT |
| POST | `/accounts.syncFromSalesforce` | Sync account from Salesforce | Cookie/JWT |
| GET | `/brands.list` | List brands with metrics | Cookie/JWT |
| GET | `/umapi.*` | Proxy to Continuum Universal Merchant API | Cookie/JWT |
| GET | `/bhuvan.*` | Proxy to Continuum Bhuvan merchant data | Cookie/JWT |

### AI & Content Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/ai-gateway.chat` | Centralized LLM chat proxy (OpenAI/Anthropic) | Cookie/JWT |
| POST | `/ai-gateway.complete` | LLM completion proxy with Langfuse tracing | Cookie/JWT |
| POST | `/aidg_aiaas.infer` | Python AI-as-a-Service inference proxy | Cookie/JWT |
| POST | `/gen_ai.generate` | Generate AI content for core flows | Cookie/JWT |

### Core Platform Services

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/email.send` | Send email via SendGrid | Internal |
| POST | `/sms.send` | Send SMS via Twilio | Internal |
| POST | `/notifications.create` | Create push notification | Cookie/JWT |
| GET | `/notifications.list` | List user notifications | Cookie/JWT |
| POST | `/video.upload` | Upload video for Mux processing | Cookie/JWT |
| POST | `/images.upload` | Upload and process image | Cookie/JWT |
| GET | `/big-query.query` | Execute BigQuery analytics query | Cookie/JWT |
| GET | `/translations.list` | List translations for locale | Cookie/JWT |
| GET | `/feature-flags.list` | List feature flags | Cookie/JWT |
| GET | `/auditlog.list` | Query audit log entries | Cookie/JWT |
| WS | `/websocket.connect` | WebSocket connection for real-time updates | Cookie/JWT |

### Go Backend -- Search & Recommendations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/recommendations` | Autocomplete suggestions and deal recommendations | Public |
| POST | `/deals` | Search deals with query preprocessing | Public |
| POST | `/deals/batch` | Batch deal search | Public |

### Python Microservices (AI/ML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/aiaas-deal-content/infer` | AI deal content generation | API Key |
| POST | `/aiaas-deal-structure/infer` | AI deal structure inference | API Key |
| POST | `/aiaas-image-classification/infer` | Image classification | API Key |
| POST | `/aiaas-image-scraper/scrape` | Web image scraping | API Key |
| POST | `/aiaas-merchant-quality/infer` | Merchant quality scoring | API Key |
| POST | `/aiaas-merchant-priority/infer` | Merchant priority ranking | API Key |
| POST | `/aiaas-google-scraper/scrape` | Google business data scraping | API Key |
| POST | `/aiaas-social-scraper/scrape` | Social media data scraping | API Key |
| POST | `/aiaas-top-deals/infer` | Top deals ranking | API Key |
| POST | `/aiaas-inferpds-unified/infer` | Unified PDS inference | API Key |

## Request/Response Patterns

### Common headers
- `Authorization: Bearer <JWT>` for API token auth
- Cookie-based session for browser clients (managed by Encore gateway)
- `X-Request-ID` for request correlation
- `Content-Type: application/json` for all REST endpoints

### Error format
Encore services return standardized error responses:
```json
{
  "code": "not_found",
  "message": "Deal not found",
  "details": {}
}
```
Error codes follow Encore's built-in error code system (not_found, permission_denied, invalid_argument, internal, etc.).

### Pagination
Services that return lists use cursor-based pagination:
```json
{
  "items": [...],
  "totalCount": 1234,
  "pagination": {
    "pageSize": 20,
    "nextCursor": "eyJpZCI6MTAwfQ=="
  }
}
```

## Rate Limits

No explicit rate limiting is configured at the application layer. Rate limiting is handled at the infrastructure level by Encore Cloud and the API gateway.

## Versioning

The TypeScript backend does not use URL-path versioning; all endpoints are exposed at the service level via Encore's routing. The Go backend uses URL-path versioning (`/v1/recommendations`). Python microservices are unversioned.

## OpenAPI / Schema References

- TypeScript backend OpenAPI spec is auto-generated by Encore CLI (`pnpm gen` / `pnpm generate:openapi`)
- Generated TypeScript client: `packages/encore-client/` (consumed by all frontends)
- Generated Go TypeScript client: `packages/encore-client-go/`
- Generated Python TypeScript client: `packages/python-services-client/`
- Swagger UI is embedded in the admin frontend for interactive API exploration

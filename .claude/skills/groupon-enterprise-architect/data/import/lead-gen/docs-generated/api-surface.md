---
service: "lead-gen"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, internal]
auth_mechanisms: [api-key, service-auth]
---

# API Surface

## Overview

LeadGen Service exposes internal REST APIs consumed by n8n workflows and operational tooling. The API enables triggering scraping jobs, querying lead status, managing outreach campaigns, and monitoring pipeline health. The service also acts as an API client to five external systems (Apify, inferPDS, merchantQuality, Mailgun, Salesforce).

## Endpoints

### Workflow Trigger Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/leads/scrape` | Trigger a new Apify scraping job for a given region or category | service-auth |
| POST | `/api/leads/enrich` | Trigger enrichment pipeline for a batch of scraped leads | service-auth |
| POST | `/api/leads/outreach` | Trigger an outreach campaign for qualified leads | service-auth |
| POST | `/api/leads/sync-crm` | Trigger Salesforce sync for outreach-qualified leads | service-auth |

### Lead Query Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/leads` | List leads with filtering by status, score, region | service-auth |
| GET | `/api/leads/{id}` | Get detailed lead record with enrichment and outreach state | service-auth |
| GET | `/api/leads/{id}/history` | Get full lifecycle history for a lead | service-auth |

### Pipeline Status Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/pipeline/status` | Current pipeline status (scrape queue depth, enrichment backlog, outreach pending) | service-auth |
| GET | `/api/health` | Health check for readiness and liveness probes | none |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json`
- `Authorization: Bearer <service-token>` for authenticated endpoints

### Error format

Standard JSON error response:
```json
{
  "error": "error_code",
  "message": "Human-readable description",
  "timestamp": "ISO-8601"
}
```

### Pagination

Cursor-based pagination for list endpoints using `?cursor=<token>&limit=<n>` query parameters.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Scrape trigger | 10 requests | per minute |
| Enrichment trigger | 50 requests | per minute |
| Query endpoints | 100 requests | per minute |

> Rate limits are internal safeguards to prevent overloading external providers. Apify, Mailgun, and Salesforce impose their own upstream rate limits.

## Versioning

No explicit API versioning strategy is currently implemented. All endpoints are served under the `/api/` prefix without version numbering.

## OpenAPI / Schema References

> OpenAPI specification is not yet published for this service. API contracts are documented in the service repository.

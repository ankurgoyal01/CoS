---
service: "email_campaign_management"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

CampaignManagement exposes a synchronous REST API over HTTPS/JSON. All endpoints are internal-facing — consumed by campaign orchestrators and tooling clients within the Continuum platform. The API covers campaign and send lifecycle management, audience targeting configuration, program and event type catalog management, scheduling metadata, and operational health checks.

## Endpoints

### Campaigns

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/campaigns` | List campaigns with optional filters | Internal |
| POST | `/campaigns` | Create a new campaign | Internal |
| GET | `/campaigns/:id` | Retrieve a single campaign by ID | Internal |
| PUT | `/campaigns/:id` | Update an existing campaign | Internal |
| DELETE | `/campaigns/:id` | Archive/delete a campaign | Internal |
| POST | `/campaigns/:id/rolloutTemplateTreatment` | Roll out an A/B treatment variant for a campaign template | Internal |

### Campaign Sends

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/campaignsends` | List campaign send records | Internal |
| POST | `/campaignsends` | Create a new campaign send record | Internal |
| GET | `/campaignsends/:id` | Retrieve a single campaign send record | Internal |
| PUT | `/campaignsends/:id` | Update campaign send status or metadata | Internal |

### Business Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/businessgroups` | List business group definitions | Internal |
| POST | `/businessgroups` | Create a business group | Internal |
| GET | `/businessgroups/:id` | Retrieve a business group | Internal |
| PUT | `/businessgroups/:id` | Update a business group | Internal |

### Programs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/programs` | List programs | Internal |
| POST | `/programs` | Create a program | Internal |
| GET | `/programs/:id` | Retrieve a program | Internal |
| PUT | `/programs/:id` | Update a program | Internal |
| DELETE | `/programs/:id` | Archive a program | Internal |

### Deal Queries

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dealqueries` | List deal query definitions | Internal |
| POST | `/dealqueries` | Create a deal query | Internal |
| GET | `/dealqueries/:id` | Retrieve a deal query | Internal |
| PUT | `/dealqueries/:id` | Update a deal query | Internal |
| DELETE | `/dealqueries/:id` | Archive a deal query | Internal |

### Event Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/eventtypes` | List event type catalog entries | Internal |
| POST | `/eventtypes` | Create an event type | Internal |
| GET | `/eventtypes/:id` | Retrieve an event type | Internal |

### Scheduling

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/calendar` | Retrieve campaign scheduling calendar metadata | Internal |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Liveness check — returns service alive status | None |
| GET | `/preflight` | Dry-run campaign send validation against Rocketman | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on POST/PUT requests
- Internal service-to-service auth headers as required by Continuum platform conventions

### Error format

> No evidence found in the inventory. Standard Express JSON error responses are expected (`{ error: "...", message: "..." }`).

### Pagination

> No evidence found in the inventory for explicit pagination conventions. List endpoints (`/campaigns`, `/campaignsends`, etc.) likely accept query parameters for filtering.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning is used. The API is versioned implicitly by deployment; consumers must coordinate with the Campaign Management team on breaking changes.

## OpenAPI / Schema References

> No evidence found. No OpenAPI spec, proto files, or GraphQL schema discovered in the inventory.

---
service: "ckod-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth-header, super-token]
---

# API Surface

## Overview

ckod-ui exposes a set of Next.js API route handlers (under `/api`) that serve as the backend for the React frontend. All API calls from the UI go through these routes via RTK Query (`ckodApi` base slice at `NEXT_PUBLIC_CKOD_UI_URL`). The API routes in turn proxy to external services (JIRA, Keboola, Deploybot, GitHub, Vertex AI, JSM) and query the owned MySQL databases via Prisma. Authentication is based on the `x-grpn-email` header (OAuth) and an optional `ckod-token` super-user header.

## Endpoints

### SLO / SLA Job Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/keboola-slo-job-detail` | Fetch Keboola SLA job details with optional date/status filters | OAuth header |
| `GET` | `/api/keboola-slo-job-detail/{id}` | Fetch a single Keboola SLA job detail by key | OAuth header |
| `GET` | `/api/edw-sla-details` | Fetch EDW SLA job details | OAuth header |
| `GET` | `/api/sem-sla-details` | Fetch SEM SLA job details | OAuth header |
| `GET` | `/api/rm-sla-details` | Fetch RM SLA job details | OAuth header |
| `GET` | `/api/op-sla-details` | Fetch OP SLA job details | OAuth header |
| `GET` | `/api/cdp-sla-details` | Fetch CDP SLO job details | OAuth header |
| `GET` | `/api/mds-feeds-sla-details` | Fetch MDS Feeds SLO job details | OAuth header |

### SLO Definition Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/slo-definitions?type={type}` | List SLO definitions by platform type with pagination and search | OAuth header |
| `POST` | `/api/slo-definitions` | Create a new SLO definition for a given platform | OAuth header |
| `PATCH` | `/api/slo-definitions` | Update one or more SLO definitions (including Airflow bulk update) | OAuth header |
| `DELETE` | `/api/slo-definitions?type={type}&id={id}` | Soft-delete or hard-delete an SLO definition | OAuth header |

### Deployments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/deployments/all` | List deployments with filters (jiraKey, date range, status, project) | OAuth header |
| `GET` | `/api/deployments/describe` | Fetch Keboola branch deployment details | OAuth header |
| `GET` | `/api/deployments/diff-link` | Get GitHub diff link for a Deploybot URL | OAuth header |
| `GET` | `/api/deployments/metadata` | Get deployment metadata from Deploybot | OAuth header |
| `GET` | `/api/deployments/environment` | Get environment info for a deployment | OAuth header |
| `GET` | `/api/deployments/sox` | Check whether a deployment is SOX-scoped | OAuth header |
| `GET` | `/api/deployments/sox/requester/{deploymentTicketId}` | Get SOX requester for a deployment ticket | OAuth header |
| `GET` | `/api/deployments/diff-authors` | Get list of authors from a GitHub diff | OAuth header |
| `GET` | `/api/deployments/initial-release` | Check whether a repo has had an initial release | OAuth header |
| `GET` | `/api/deployments/pipeline-authors` | Get pipeline authors for a repo | OAuth header |
| `GET` | `/api/deployments/create/keboola` | Create a Keboola deployment (triggers Jira + DB record) | OAuth header |
| `GET` | `/api/deployments/create/airflow` | Create an Airflow pipeline deployment (triggers Jira + DB record) | OAuth header |

### Incidents

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/dnd-critical-incident` | List DND critical incidents with filters (date, severity, status, JIRA key) | OAuth header |

### Cost Alerts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/cost-alert/{date}` | Get cost alert data for a specific date | OAuth header |

### Vertex AI Agent

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/agents` | List available Vertex AI reasoning engine agents | OAuth header |
| `GET` | `/api/sessions?engineId={id}` | List sessions for a given agent engine | OAuth header |
| `POST` | `/api/sessions?engineId={id}` | Create a new agent session | OAuth header |
| `DELETE` | `/api/sessions?engineId={id}&sessionId={id}` | Delete an agent session | OAuth header |
| `POST` | `/api/chat?engineId={id}&sessionId={id}` | Send a message to an agent (supports streaming) | OAuth header |
| `GET` | `/api/session-events?engineId={id}&sessionId={id}` | Retrieve session event history | OAuth header |

### Hand It Over

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/handitover/on-call` | Retrieve current and next on-call person from JSM | PRE team only |
| `GET` | `/api/handitover/jsm-alerts` | Fetch active JSM alerts (supports JQL filter) | PRE team only |
| `GET` | `/api/handitover/jira-search` | Search JIRA issues with JQL | PRE team only |
| `GET` | `/api/handitover/check-access` | Check if the requesting user has Hand It Over access | OAuth header |
| `POST` | `/api/handitover/generate-notes` | Generate AI handover notes via LiteLLM | PRE team only |
| `POST` | `/api/handitover/share-chat` | Send handover chat cards to Google Chat | PRE team only |

### Active Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/active-user` | List all active users from MySQL | OAuth header |

### Logging

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/log` | Receive client-side logs and write to server log file via Winston | OAuth header |

## Request/Response Patterns

### Common headers
- `x-grpn-email` — identifies the authenticated user (extracted from OAuth session); required for all protected routes
- `ckod-token` — super-user bypass token; must match `CKOD_SUPER_TOKEN` environment variable

### Error format
All error responses follow the pattern:
```json
{
  "error": true,
  "message": "Human-readable error message",
  "details": "Optional technical detail string"
}
```
HTTP status codes: `400` for bad request, `401`/`403` for auth failures, `500` for server errors.

### Pagination
SLO definitions endpoint (`/api/slo-definitions`) supports `limit` and `offset` query parameters for cursor-style pagination. Response includes `total`, `limit`, and `offset` fields.

## Rate Limits

> No rate limiting is configured in ckod-ui itself. Upstream services (Keboola, JIRA, Vertex AI) may apply their own rate limits.

## Versioning

No explicit API versioning strategy. Routes are stable paths under `/api`. Legacy routes retain snake_case names (e.g., `/slo_dashboard`), while new routes use kebab-case.

## OpenAPI / Schema References

> No OpenAPI or GraphQL schema files are present in the repository. Route handler types are defined using TypeScript interfaces in `src/types/api.ts` and within individual API slice files under `src/apiSlices/`.

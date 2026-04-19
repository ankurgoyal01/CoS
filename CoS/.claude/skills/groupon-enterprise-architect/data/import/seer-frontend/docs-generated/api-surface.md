---
service: "seer-frontend"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

Seer Frontend is a browser-rendered SPA. It does not expose an HTTP API to other services — it is a consumer, not a provider. All backend communication is made from the browser to the `seer-service` backend, routed through the `/api` path prefix defined in `src/constants.js` (`BASE_HTTP_URL = "/api"`). In production, the Vite preview server or container networking forwards `/api` requests to the backend. During development, `vite.config.js` proxies `/api` to `http://seer-service.staging.service.us-central1.gcp.groupondev.com`.

The endpoints documented below are the backend API paths consumed by this frontend, derived from `src/` source files.

## Endpoints

### Code Quality Metrics (SonarQube)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/sonarqube/metrics` | Retrieve SonarQube metrics for all services; returns map of service name to metric values | None observed |

### Alert Metrics (OpsGenie)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/opsgenie/teams` | Retrieve list of OpsGenie teams (id, name) for the dropdown selector | None observed |
| GET | `/api/opsgenie/team/{teamId}/report_by_freq` | Retrieve weekly alert report for a team; query params: `startDate`, `endDate`, `frequency=weekly` | None observed |

### Sprint Metrics (Jira)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/jira/boards` | Retrieve list of Jira sprint boards (id, name) for selector | None observed |
| GET | `/api/jira/get_board_sprint_report/{boardId}` | Retrieve per-sprint report for a board; returns array with `name`, `numDefects`, `volatility`, `KTLOBugsPercentage`, `featuresPercentage` | None observed |

### Incident / SEV Metrics (Jira)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/serviceportal/owners` | Retrieve map of service name to service owner; used for service and owner dropdowns | None observed |
| GET | `/api/jira/incidents` | Retrieve incident counts; query params: `service`, `owner`, `startDate`, `endDate`, `minSEV`, `maxSEV`; returns `daily` and `weekly` maps | None observed |

### Jenkins Build Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/jenkins/build/report` | Retrieve Jenkins build time data; query params: `startDate`, `endDate`, `service`; returns `daily` and `weekly` maps | None observed |

### Pull Request Merge Time Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/seer/pullreq/report` | Retrieve PR merge time data; query params: `startDate`, `endDate`, `service`; returns `daily` and `weekly` maps | None observed |

### Deployment Time Metrics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/deploybot/report` | Retrieve deployment average time data; query params: `startDate`, `endDate`, `service`; returns `daily` and `weekly` maps | None observed |

## Request/Response Patterns

### Common headers

All fetch calls send `Content-Type: application/json`. Some calls also include `Access-Control-Allow-Origin: *` (client-set; no functional effect on same-origin requests in production).

### Error format

> No evidence found in codebase. Errors are caught in `.catch()` blocks and logged to browser console only. No user-visible error state is rendered.

### Pagination

> No evidence found in codebase. All responses are returned in a single JSON payload without pagination.

## Rate Limits

> No rate limiting configured at the frontend layer. Rate limiting, if any, is enforced by the backend.

## Versioning

No API versioning strategy is used at the frontend. All endpoint paths are unversioned. The `BASE_HTTP_URL` constant (`/api`) is the sole configuration point in `src/constants.js`.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in this repository.

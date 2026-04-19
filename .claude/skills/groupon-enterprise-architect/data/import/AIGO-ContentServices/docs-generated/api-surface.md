---
service: "AIGO-ContentServices"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [cors-origin-allowlist]
---

# API Surface

## Overview

AIGO-ContentServices exposes four distinct HTTP/REST APIs — one per deployable component. All backend services are FastAPI applications with OpenAPI docs available at `/docs`. The frontend Next.js application is accessed directly by users via browser and proxies requests to the backend services. CORS is configured with an explicit origin allowlist across all services.

---

## Content Generator Service (port 5000)

Architecture ref: `continuumContentGeneratorService` / `cgGenerationApi`

### Content Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/generate` | Run a multi-step LLM content generation flow; returns intermediate steps, final result, and global cost | CORS origin check |

### Salesforce Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/deals` | **[Deprecated]** Fetch deals from a Salesforce report (truncated data) | CORS origin check |
| `POST` | `/salesforce/launch-job` | Initiate a Salesforce bulk query job for deal data | CORS origin check |
| `GET` | `/salesforce/store-results/{job_id}` | Fetch results from a specific Salesforce bulk job and save to CSV | CORS origin check |
| `GET` | `/salesforce/poll-job` | Launch a Salesforce job, poll until completion, and store results (configurable `max_attempts`, `interval`, `initial_wait`) | CORS origin check |
| `GET` | `/salesforce/get-stored-data` | Return stored Salesforce CSV data as JSON, wrapped in `{"deals": [...]}` | CORS origin check |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Service liveness check; returns `{"status": "OK"}` | None |

---

## Web Scraper Service (port 8000)

Architecture ref: `continuumWebScraperService` / `wsScraperApi`

### Scraping

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Root welcome message | None |
| `POST` | `/crawl` | Start a web crawl; accepts `start_url`, `max_pages`, `file`, and `agent_versions` (version keys: `clean_text`, `extract_usps`, `filter_links`, `manage_duplicates`, `quality_content`); returns `scraper_results`, `top10_usps`, `global_cost` | CORS origin check |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Service liveness check; returns `{"status": "OK"}` | None |

---

## Prompt Database Service (port 7000)

Architecture ref: `continuumPromptDatabaseService` / `pdAgentsApi` + `pdGuidelinesApi`

### Agents

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/` | Root welcome message | None |
| `POST` | `/agents/` | Create a new agent configuration | CORS origin check |
| `GET` | `/agents/` | List agent configurations (supports `skip`, `limit` pagination) | CORS origin check |
| `GET` | `/agents/{agent_id}` | Retrieve a single agent by integer ID | CORS origin check |
| `PUT` | `/agents/{agent_id}` | Update an existing agent | CORS origin check |
| `DELETE` | `/agents/{agent_id}` | Delete an agent by ID | CORS origin check |
| `POST` | `/agents/query` | Query agents by list of `{agent_name, version}` criteria | CORS origin check |

### L1 Guidelines

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/guidelines/l1/` | Retrieve all L1 guidelines (deal-level and section-level) | CORS origin check |
| `POST` | `/guidelines/l1/entry/` | Create a new L1 guideline entry | CORS origin check |
| `GET` | `/guidelines/l1/entry/{guideline_id}` | Retrieve a specific L1 guideline by ID | CORS origin check |
| `PUT` | `/guidelines/l1/entry/{guideline_id}` | Update an L1 guideline | CORS origin check |
| `DELETE` | `/guidelines/l1/entry/{guideline_id}` | Delete an L1 guideline | CORS origin check |

### L2 Guidelines

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/guidelines/l2/{category}` | Retrieve L2 guidelines by category name | CORS origin check |
| `GET` | `/guidelines/l2/pds/{pds}` | Retrieve L2 guidelines by PDS code (looks up category from `data/pds_conversion.csv`) | CORS origin check |

### TG Guidelines

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/guidelines/tg/{taxonomy_group}` | Retrieve TG (taxonomy group) guidelines | CORS origin check |
| `GET` | `/guidelines/tg/pds/{pds}` | Retrieve TG guidelines by PDS code (looks up taxonomy group from `data/pds_conversion.csv`) | CORS origin check |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Service liveness check; returns `{"status": "OK"}` | None |

---

## Frontend Content Generator (port 3000)

Architecture ref: `continuumFrontendContentGenerator`

The Next.js application is a browser-accessed web UI. It does not expose a public API but uses Next.js route handlers and environment-variable-configured base URLs (`NEXT_PUBLIC_GENERATOR_URL`, `NEXT_PUBLIC_SCRAPER_URL`, `NEXT_PUBLIC_PROMPTDB_URL`) to proxy calls to backend services.

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/grpn/healthcheck` | Frontend health endpoint (Next.js route handler) |

---

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for all POST/PUT request bodies
- `Origin` header checked against CORS allowlist: `http://localhost:3000`, `https://aigenerationtool-frontend.eu.ngrok.io`, `https://aigo-contentservices.staging.service.us-central1.gcp.groupondev.com`, `https://aigo-contentservices.production.service.us-central1.gcp.groupondev.com`, and regex `https://.*\.(groupondev|groupon)\.com`

### Error format
FastAPI default: `{"detail": "<error message string>"}` with appropriate HTTP status code (400, 401, 404, 408, 500).

### Pagination
`/agents/` supports offset pagination via `skip` (default 0) and `limit` (default 10) query parameters.

## Rate Limits

> No rate limiting configured at the application layer. External LLM and Salesforce APIs have their own rate limits.

## Versioning

No URL-based API versioning is implemented. Agent prompt versions are tracked as data within the `agent_configurations` table (e.g., `v0`, `v3.1`) and selected at call time via the `/agents/query` endpoint.

## OpenAPI / Schema References

All FastAPI services serve interactive OpenAPI documentation at `<service-base-url>/docs`. No static OpenAPI spec files are committed to the repository.

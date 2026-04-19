---
service: "ckod-backend-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 0
---

# Integrations

## Overview

CKOD Backend JTier has five external dependencies, all accessed over HTTPS/REST using Apache HttpClient and `HttpURLConnection`. There are no internal Groupon service dependencies beyond the owned MySQL database. All external calls originate from the `continuumCkodIntegrationClients` component. No circuit breaker library is present in the codebase; failure handling is propagated as `IOException` to the calling domain service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Keboola Cloud (job queue) | REST | Poll job runs for all onboarded projects | yes | `keboola` |
| Keboola Cloud (storage API) | REST | Retrieve branches, components, project descriptions, and workspace owners | yes | `keboola` |
| Jira Cloud | REST | Create and link deployment tickets; look up user account IDs and on-call schedules | yes | `continuumJiraService` |
| GitHub Enterprise | REST | Generate diff links and retrieve commit authors between two refs; fetch SOX scoping CSV | yes | `githubEnterprise` |
| Google Chat | REST (Webhook) | Send deployment and incident notification messages | no | `googleChat` |
| Deploybot (via edge proxy) | REST | Fetch last successful deployment metadata for staging and production | no | `unknownDeploybot_81ab3f0d` |

### Keboola Cloud Detail

- **Protocol**: HTTPS/REST
- **Base URLs**: `https://queue.groupon.keboola.cloud` (job queue), `https://connection.groupon.keboola.cloud` (storage/branches/components)
- **Auth**: Per-project API token stored in the `keboola_project` table, passed as `X-StorageAPI-Token` header
- **Purpose**: Polls `/search/jobs` endpoint for new and non-terminal job runs; retrieves branch listings from `/v2/storage/dev-branches/`; fetches component configs from `/v2/storage/branch/{branchId}/components`; updates project descriptions via `/v2/storage/branch/default/metadata`; fetches workspace owner information from `/v2/storage/workspaces`
- **Failure mode**: `IOException` propagated to worker; job update metrics are recorded via `KeboolaRequestMetrics`; polling stops for the affected project until the next scheduled cycle
- **Circuit breaker**: No

### Jira Cloud Detail

- **Protocol**: HTTPS/REST
- **Base URL**: Configured via `JIRA_SERVER` environment variable (e.g., `https://<jira-server>/rest/api/2/`)
- **Auth**: Bearer token from `JIRA_AUTH` environment variable; also uses Atlassian JSM API with endpoint `https://api.atlassian.com/jsm/ops/api/d22269b5.../v1/schedules/.../on-calls` for on-call lookups
- **Purpose**: Creates GPROD deployment issues (`POST /rest/api/2/issue`); creates issue links for blockers and action items (`POST /rest/api/2/issueLink`); looks up Jira account IDs by username (`GET /rest/api/3/user/search`)
- **Failure mode**: Non-2xx response causes `IOException`; deployment creation is aborted and error is returned to caller
- **Circuit breaker**: No

### GitHub Enterprise Detail

- **Protocol**: HTTPS/REST
- **Base URL**: `https://api.github.groupondev.com`
- **Auth**: Bearer token from `GITHUB_API_TOKEN` environment variable; `Authorization: Bearer <token>` header; `X-GitHub-Api-Version: 2022-11-28`
- **Purpose**: `GET /repos/{org}/{repo}/compare/{base}...{head}` for diff author resolution; `GET /repos/{org}/{repo}/contributors` for pipeline author lists; fetches SOX scoping CSV from `https://api.github.groupondev.com/repos/asadauskas/pipeline-sox-scopings/contents/PIPELINES_PROD.csv`
- **Failure mode**: `IOException` propagated; deployment diff resolution fails gracefully
- **Circuit breaker**: No

### Google Chat Detail

- **Protocol**: HTTPS/REST (webhook POST)
- **Base URL**: Webhook URL provided at runtime (not hardcoded in source)
- **Auth**: Webhook URL contains authentication in the URL path
- **Purpose**: Sends structured JSON messages for deployment start, completion, and incident notifications via `HttpClient.postChatMessage()`
- **Failure mode**: Non-2xx response throws `IOException`; notification failure does not block deployment ticket creation
- **Circuit breaker**: No

### Deploybot (Edge Proxy) Detail

- **Protocol**: HTTPS/REST
- **Base URL**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com/v1/last_successful_deployments/{org}/{repo}`
- **Auth**: `Host: deploybot.production.service` header; SSL verification disabled for this call
- **Purpose**: Retrieves most recent production and staging deployment records (version, SHA, date) for a given GitHub repository
- **Failure mode**: `IOException` propagated to caller; SOX and diff-link resolution degrades gracefully
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found in codebase. CKOD Backend JTier has no dependencies on other internal Groupon services beyond its owned MySQL database.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include the CKOD UI and on-call automation tooling that call the REST API endpoints.

## Dependency Health

No automated health checks, retries, or circuit breakers are configured for external dependencies. Failures are surfaced as exceptions and logged via Steno. Keboola polling success/failure metrics are tracked via `KeboolaRequestMetrics` counters (`markSuccessfulJobsRequestEvent`, `markFailedJobsRequestEvent`, etc.) and visible in the Wavefront dashboard.

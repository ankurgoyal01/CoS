---
service: "proxykong"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

ProxyKong integrates with six downstream systems. Two are external platforms (GitHub Enterprise and Jira), and four are internal Groupon services (api-proxy-config, Service Portal, Hybrid Boundary edge proxy, and the Robin reporting service). All integrations are synchronous HTTPS or HTTP calls; there is no message-bus usage. The service uses Kubernetes secrets to supply credentials for GitHub and Jira.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise (`github.groupondev.com`) | HTTPS REST | Creates feature branches and pull requests against `groupon-api/api-proxy-config` for route changes | yes | `githubEnterprise` |
| Jira (`jira.groupondev.com`) | HTTPS REST | Creates route request issues in project GAPI (ID `11500`, issue type `10700`) | yes | `continuumJiraService` |

### GitHub Enterprise Detail

- **Protocol**: HTTPS REST (`https://github.groupondev.com/api/v3`)
- **Base URL**: `https://github.groupondev.com/api/v3` (hardcoded as `GH_HOST` in `prHelper.ts`)
- **Auth**: Personal access token injected from Kubernetes secret `git-auth` as `GITHUB_TOKEN` environment variable; mounted at `/secrets/git/github_token.json`
- **Purpose**: `scmGateway` / `PrHelper` creates a temporary branch from `master`, commits route config mutations, pushes the branch, and opens a pull request against `groupon-api/api-proxy-config`. The PR title includes the Jira issue key(s) for traceability.
- **Failure mode**: PR creation throws an exception caught by `handleIssueAndPRPromises`; the error is returned to the UI as a JSON error response. No retry logic is implemented.
- **Circuit breaker**: No evidence found in codebase.

### Jira Detail

- **Protocol**: HTTPS REST
- **Base URL**: Production Jira instance; credentials loaded from `/secrets/jira/jira.json`
- **Auth**: Jira credentials mounted from Kubernetes secret `jira-auth` at `/secrets/jira`; loaded via `require('/secrets/jira/jira')` in `jiraHelper.ts`
- **Purpose**: `issueTrackerGateway` / `jiraHelper.createIssue` creates a Jira issue with routing request metadata (region, environment, path, method, timeout values, ORR/GEARS compliance links, data classification) before the GitHub PR is submitted. The issue key is embedded in the PR title and body.
- **Failure mode**: Issue creation failure is caught in `handleIssueAndPRPromises`; PR creation is skipped if issue creation fails. The error is returned to the UI.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy Config Bundle | Filesystem / Git | Provides routing configuration data and mutation scripts at `/api-proxy-config/config_tools` | `continuumApiProxyConfigBundle` |
| Service Portal | HTTP REST | Validates service names and fetches service metadata (regulatory classifications, ORR, Slack channel) | `servicePortal` |
| Hybrid Boundary Edge Proxy | HTTP | Validates whether a service VIP is reachable at `{service}.staging.service` before a route change is submitted | `continuumHybridBoundaryEdgeProxy` |
| Robin Reporting Service | Service API (`@grpn/robin`) | Generates `PerformanceReport` data and sends emails via `EmailGenerator` for the Argus reporting module | `continuumRobinReportingService` |

### API Proxy Config Bundle Detail

- **Protocol**: Filesystem (cloned Git repo mounted at `/api-proxy-config`)
- **Base URL**: `/api-proxy-config/config_tools/` (Node.js `require` calls)
- **Auth**: GitHub token used to pull/push via `git remote set-url` in `bin/start-proxykong.sh`
- **Purpose**: All route read queries and all config mutations use scripts from this bundle. It is the authoritative source of routing data.
- **Failure mode**: If the local clone is stale or unreachable, read endpoints return stale data or throw synchronously.

### Service Portal Detail

- **Protocol**: HTTP REST
- **Base URL**: `http://service-portal.snc1/api/v2/services/{serviceName}`
- **Auth**: `GRPN-Client-ID: proxykong` header
- **Purpose**: Fetches service metadata including ORR, regulatory classifications, and Slack channel for enriching route change context.
- **Failure mode**: Errors are caught and returned as JSON to the caller.

### Hybrid Boundary Edge Proxy Detail

- **Protocol**: HTTP
- **Base URL**: `http://edge-proxy--staging--default.stable.us-west-1.aws.groupondev.com/grpn/hybrid-boundary`
- **Auth**: `Host` header set to `{service}.staging.service`
- **Purpose**: Validates that a proposed destination service VIP is registered and reachable; returns `true` or `false` to the UI form.
- **Failure mode**: HTTP errors return `false` (service not found).

## Consumed By

> Upstream consumers are tracked in the central architecture model. ProxyKong is an internal tool accessed by authenticated Groupon engineers via browser through the Hybrid Boundary ingress.

## Dependency Health

No circuit breakers or explicit health checks are implemented for downstream integrations. Failures surface as JSON error responses in the UI. Engineers should consult the Wavefront dashboard (`https://groupon.wavefront.com/dashboard/gapi-overview`) and ELK logs to diagnose integration failures.

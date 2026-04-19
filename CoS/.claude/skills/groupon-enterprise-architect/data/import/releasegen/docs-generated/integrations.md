---
service: "releasegen"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Releasegen has three external dependencies: Deploybot (deployment records), GitHub Enterprise (release and deployment management), and JIRA (release ticket tracking). All integrations use synchronous REST. There are no internal Continuum service-to-service dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Deploybot | REST (Retrofit) | Source of deployment records; queried by ID and by org/project | yes | `deploybotSystem_7f4e` |
| GitHub Enterprise | REST (kohsuke github-api + direct REST) | Creates/updates releases, deployment records, and deployment statuses | yes | `githubSystem_3a1b` |
| JIRA | REST (Retrofit) | Searches RE-project release tickets, adds labels, adds remote links | yes | `jiraSystem_9c2d` |

### Deploybot Detail

- **Protocol**: REST via Retrofit (`jtier-retrofit`)
- **Base URL / SDK**: Configured via `deploybot` block in the JTier YAML config file; endpoint resolved per environment via `JTIER_RUN_CONFIG`
- **Auth**: Configured in the per-environment secrets YAML file loaded at runtime
- **Purpose**: Provides the authoritative `DeploymentId` record for each deployment, including SHA, environment, region, JIRA ticket key, logbook ticket, deployer, and completion status
- **Failure mode**: Deployment publication fails with a `DeploymentNotFoundException`; the background worker logs the error and continues polling
- **Circuit breaker**: No evidence of circuit breaker configured

### GitHub Enterprise Detail

- **Protocol**: REST via `org.kohsuke:github-api` 1.314 for high-level operations; direct Retrofit `GitHubAPI` for release note generation and release creation where the library does not expose functionality
- **Base URL / SDK**: Configured via `github.endpoint` in the JTier YAML config (e.g., `github.groupondev.com`); supports both GitHub App credentials (`APP_PRIVATE_KEY`, `APPLICATION_ID`) and user token (`GITHUB_TOKEN`)
- **Auth**: GitHub App installation tokens (JWT-signed, managed by `com.groupon:github-app` 0.1.0); falls back to Bearer token for user credentials
- **Purpose**: Creates GitHub releases tagged to deployed SHAs, generates release notes from PR history using the `/repos/{org}/{repo}/releases/generate-notes` API, records GitHub Deployments and DeploymentStatuses for environment tracking, and rewrites JIRA ticket references as hyperlinks in release bodies
- **Failure mode**: Release creation or status update fails; the caller receives an error; no silent failure path is implemented
- **Circuit breaker**: No evidence of circuit breaker configured

### JIRA Detail

- **Protocol**: REST via Retrofit; base path is the JIRA REST API v2/v3
- **Base URL / SDK**: Configured via `jira` block in the JTier YAML config file; endpoint resolved per environment
- **Auth**: Configured in the per-environment secrets YAML file loaded at runtime
- **Purpose**: Searches the `RE` project for issues in `Done` status that have not yet been labeled `releasegen` (JQL: `project=RE AND status='Done' AND (labels is EMPTY OR labels!='releasegen')`); retrieves issue changelogs to determine the exact `Done` transition timestamp; adds the `releasegen` label to processed issues; adds remote links from JIRA tickets to the corresponding GitHub release
- **Failure mode**: Worker polling continues; individual issue failures are logged; JIRA's own timezone is used for date filtering (fetched via `GET /myself` at startup)
- **Circuit breaker**: No evidence of circuit breaker configured

## Internal Dependencies

> No evidence found in codebase. Releasegen has no runtime dependencies on other internal Continuum microservices.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Deploybot triggers deployment publication by calling `POST /deployment/{org}/{repo}/{id}` or the background worker self-triggers via JIRA polling. The admin UI is used directly by the Release Engineering team.

## Dependency Health

Releasegen uses Dropwizard's built-in health check infrastructure (provided by the jtier framework). Individual dependency health is verified at startup: JIRA's timezone is fetched via `GET /myself` to confirm connectivity. No retry or circuit breaker patterns are configured in the codebase; transient failures propagate as exceptions.

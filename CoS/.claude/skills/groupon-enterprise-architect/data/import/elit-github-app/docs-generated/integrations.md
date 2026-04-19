---
service: "elit-github-app"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

This service has a single external dependency: GitHub Enterprise. All interactions are bidirectional — GitHub Enterprise sends inbound webhooks to this service, and this service calls back to the GitHub Enterprise REST API to manage check runs and read repository content. There are no internal Groupon service dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | HTTPS REST + Webhook | Sends check suite/run events; receives check run creation, updates, and annotations; provides PR diffs and rule files | yes | `githubEnterprise` |

### GitHub Enterprise Detail

- **Protocol**: HTTPS (inbound webhook POST; outbound REST API calls)
- **Base URL / SDK**: Configured via `github.endPoint` in the application YAML config. Accessed through the `com.groupon:github-app` SDK (v0.1.0) and `org.kohsuke:github-api` (v1.314).
- **Auth**:
  - Inbound webhook authentication: HMAC-SHA256 signature validation using `github.secret` config value.
  - Outbound API authentication: GitHub App JWT (generated from `github.privateKey` and `github.applicationId`) exchanged for per-installation access tokens.
- **Purpose**:
  - Receives check suite lifecycle events (`requested`, `rerequested`) to trigger check creation.
  - Receives check run `created` event to trigger the ELIT scan.
  - Creates and updates check runs with status, conclusion, and inline file annotations.
  - Fetches PR diffs using `application/vnd.github.v3.diff` Accept header.
  - Reads ELIT rule files (`.elit.yml` and referenced rule files) from repository branches at the PR head SHA.
- **Failure mode**: If the GitHub Enterprise API is unavailable, check runs will fail to be created or updated. Errors during scan execution are caught and the check run is marked `SKIPPED` with an `Internal error` output. Webhook delivery failures are retried by GitHub's built-in retry mechanism.
- **Circuit breaker**: No circuit breaker configured.

## Internal Dependencies

> No evidence found in codebase. This service has no internal Groupon service dependencies.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| GitHub Enterprise | HTTPS Webhook | Delivers check suite and check run events to `/elit-github-app/webhook` |

> Upstream consumers are tracked in the central architecture model. The GitHub App installation determines which repositories have their PRs scanned.

## Dependency Health

No explicit health check, retry, or circuit breaker patterns are implemented for the GitHub Enterprise dependency. Error handling in `StartCheckActionHandler` catches all exceptions during scan execution and marks the check run as `SKIPPED` with an error message rather than crashing the service.

---
service: "webhooks-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

The Webhooks Service has four external dependencies, all of which are called synchronously during webhook processing. There are no internal Groupon service dependencies. GitHub Enterprise is both the event source (inbound webhooks) and a downstream API target (reads and writes). Slack, Jira, and Jenkins CI are write-heavy targets invoked by specific hook implementations. All four dependencies must be reachable for their respective hooks to succeed; failures in one do not block unrelated hooks from running.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | REST (HTTPS) | Reads `.webhooks.yml` config, PR data, statuses, labels, branches, teams, users; writes comments, labels, statuses, branches, PR merges | yes | `webhookSvc_githubClient` |
| Slack | REST (HTTPS) | Resolves users by email; sends direct messages and channel notifications | no | `webhookSvc_slackClient` |
| Jira Cloud | REST (HTTPS) | Reads issue state, transitions, sprint data, remote links; posts transitions, comments, and remote links | no | `webhookSvc_jiraClient` |
| Jenkins CI (DotCI + Cloud Jenkins) | HTTP JSON API | Triggers build jobs with parameters; polls for new build execution; retrieves build status JSON | no | `webhookSvc_ciClient` |

### GitHub Enterprise Detail

- **Protocol**: HTTPS REST via `@octokit/rest`
- **Base URL**: `GITHUB_SERVICE_URL` environment variable (e.g., `https://github.production.service` in production); API path appended as `/api/v3`
- **Auth**: Bearer token via `GITHUB_API_TOKEN` environment variable; bot user identity from `GITHUB_USER` environment variable
- **Purpose**: Primary data source and write target. Configuration loading, PR/label/branch/status management, team resolution, comment management.
- **Failure mode**: If GitHub is unreachable, config loading fails and the entire event is skipped (logged, no hooks execute). If individual GitHub write calls fail, the specific hook fails but other hooks continue.
- **Circuit breaker**: No. The `@octokit/plugin-retry` plugin handles transient failures with automatic retries. No circuit breaker pattern is implemented.

### Slack Detail

- **Protocol**: HTTPS REST via `@slack/web-api`
- **Base URL**: Slack Web API (standard Slack endpoint)
- **Auth**: Bot token via `SLACK_API_TOKEN` environment variable
- **Purpose**: Send direct messages to engineers for PR review requests, @mentions, build status results, and config validation warnings. Send channel notifications for team mentions.
- **Failure mode**: Slack-dependent hooks log errors and return failure, but do not block other hooks. Errors to specific users are also posted to the `#webhook-errors` Slack channel (`CF7MWGCNM`).
- **Circuit breaker**: No.

### Jira Cloud Detail

- **Protocol**: HTTPS REST (`rest/api/2`)
- **Base URL**: `JIRA_SERVICE_URL` environment variable (e.g., `https://groupondev.atlassian.net`); user-facing URL hardcoded to `https://groupondev.atlassian.net`
- **Auth**: Basic authentication using `JIRA_API_TOKEN` environment variable (base64 encoded)
- **Purpose**: Validates that Jira issue keys parsed from PR titles and commit messages exist; transitions issues between states on PR open/merge/close; posts PR links as Jira remote links; adds comments.
- **Failure mode**: Jira hook failures are logged and isolated; other hooks continue execution.
- **Circuit breaker**: No.

### Jenkins CI Detail

- **Protocol**: HTTP POST (form-encoded) to trigger builds; HTTP GET (JSON API) to poll build status
- **Base URL**: `CI_SERVICE_URL` (DotCI) and `CJ_SERVICE_URL` (Cloud Jenkins) environment variables; URLs with `ci.groupondev.com` or `cloud-jenkins.groupondev.com` are internally rewritten to avoid Okta authentication
- **Auth**: None documented in code (direct internal network access)
- **Purpose**: Triggers CI jobs when label or PR event matches configured conditions; polls for the matching build run (up to 30 seconds); posts build artifact links back to the PR
- **Failure mode**: CI hook failures are logged and isolated. Build trigger calls time out after 20 seconds.
- **Circuit breaker**: No.

## Internal Dependencies

> No evidence found in codebase. This service has no internal Groupon service dependencies.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| GitHub Enterprise | HTTP webhook POST | Delivers all repository event payloads to `/uber`; configured as the "uber webhook" on GitHub organizations and repositories |

## Dependency Health

- All outbound HTTP calls use a 10-second timeout for GitHub API calls (Octokit client config) and 20-second timeouts for Jenkins CI API calls (axios config).
- The `@octokit/plugin-retry` plugin automatically retries transient GitHub API errors.
- Individual hook failures are isolated using `Promise.allSettled` — a failure in one hook does not prevent other hooks from executing.
- If any dependency call fails, the error is logged via the Steno structured logger and, in some cases, posted to the Slack `#webhook-errors` channel.

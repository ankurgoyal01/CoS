---
service: "mergebot"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Mergebot has three external dependencies and no internal service-to-service dependencies. GitHub Enterprise is both the event source (inbound webhooks) and the primary data and action target (API calls for reads, merges, and branch deletes). Slack provides optional outbound notifications. The Groupon logging stack receives structured application logs via filebeat.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | REST (HTTPS) + webhook | Event source; PR/review/status/comment reads; merge and branch delete execution | yes | `githubEnterprise` |
| Slack | REST (HTTPS) | Post merge success and failure notifications to configured channels | no | `slack` |
| Groupon Logging Stack (ELK/filebeat) | filebeat / Kafka | Structured JSON log aggregation for observability and troubleshooting | no | `loggingStack` |

### GitHub Enterprise Detail

- **Protocol**: REST over HTTPS; inbound webhooks (HTTP POST) and outbound API calls
- **Base URL**: `https://github.groupondev.com/api/v3/`
- **Auth**: OAuth token via `GITHUB_TOKEN` environment variable; webhook signature verification via `WEBHOOK_SECRET`
- **Purpose**: Mergebot reads PR metadata, commit lists, CI commit statuses, issue comments, pull request reviews, and repository contents (`.ghe-bot.yml`). It writes by executing PR merges (`PUT /repos/:owner/:repo/pulls/:number/merge`) and deleting source branch refs (`DELETE /repos/:owner/:repo/git/refs/heads/:branch`).
- **Failure mode**: If GitHub Enterprise is unavailable, webhook delivery will fail or timeout. Exceptions during API calls are caught and logged; no fallback or retry logic is implemented beyond the single request cycle.
- **Circuit breaker**: No evidence found in codebase.

### Slack Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: `https://groupon.slack.com` via `slack-api` gem 1.2.4; calls `api/chat.postMessage`
- **Auth**: Bot token via `SLACK_TOKEN` environment variable
- **Purpose**: Posts notifications when a PR is successfully merged (`"MergeBot merging #N on org/repo: result"`) and when a validation failure occurs (`"MergeBot failure on URL: reason"`). Notifications are only sent if `slack_channel` is configured in the repository's `.ghe-bot.yml`.
- **Failure mode**: Slack errors are caught and logged via STENO_LOGGER; Slack failure does not block or retry the merge operation.
- **Circuit breaker**: No evidence found in codebase.

### Groupon Logging Stack (ELK/filebeat) Detail

- **Protocol**: filebeat agent reads from `/app/log/steno.log` (JSON format) and ships to Kafka at `kafka-logging-producer.*`
- **Auth**: Internal infrastructure routing; no application-level auth
- **Purpose**: Centralized log aggregation. Logs are queryable in Kibana at `logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com`. Key log fields: `data.pr` (PR number), `data.repo` (org/repo), `name` (message).
- **Failure mode**: Logging failures do not affect merge processing.
- **Circuit breaker**: Not applicable.

## Internal Dependencies

> No evidence found in codebase. Mergebot has no runtime dependencies on other Groupon internal services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| GitHub Enterprise | webhook (HTTP POST) | Delivers `issue_comment` and `pull_request_review` events to trigger Mergebot's merge validation workflow |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

No automated health check, retry, or circuit breaker patterns are implemented for external dependencies. Failures are caught via Ruby `rescue` blocks and logged. Slack failures are silently swallowed after logging. GitHub API failures during merge attempts are logged with a `WARN` level log entry.

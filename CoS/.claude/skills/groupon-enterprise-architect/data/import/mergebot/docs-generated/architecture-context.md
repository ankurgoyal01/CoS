---
service: "mergebot"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMergebotService"]
---

# Architecture Context

## System Context

Mergebot sits within the Continuum platform as a Release Engineering service. It acts as a GitHub App installed on repositories, receiving inbound webhook events from GitHub Enterprise and responding by reading PR data via the GitHub API, evaluating policy, and executing merges. It has no inbound callers other than GitHub Enterprise webhooks and has no persistent data store — all state is fetched live from the GitHub API on each webhook event. Slack and the Groupon logging stack are outbound-only dependencies.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Mergebot Service | `continuumMergebotService` | Service | Ruby on Rails 4.2 | 4.2.11.1 | Processes GitHub webhook events, validates merge policy, and performs compliant PR merges with status notifications. |

## Components by Container

### Mergebot Service (`continuumMergebotService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Webhook API Controller (`mergebot_webhookApiController`) | Accepts GitHub webhook POST requests, verifies HMAC-SHA256 signatures, dispatches to the merge decision engine | Rails Controller |
| Merge Decision Engine (`mergebot_mergeDecisionEngine`) | Applies merge policy, evaluates approvals and build state, coordinates merge execution and branch deletion | Ruby Domain Service |
| Repository Config Loader (`mergebot_repoConfigLoader`) | Fetches `.ghe-bot.yml` from the repository default branch via GitHub API and deep-merges with default configuration | Ruby Service |
| GitHub Client Adapter (`mergebot_githubClientAdapter`) | Wraps Octokit access to pull requests, reviews, statuses, comments, merge, and branch deletion APIs at `https://github.groupondev.com/api/v3/` | Octokit Client |
| Slack Notification Adapter (`mergebot_slackNotificationAdapter`) | Sends merge success and failure notification messages to the Slack channel configured in `.ghe-bot.yml` | Slack API Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMergebotService` | `githubEnterprise` | Receives webhook events and uses PR/review/status/merge APIs | HTTPS |
| `continuumMergebotService` | `slack` | Posts merge outcomes and failure notifications | HTTPS |
| `continuumMergebotService` | `loggingStack` | Emits structured request/application logs | filebeat / Kafka |
| `mergebot_webhookApiController` | `mergebot_mergeDecisionEngine` | Delegates pull request validation and merge orchestration | direct |
| `mergebot_mergeDecisionEngine` | `mergebot_githubClientAdapter` | Reads pull request, review, and status data; executes merge/delete operations | direct |
| `mergebot_mergeDecisionEngine` | `mergebot_repoConfigLoader` | Loads per-repository `.ghe-bot.yml` policy | direct |
| `mergebot_mergeDecisionEngine` | `mergebot_slackNotificationAdapter` | Publishes merge success/failure notifications | direct |

## Architecture Diagram References

- Component: `components-continuumMergebotService`
- Dynamic flow: `dynamic-dynamics-mergebot-webhook-to-merge`

---
service: "webhooks-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Mobile Webhooks Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md) | synchronous | GitHub Enterprise HTTP POST to `/uber` | Receives, verifies, and routes a GitHub event to all enabled hook implementations |
| [PR Jira Integration](pr-jira-integration.md) | synchronous | `pull_request` event (opened, reopened, closed, merged) | Transitions Jira issues parsed from PR title and commits based on PR lifecycle state |
| [PR Auto-Merge](pr-auto-merge.md) | synchronous | `status` event (all checks pass) | Merges a PR automatically when all build statuses are green and the auto-merge trigger label is present |
| [PR Auto-Create Back-Merge](pr-auto-create.md) | synchronous | `pull_request` closed (merged) into a release branch | Creates a back-merge PR from the release branch to the next newer protected branch or main |
| [GitHub to Slack Notifier](github-to-slack-notifier.md) | synchronous | `issue_comment`, `commit_comment`, `pull_request_review_comment` events | Resolves GitHub @mentions in comments to Slack user IDs and sends direct messages or channel notifications |
| [Build Status Notifier](build-status-notifier.md) | synchronous | `status` event | Notifies the committer on Slack with the build result when a CI status event arrives |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service originate from GitHub Enterprise webhook delivery and fan out to Slack, Jira, or Jenkins CI. There are no flows that cross internal Groupon service boundaries. The following architecture containers are involved across all flows:

- `continuumWebhooksService` — the service itself
- `slack` — Slack Web API (external)
- GitHub Enterprise — event source and API target (external, not modeled in federated DSL)
- Jira Cloud — issue lifecycle target (external, not modeled in federated DSL)
- Jenkins CI — build trigger target (external, not modeled in federated DSL)

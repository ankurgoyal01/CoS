---
service: "mergebot"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [webhook]
---

# Events

## Overview

Mergebot does not use an async message broker (no Kafka, RabbitMQ, or SQS). Its event model is entirely webhook-driven: GitHub Enterprise pushes synchronous HTTP POST events to Mergebot, and Mergebot responds inline. Outbound notifications to Slack are fire-and-forget HTTP calls, not message-bus events.

## Published Events

> No evidence found in codebase. Mergebot does not publish events to any message bus or topic. Outbound communication is via Slack API (synchronous HTTP POST to `https://groupon.slack.com/api/chat.postMessage`) and GitHub API (merge/branch delete REST calls).

## Consumed Events

Mergebot consumes GitHub webhook events delivered via HTTP POST to `/api/events/issue_comments`.

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| GitHub webhook (HTTP POST) | `issue_comment` | `ApiController#issue_comments` → `MergeBot::IssueComment#process!` | Validates PR eligibility; may trigger merge + branch delete + Slack notification |
| GitHub webhook (HTTP POST) | `pull_request_review` | `ApiController#issue_comments` → `MergeBot::IssueComment#process!` | Validates PR eligibility via review approval count; may trigger merge + branch delete + Slack notification |
| GitHub webhook (HTTP POST) | `ping` | `ApiController#issue_comments` (no-op) | Ignored; `200 OK` returned immediately |

### `issue_comment` Event Detail

- **Source**: GitHub Enterprise webhook, fired when a comment is created on a PR or issue
- **Handler**: `MergeBot::IssueComment#process!` via `MergeBot::Approval::ApprovalByComment` when `approval_method` is `approval_by_comment`
- **Idempotency**: Not strictly idempotent — each webhook triggers a full re-evaluation. Repeated identical webhooks result in repeated merge attempts, though GitHub will reject a second merge on an already-closed PR
- **Error handling**: Exceptions are caught and logged via STENO_LOGGER; no retry or DLQ mechanism exists
- **Processing order**: Unordered; each event processed independently

### `pull_request_review` Event Detail

- **Source**: GitHub Enterprise webhook, fired when a reviewer submits a formal GitHub review (Approve / Request Changes)
- **Handler**: `MergeBot::IssueComment#process!` via `MergeBot::Approval::ApprovalByReview` when `approval_method` is `approval_by_review`
- **Idempotency**: Same as `issue_comment` — stateless re-evaluation on each event
- **Error handling**: Exceptions caught and logged; no DLQ
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. Mergebot has no DLQ mechanism. Failed webhook processing is logged and may generate a Slack failure notification.

---
service: "webhooks-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [webhook]
---

# Events

## Overview

The Webhooks Service does not use an async messaging system (Kafka, RabbitMQ, SQS, etc.). It operates as a synchronous webhook receiver: GitHub Enterprise pushes HTTP POST requests to the service, and the service processes them inline, making outbound calls to GitHub, Slack, Jira, and Jenkins CI before responding. The service is the consumer of GitHub webhook events, not a producer of internal async events.

## Published Events

> No evidence found in codebase. This service does not publish events to any internal messaging system or event bus.

## Consumed Events

The service consumes GitHub webhook events delivered over HTTPS to the `/uber` endpoint. These are synchronous HTTP pushes from GitHub Enterprise, not messages from a queue.

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `POST /uber` | `pull_request` | Webhook Router + enabled PR hooks | Label management, branch deletion, Jira transitions, Slack notifications, CI triggers, auto-merge |
| `POST /uber` | `status` | Webhook Router + `build_status_notifier`, `pr_auto_merge` | Notifies committer of build result; triggers auto-merge when all statuses green |
| `POST /uber` | `issue_comment` | Webhook Router + `github_to_slack_notifier` | Sends Slack DM to mentioned GitHub users |
| `POST /uber` | `push` | Webhook Router + `validate_user_config` | Validates committer email linkage; pings user on Slack with fix instructions |
| `POST /uber` | `commit_comment` | Webhook Router + `github_to_slack_notifier` | Sends Slack DM to mentioned GitHub users |
| `POST /uber` | `pull_request_review_comment` | Webhook Router + `github_to_slack_notifier` | Sends Slack DM to mentioned GitHub users |

### GitHub Event Detail

- **Delivery mechanism**: HTTP POST from GitHub Enterprise to `http://webhook-vip.snc1/uber`
- **Signature verification**: HMAC-SHA1 using a shared secret (`X-Hub-Signature` header), verified by `@octokit/webhooks`
- **Delivery ID**: `X-GitHub-Delivery` header used for request tracing and logging context
- **Idempotency**: The service does not deduplicate based on delivery ID; GitHub may re-deliver events on failure; individual hooks may produce duplicate side effects on re-delivery
- **Error handling**: If signature verification fails, the request is silently dropped. If hook execution fails, the service responds with HTTP 500 and GitHub may re-deliver.
- **Processing order**: All matching hooks for a single event run concurrently via `Promise.allSettled`

## Dead Letter Queues

> No evidence found in codebase. This service does not use a message queue and therefore has no dead letter queue configuration.

---
service: "deploybot"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [pest, slack, jira, github-webhook]
---

# Events

## Overview

deploybot participates in event-driven messaging in two directions. It consumes GitHub push webhook events as its primary deployment trigger and queries the GitHub REST API for CI status. It publishes deployment lifecycle events to PEST, creates and closes Jira SOX logbook tickets as structured audit events, and sends Slack notifications at every meaningful stage of a deployment. There is no Kafka or RabbitMQ broker involved; event publication is synchronous HTTP calls to external systems.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| PEST | `deploy_start` | Deployment begins execution | deployment key, project, environment, commit SHA |
| PEST | `deploy_complete` | Deployment finishes (success or failure) | deployment key, project, environment, status, duration |
| Jira | SOX logbook ticket created | Every deployment starts | project, environment, deployer, commit SHA, deployment key |
| Jira | SOX logbook ticket closed | Deployment finalizes | deployment key, outcome (success/failure), log archive URL |
| Slack | `deploy_queued` | Deployment enters the queue | project, environment, deployer, commit SHA |
| Slack | `deploy_started` | Deployment begins execution | project, environment, deployer, deployment key |
| Slack | `deploy_completed` | Deployment completes successfully | project, environment, duration, log URL |
| Slack | `deploy_failed` | Deployment fails at any stage | project, environment, failure reason, log URL |
| Slack | `deploy_overridden` | A queued deployment is overridden by a newer one | project, environment, overridden by |

### deploy_start Detail

- **Topic**: PEST
- **Trigger**: `deploybotOrchestrator` transitions deployment state to executing
- **Payload**: deployment key, project name, target environment, commit SHA
- **Consumers**: Unknown — tracked in central PEST consumer registry
- **Guarantees**: at-most-once (synchronous HTTP POST; no retry queue)

### deploy_complete Detail

- **Topic**: PEST
- **Trigger**: `deploybotOrchestrator` transitions deployment state to finalized (success or failure)
- **Payload**: deployment key, project name, target environment, final status, duration
- **Consumers**: Unknown — tracked in central PEST consumer registry
- **Guarantees**: at-most-once (synchronous HTTP POST; no retry queue)

### Jira SOX Logbook Detail

- **Topic**: Jira (REST API)
- **Trigger**: Every deployment start and finalization
- **Payload**: project, environment, deployer identity, commit SHA, deployment key, outcome, S3 log URL
- **Consumers**: SOX auditors, compliance tooling
- **Guarantees**: at-most-once (synchronous Jira REST call)

### Slack Notifications Detail

- **Topic**: Slack (webhook or API)
- **Trigger**: Each stage transition: queued, started, completed, failed, overridden
- **Payload**: Contextual deployment metadata per stage
- **Consumers**: Engineering teams and release engineers
- **Guarantees**: at-most-once (synchronous HTTP call)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| GitHub Webhook | `push` | `deploybotApi` — `/request/webhook` endpoint | Triggers deployment validation and queueing |
| GitHub REST API | Commit status | `deploybotValidator` | Blocks or unblocks deployment based on CI build result |
| Conveyor Cloud API | Maintenance window query | `deploybotValidator` | Blocks deployment if active maintenance window detected |

### GitHub push webhook Detail

- **Topic**: GitHub Webhook (`push` event)
- **Handler**: Receives POST at `/request/webhook`, validates `X-Hub-Signature`, reads `.deploy_bot.yml` from the pushed branch, then passes to `deploybotOrchestrator` for queueing
- **Idempotency**: No explicit deduplication; duplicate pushes may trigger duplicate deployments unless blocked by in-progress state
- **Error handling**: Signature validation failure returns HTTP 401; malformed payload returns HTTP 400
- **Processing order**: Unordered (each push processed independently)

### GitHub Commit Status Detail

- **Topic**: GitHub REST API (polling)
- **Handler**: `deploybotValidator` polls GitHub commit status checks to gate deployment on CI build completion
- **Idempotency**: Polling is idempotent; same status checked repeatedly until passing or timed out
- **Error handling**: GitHub API failures cause validation to retry; prolonged failure blocks deployment
- **Processing order**: Ordered per deployment (must pass before execution proceeds)

## Dead Letter Queues

> No evidence found in codebase. deploybot does not use a message broker with DLQ support. All event publication is via synchronous HTTP; failures are logged but not requeued.

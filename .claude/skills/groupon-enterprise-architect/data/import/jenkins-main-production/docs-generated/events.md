---
service: "cloud-jenkins-main"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [wavefront-api, slack]
---

# Events

## Overview

Cloud Jenkins Main does not use a traditional message bus (Kafka, RabbitMQ, SQS). Asynchronous communication occurs in two forms: (1) Wavefront event API calls fired from Groovy init hooks to mark controller startup and shutdown lifecycle boundaries, and (2) Slack webhook messages sent by the pipeline on build failure. The AWS Lambda cleanup component is invoked by an AWS EventBridge schedule rather than a message topic.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `https://groupon.wavefront.com/api/v2/event` | `cloud_jenkins_main_start` | Jenkins controller init hook `S01AddWavefrontEvent.groovy` fires on startup | `name`, `startTime`, `tags` (service, region, env, vpc, source, atom, component) |
| `https://groupon.wavefront.com/api/v2/event/{id}/close` | Wavefront event close | Jenkins controller init hook `S04WavefrontEventClose.groovy` fires after init completes | event ID from startup response |
| Slack `#cj-dev` channel | Pipeline failure notification | `post { failure { ... } }` block in `Jenkinsfile` when master-branch build fails | `JOB_NAME`, `ref`, `BUILD_URL` |

### `cloud_jenkins_main_start` Detail

- **Topic**: `https://groupon.wavefront.com/api/v2/event`
- **Trigger**: Controller startup — only when `ENV` is `staging` or `production` and `STACK` is `main`
- **Payload**: JSON object with fields `name: cloud_jenkins_main_start`, `startTime` (epoch ms), `tags` array including service, region, env, vpc, source, atom, component
- **Consumers**: Wavefront metrics/dashboard platform
- **Guarantees**: at-most-once (single HTTP POST with no retry logic)

### Pipeline Failure Slack Notification Detail

- **Topic**: Slack channel `#cj-dev` via `slackSend`
- **Trigger**: Any `Jenkinsfile` pipeline failure on the `master` branch (i.e. `shouldBeDeployed == true`)
- **Payload**: `"${env.JOB_NAME} has failed at ref ${ref}. ${env.BUILD_URL}"` with color `danger`
- **Consumers**: CICD on-call team
- **Guarantees**: at-most-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| GitHub Enterprise push webhook | `push` | `/ghe-seed/` endpoint (Conveyor Build Plugin) | Seeds or triggers pipeline jobs based on repository Jenkinsfile |
| AWS EventBridge schedule | Cron invocation | `agentCleanupScheduler` → `danglingAgentTerminator` | Terminates stale EC2 Jenkins agents |

### GitHub Enterprise Push Webhook Detail

- **Topic**: `/ghe-seed/` HTTP endpoint
- **Handler**: Conveyor Build Plugin receives the event, validates `X-Hub-Signature`, and seeds or triggers the relevant pipeline job
- **Idempotency**: Not explicitly enforced; duplicate push events may trigger duplicate builds
- **Error handling**: Returns HTTP 400 on payload parse failure; CSRF exclusion verified in smoke tests
- **Processing order**: Unordered (each push is processed independently)

### AWS EventBridge Cron Detail

- **Topic**: AWS EventBridge schedule (cron expression not visible in this repo; defined in Terraform modules)
- **Handler**: `agentCleanupScheduler` component triggers `danglingAgentTerminator` Lambda handler
- **Idempotency**: Cleanup is idempotent — terminating an already-terminated instance is a no-op
- **Error handling**: Errors logged to the central logging stack; metrics emitted to Wavefront
- **Processing order**: Ordered (single scheduled invocation per interval)

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present for any event channel.

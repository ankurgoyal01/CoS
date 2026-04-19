---
service: "machine-learning-toolkit"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["sns", "sqs"]
---

# Events

## Overview

The Machine Learning Toolkit uses AWS SNS and SQS for asynchronous notifications and async inference result fanout. Three SNS topics carry platform-level notifications (success, failure, general). Per-model SQS queues receive async SageMaker inference results from the success and failure topics. Each SQS queue has a paired dead-letter queue. The MWAA environment publishes to SNS topics on workflow completion or failure. Async inference results flow from SageMaker through the SNS topics into SQS queues where downstream consumers can retrieve them.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `{service_name_prefix}-sage-alerts-success` (SNS) | `workflow-success` | MWAA DAG completes successfully or SageMaker async inference succeeds | SNS message body (project-defined) |
| `{service_name_prefix}-sage-alerts-error` (SNS) | `workflow-failure` | MWAA DAG fails or SageMaker async inference fails | SNS message body (project-defined) |
| `{service_name_prefix}-sage-alerts-general` (SNS) | `workflow-general` | General MWAA workflow event; email fanout to Slack alerts email | `owner_email` filter key |

### workflow-success Detail

- **Topic**: `{service_name_prefix}-sage-alerts-success`
- **Trigger**: MWAA Alert Publisher DAG task completes without error, or SageMaker async invocation returns a success notification
- **Payload**: Project-defined SNS message; delivery policy allows 3 retries with linear backoff, max 1 message/second throttle
- **Consumers**: SQS async endpoint queues (`{service_name_prefix}-sage-async-{project}_{version}_{api_name}-{env}`)
- **Guarantees**: at-least-once

### workflow-failure Detail

- **Topic**: `{service_name_prefix}-sage-alerts-error`
- **Trigger**: MWAA Alert Publisher DAG task fails, or SageMaker async invocation returns an error notification
- **Payload**: Project-defined SNS message; same delivery policy as success topic
- **Consumers**: SQS async endpoint queues (same per-model queues as success), Slack alerts email via SNS email subscription
- **Guarantees**: at-least-once

### workflow-general Detail

- **Topic**: `{service_name_prefix}-sage-alerts-general`
- **Trigger**: General MWAA workflow events published by the Alert Publisher component
- **Payload**: Filtered by `owner_email` attribute; email delivered to project owner and to Slack alerts email (`dnd-dssi-service-aler-...@groupon.slack.com`)
- **Consumers**: Project owner emails, Slack channel via email endpoint
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `{service_name_prefix}-sage-async-{project}_{version}_{api_name}-{env}` (SQS) | Async inference result | Downstream ML project consumer (reads from SQS) | Inference result retrieved and processed by the consuming application |

### Async Inference Result Detail

- **Topic**: Per-model SQS queue, subscribed to both the success and failure SNS topics
- **Handler**: Downstream ML project or data pipeline that polls the SQS queue
- **Idempotency**: Not enforced at platform level; consuming applications are responsible
- **Error handling**: Dead-letter queue (`{service_name_prefix}-sage-async-dead-letter-{project}_{version}_{api_name}-{env}`) receives messages after 4 failed receive attempts
- **Processing order**: Unordered (standard SQS queue)

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| `{service_name_prefix}-sage-async-dead-letter-{project}_{version}_{api_name}-{env}` | Per-model SQS async queue | 86400 seconds (24 hours) | No automatic platform alert configured; monitoring via CloudWatch |

> Queue naming uses the pattern `{service_name_prefix}-sage-async-{project}_{version}_{api_name}-{env}` where values are resolved at Terraform apply time from `api_config` variable inputs. Each async inference endpoint gets its own SQS and DLQ pair.

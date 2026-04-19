---
service: "n8n"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [redis, bull]
---

# Events

## Overview

n8n uses a Redis-backed Bull queue as its internal job messaging system when running in `EXECUTIONS_MODE=queue`. This is not a general-purpose pub/sub event bus — it is an internal queue used to distribute workflow execution jobs from the n8n Service (workflow engine) to queue-worker pods. Each deployed instance (default, finance, merchant, llm-traffic, business) has its own dedicated Redis Memorystore instance as the queue backend.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Bull Redis queue (instance-scoped) | Workflow execution job | Workflow trigger (webhook, schedule, manual) | Workflow ID, execution ID, input data |

### Workflow Execution Job Detail

- **Topic**: Bull Redis queue on the instance-scoped Memorystore (e.g., `n8n-default-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`)
- **Trigger**: Any workflow trigger event: inbound webhook, cron schedule, manual start via editor, or API call
- **Payload**: Workflow execution context including workflow ID, execution ID, and trigger input data
- **Consumers**: Queue-worker pods of the same n8n instance (2–20 replicas per instance, 10 concurrent jobs per pod)
- **Guarantees**: At-least-once (Bull queue semantics with lock duration `QUEUE_WORKER_LOCK_DURATION=60000`ms)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Bull Redis queue (instance-scoped) | Workflow execution job | n8n queue-worker (`n8n worker --concurrency=10`) | Executes workflow, writes execution record to PostgreSQL, invokes code nodes via runner broker |

### Workflow Execution Job (Consumer) Detail

- **Topic**: Bull Redis queue on the instance-scoped Memorystore
- **Handler**: `n8n worker --concurrency=10` process running in each queue-worker pod. Fetches jobs, executes the workflow graph node-by-node, and writes the final execution record to PostgreSQL.
- **Idempotency**: Not guaranteed — each job is processed once, retried if the lock expires. Workflow authors are responsible for idempotent workflow design.
- **Error handling**: Failed jobs are retried per Bull default retry policy. `QUEUE_HEALTH_CHECK_ACTIVE=true` enables a queue health probe at the readiness endpoint.
- **Processing order**: Unordered (Bull FIFO within priority, multiple concurrent workers)

## Dead Letter Queues

> No evidence found in codebase. No explicit DLQ configuration was found in the deployment manifests. Bull's built-in failed job handling applies.

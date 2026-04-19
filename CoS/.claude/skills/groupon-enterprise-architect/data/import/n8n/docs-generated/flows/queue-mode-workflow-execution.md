---
service: "n8n"
title: "Queue-Mode Workflow Execution"
generated: "2026-03-03"
type: flow
flow_name: "queue-mode-workflow-execution"
flow_type: asynchronous
trigger: "Any workflow trigger (schedule, webhook, manual start, API call)"
participants:
  - "continuumN8nService"
  - "n8nWorkflowEngine"
  - "continuumN8nPostgres"
  - "n8nWorkflowDataStore"
  - "continuumN8nTaskRunners"
  - "n8nRunnerLauncher"
architecture_ref: "dynamic-workflow-execution-flow"
---

# Queue-Mode Workflow Execution

## Summary

All n8n production instances run in `EXECUTIONS_MODE=queue`. When a workflow is triggered, the n8n Service (workflow engine) enqueues the execution job to a Redis Memorystore Bull queue. A queue-worker pod picks up the job, executes the workflow nodes (optionally invoking external task runners for code nodes), and writes the final execution record to PostgreSQL. This model decouples triggering from execution, enabling horizontal scaling of execution capacity independently from the main n8n Service.

## Trigger

- **Type**: Any workflow activation event — inbound webhook, cron schedule, manual start via editor, or REST API call
- **Source**: `continuumN8nService` (workflow engine) after validating the trigger
- **Frequency**: On-demand or scheduled

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| n8n Service (Workflow Engine) | Receives trigger, enqueues execution job to Redis | `continuumN8nService` / `n8nWorkflowEngine` |
| Redis Memorystore (Bull queue) | Holds the pending execution job | Instance-scoped Memorystore (`QUEUE_BULL_REDIS_HOST`) |
| n8n Queue-Worker Pod | Consumes job from queue, executes workflow nodes, writes result | `continuumN8nService` (worker mode) |
| n8n PostgreSQL | Stores initial execution record; receives final execution result | `continuumN8nPostgres` / `n8nWorkflowDataStore` |
| n8n Task Runners | Executes JavaScript or Python code nodes on behalf of the queue-worker | `continuumN8nTaskRunners` / `n8nRunnerLauncher` |

## Steps

1. **Workflow Trigger Received**: The n8n Service receives a trigger (webhook POST, schedule tick, manual activation, or API call).
   - From: Trigger source (external caller, cron, editor user)
   - To: `continuumN8nService`
   - Protocol: HTTPS / internal

2. **Load Workflow and Write Initial Execution Record**: The Workflow Engine loads the workflow definition from PostgreSQL and creates an initial execution record.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

3. **Enqueue Execution Job**: The Workflow Engine pushes the execution job to the instance-scoped Bull Redis queue with a lock duration of 60,000 ms.
   - From: `n8nWorkflowEngine`
   - To: Redis Memorystore (`QUEUE_BULL_REDIS_HOST:6379`)
   - Protocol: Redis

4. **Queue-Worker Picks Up Job**: One of the available queue-worker pods (concurrency: 10 jobs per pod) acquires the job lock from the Bull queue.
   - From: Redis Memorystore
   - To: n8n queue-worker pod
   - Protocol: Redis

5. **Execute Workflow Nodes**: The queue-worker executes each node in the workflow graph sequentially or in parallel as configured. For Code nodes, the runner broker is used (see [Code Node Task Execution](code-node-task-execution.md)).
   - From: n8n queue-worker
   - To: Workflow nodes (internal); `n8nRunnerBroker` (for code nodes)
   - Protocol: direct / HTTP (port 5679)

6. **Persist Execution Result**: On completion or error, the queue-worker updates the execution record in PostgreSQL with the final status, output, and timestamps.
   - From: n8nRunnerLauncher / queue-worker
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

7. **Job Acknowledged**: The queue-worker acknowledges job completion to the Bull queue; Redis removes the job from the active set.
   - From: Queue-worker
   - To: Redis Memorystore
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Worker crashes during execution | Bull lock expires (after 60,000 ms); job requeued for another worker | At-least-once reprocessing; possible duplicate execution if not idempotent |
| Redis unavailable | Queue-worker cannot fetch jobs; queue backlog grows | Executions stall; KEDA scaling metric no longer functions; readiness probe fails |
| PostgreSQL unavailable | Execution record cannot be written; workflow cannot load | Execution fails; error logged |
| Workflow node error | Workflow enters error path if configured; execution record set to `error` | Error recorded; no retry at queue level unless workflow implements retry logic |
| Job concurrency exceeded | Bull queue holds jobs until worker capacity is available | Jobs wait in queue; KEDA scales up workers when queue depth exceeds threshold (10) |

## Sequence Diagram

```
Trigger source -> continuumN8nService: Activate workflow
n8nWorkflowEngine -> n8nWorkflowDataStore: Load workflow definition + create execution record
n8nWorkflowEngine -> RedisMemorystore: LPUSH execution job (Bull queue)
QueueWorkerPod -> RedisMemorystore: BRPOPLPUSH (acquire job with lock)
QueueWorkerPod -> QueueWorkerPod: Execute workflow nodes
QueueWorkerPod -> n8nRunnerBroker: Dispatch code task (if Code node)
n8nRunnerLauncher -> n8nRunnerBroker: Fetch task, execute, return result
QueueWorkerPod -> n8nWorkflowDataStore: UPDATE execution record (status=success|error)
QueueWorkerPod -> RedisMemorystore: Acknowledge job completion
```

## Related

- Architecture dynamic view: `dynamic-workflow-execution-flow`
- Related flows: [Webhook-Triggered Workflow Execution](webhook-triggered-workflow-execution.md), [Code Node Task Execution](code-node-task-execution.md), [Scheduled Workflow Execution](scheduled-workflow-execution.md)

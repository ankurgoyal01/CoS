---
service: "n8n"
title: "Scheduled Workflow Execution"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-workflow-execution"
flow_type: scheduled
trigger: "Cron schedule configured in a workflow's Schedule Trigger node"
participants:
  - "continuumN8nService"
  - "n8nWorkflowEngine"
  - "continuumN8nPostgres"
  - "n8nWorkflowDataStore"
architecture_ref: "dynamic-workflow-execution-flow"
---

# Scheduled Workflow Execution

## Summary

Workflows configured with a Schedule Trigger node (cron expression) are activated by the n8n internal scheduler within the main n8n Service. On each scheduled tick, the Workflow Engine activates the corresponding workflow and enqueues it to the Bull Redis queue (as queue execution mode is active on all production instances). Queue-worker pods consume and execute the job. This is the standard mechanism for periodic automation tasks such as data synchronization, reporting, and recurring business operations.

## Trigger

- **Type**: schedule (cron)
- **Source**: n8n internal scheduler within `continuumN8nService`; cron expressions are defined per-workflow in the workflow definition stored in `continuumN8nPostgres`
- **Frequency**: Per workflow-configured cron expression (varies by workflow)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| n8n Internal Scheduler | Evaluates cron schedules and fires trigger events at the configured time | `n8nWorkflowEngine` (within `continuumN8nService`) |
| n8n Service (Workflow Engine) | Receives the scheduler tick, loads workflow, enqueues execution | `continuumN8nService` |
| Redis Memorystore (Bull queue) | Holds the scheduled execution job | Instance-scoped Memorystore (`QUEUE_BULL_REDIS_HOST`) |
| n8n Queue-Worker Pod | Consumes and executes the workflow job | `continuumN8nService` (worker mode) |
| n8n PostgreSQL | Stores workflow definitions with schedule settings; receives execution records | `continuumN8nPostgres` / `n8nWorkflowDataStore` |

## Steps

1. **Cron Tick**: The n8n internal scheduler evaluates all active workflow schedules. When a cron expression matches the current time, the scheduler fires a trigger event for the corresponding workflow.
   - From: n8n internal scheduler
   - To: `n8nWorkflowEngine`
   - Protocol: direct (in-process)

2. **Load Workflow Definition**: The Workflow Engine retrieves the workflow definition from PostgreSQL to verify the workflow is active and get the current node configuration.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

3. **Create Execution Record and Enqueue**: The Workflow Engine creates an initial execution record in PostgreSQL (status: `waiting`) and enqueues the execution job to the Redis Bull queue.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore` (PostgreSQL) and Redis Memorystore
   - Protocol: SQL + Redis

4. **Queue-Worker Picks Up and Executes**: A queue-worker pod acquires the job from Redis and executes the workflow nodes, including any code nodes dispatched to external runners.
   - From: Queue-worker pod
   - To: Redis Memorystore (job acquire), workflow nodes (execution)
   - Protocol: Redis + direct / HTTP (port 5679 for code nodes)

5. **Persist Execution Result**: On completion, the queue-worker updates the execution record in PostgreSQL with the final status, output data, and stop time.
   - From: Queue-worker pod
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workflow is inactive | Scheduler skips the workflow | No execution enqueued |
| PostgreSQL unavailable at schedule time | Workflow definition cannot be loaded; enqueue fails | Execution missed for this tick; next scheduled tick retried |
| Queue backlog prevents timely execution | Job waits in Redis queue; KEDA scales up workers | Execution delayed; execution record shows delayed start |
| Workflow node failure | Execution record set to `error`; error path executes if configured | Failure recorded; next scheduled tick proceeds normally |
| Duplicate cron tick (unlikely in single-replica main worker) | n8n deduplicates based on execution locking | Only one execution starts per tick |

## Sequence Diagram

```
n8nScheduler -> n8nWorkflowEngine: Schedule tick (cron match)
n8nWorkflowEngine -> n8nWorkflowDataStore: SELECT workflow (active, with schedule)
n8nWorkflowDataStore --> n8nWorkflowEngine: Workflow definition
n8nWorkflowEngine -> n8nWorkflowDataStore: INSERT execution record (status=waiting)
n8nWorkflowEngine -> RedisMemorystore: LPUSH execution job (Bull queue)
QueueWorkerPod -> RedisMemorystore: BRPOPLPUSH (acquire job)
QueueWorkerPod -> QueueWorkerPod: Execute workflow nodes
QueueWorkerPod -> n8nWorkflowDataStore: UPDATE execution record (status=success|error)
QueueWorkerPod -> RedisMemorystore: Acknowledge job
```

## Related

- Architecture dynamic view: `dynamic-workflow-execution-flow`
- Related flows: [Queue-Mode Workflow Execution](queue-mode-workflow-execution.md), [Webhook-Triggered Workflow Execution](webhook-triggered-workflow-execution.md)

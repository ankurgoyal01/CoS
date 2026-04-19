---
service: "backbeat"
title: "Workflow Execution and Callback Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "workflow-execution"
flow_type: asynchronous
trigger: "API call to create or signal a workflow event"
participants:
  - "continuumBackbeatApiRuntime"
  - "continuumBackbeatPostgres"
  - "continuumBackbeatRedis"
  - "continuumBackbeatWorkerRuntime"
  - "metricsStack"
  - "accountingServiceEndpoint"
architecture_ref: "dynamic-backbeat-workflow-execution"
---

# Workflow Execution and Callback Flow

## Summary

This flow describes the end-to-end lifecycle of a workflow event in Backbeat, from initial API submission through asynchronous worker execution to downstream callback delivery. The API Runtime persists workflow state and enqueues a job reference; the Worker Runtime dequeues and executes the event, updates state, posts a callback to the client service, and emits execution metrics. The flow is asynchronous — the API caller receives an acknowledgement immediately and the execution completes out-of-band.

## Trigger

- **Type**: api-call
- **Source**: A Continuum service (e.g. Accounting Service) submits a workflow creation or signal request to `continuumBackbeatApiRuntime`
- **Frequency**: On-demand, per workflow event submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Backbeat API Runtime | Receives request; creates workflow/node state; enqueues async job | `continuumBackbeatApiRuntime` |
| Backbeat Postgres | Durably stores workflow and node state | `continuumBackbeatPostgres` |
| Backbeat Redis | Holds Sidekiq job queue entries | `continuumBackbeatRedis` |
| Backbeat Worker Runtime | Dequeues and executes workflow events; drives state transitions | `continuumBackbeatWorkerRuntime` |
| Metrics Stack | Receives execution metrics and error telemetry | `metricsStack` |
| Accounting Service (callback) | Receives activity/decision callback notification from Backbeat | `accountingServiceEndpoint` (stub-only) |

## Steps

1. **Receives workflow submission**: A client service POSTs a workflow creation or signal request to `bbWebApi`.
   - From: Client service (e.g. Accounting Service)
   - To: `continuumBackbeatApiRuntime`
   - Protocol: REST / HTTPS

2. **Creates workflow and node state**: `bbWorkflowEngine` invokes `bbPersistenceModels` to write the new workflow graph and initial node state to the database.
   - From: `continuumBackbeatApiRuntime`
   - To: `continuumBackbeatPostgres`
   - Protocol: ActiveRecord / SQL

3. **Enqueues asynchronous job metadata**: `bbWebApi` enqueues a Sidekiq job reference into Redis so the Worker Runtime can pick up execution.
   - From: `continuumBackbeatApiRuntime`
   - To: `continuumBackbeatRedis`
   - Protocol: Redis

4. **Dequeues scheduled workflow event**: `bbAsyncWorker` polls Redis, dequeues the job, and deserializes the node reference.
   - From: `continuumBackbeatWorkerRuntime`
   - To: `continuumBackbeatRedis`
   - Protocol: Redis (Sidekiq)

5. **Loads and updates workflow progression**: `bbWorkflowEvents` reads the full workflow/node state from Postgres, applies the event logic, and writes back the updated node and workflow status.
   - From: `continuumBackbeatWorkerRuntime`
   - To: `continuumBackbeatPostgres`
   - Protocol: ActiveRecord / SQL

6. **Posts activity or decision callback**: `bbClientAdapter` POSTs the activity result, decision outcome, or error notification to the downstream client's registered callback endpoint.
   - From: `continuumBackbeatWorkerRuntime`
   - To: `accountingServiceEndpoint`
   - Protocol: REST / HTTPS

7. **Emits workflow execution metrics**: `bbMetricsReporter` publishes execution counts, latency, and error telemetry to the shared Metrics Stack.
   - From: `continuumBackbeatWorkerRuntime`
   - To: `metricsStack`
   - Protocol: InfluxDB/Sonoma

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Callback delivery failure (network error) | Sidekiq automatic retry with exponential backoff | Node enters retry state; callback reattempted up to retry limit |
| Callback delivery exhausted | Sidekiq retry limit exceeded | Node enters error state; `bbClientAdapter` sends error notification |
| Postgres write failure | Exception raised; Sidekiq retries the job | Workflow/node state unchanged until successful write |
| Redis unavailable | Sidekiq cannot dequeue; API cannot enqueue | Workflow submission blocked; queue backlog builds until Redis recovers |

## Sequence Diagram

```
Client Service    -> continuumBackbeatApiRuntime  : POST /v2/workflows (create workflow)
continuumBackbeatApiRuntime -> continuumBackbeatPostgres  : INSERT workflow and node records
continuumBackbeatApiRuntime -> continuumBackbeatRedis     : ENQUEUE Sidekiq job metadata
continuumBackbeatApiRuntime --> Client Service            : 202 Accepted

continuumBackbeatWorkerRuntime -> continuumBackbeatRedis  : DEQUEUE scheduled workflow event
continuumBackbeatWorkerRuntime -> continuumBackbeatPostgres : LOAD workflow/node state
continuumBackbeatWorkerRuntime -> continuumBackbeatPostgres : UPDATE node and workflow status
continuumBackbeatWorkerRuntime -> accountingServiceEndpoint : POST activity/decision callback
continuumBackbeatWorkerRuntime -> metricsStack             : PUBLISH execution metrics
```

## Related

- Architecture dynamic view: `dynamic-backbeat-workflow-execution`
- Related flows: No additional flows documented for this service
- See [Architecture Context](../architecture-context.md) for container and component details

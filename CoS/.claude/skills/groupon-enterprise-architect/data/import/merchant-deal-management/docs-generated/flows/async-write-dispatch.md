---
service: "merchant-deal-management"
title: "Async Write Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "async-write-dispatch"
flow_type: asynchronous
trigger: "Write Orchestrator determines that a write step requires asynchronous processing"
participants:
  - "continuumDealManagementApi"
  - "dmapiWriteOrchestrator"
  - "dmapiAsyncDispatch"
  - "continuumDealManagementApiRedis"
  - "continuumDealManagementApiWorker"
architecture_ref: "components-dmapi-dmapiHttpApi"
---

# Async Write Dispatch

## Summary

The Async Write Dispatch flow describes how the Deal Management API delegates long-running write work to the background worker pool. After completing synchronous orchestration steps, the Write Orchestrator hands off to the Async Dispatch component, which calculates Resque queue depth, indexes the job, and enqueues a Resque job in Redis. The Deal Management API Worker later picks up and processes the job independently of the HTTP request lifecycle.

## Trigger

- **Type**: api-call (internal)
- **Source**: `dmapiWriteOrchestrator` within `continuumDealManagementApi` during a deal write flow
- **Frequency**: On-demand, per write request requiring async processing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Write Orchestration | Determines async work is required and initiates dispatch | `dmapiWriteOrchestrator` |
| Async Dispatch | Indexes the job and submits to Resque queue | `dmapiAsyncDispatch` |
| Deal Management API Redis | Stores the Resque job and queue state | `continuumDealManagementApiRedis` |
| Deal Management API Worker | Consumer that will dequeue and execute the job | `continuumDealManagementApiWorker` |

## Steps

1. **Trigger async dispatch**: Write Orchestrator determines that a write step (e.g., deal catalog update, Salesforce sync) should be processed asynchronously.
   - From: `dmapiWriteOrchestrator`
   - To: `dmapiAsyncDispatch`
   - Protocol: direct (in-process)

2. **Check queue depth**: Async Dispatch checks current Resque queue depth in Redis to assess backpressure.
   - From: `dmapiAsyncDispatch`
   - To: `continuumDealManagementApiRedis`
   - Protocol: Redis

3. **Index job**: Async Dispatch creates a job record and assigns it to the appropriate Resque queue.
   - From: `dmapiAsyncDispatch`
   - To: `continuumDealManagementApiRedis`
   - Protocol: Resque/Redis

4. **Enqueue job**: Resque job is stored in Redis; worker pool will pick it up for execution.
   - From: `dmapiAsyncDispatch`
   - To: `continuumDealManagementApiRedis`
   - Protocol: Resque/Redis

5. **Worker dequeues job**: `continuumDealManagementApiWorker` retrieves and begins execution of the job (see [Worker Write Execution](worker-write-execution.md)).
   - From: `continuumDealManagementApiRedis`
   - To: `dmapiWorkerExecution`
   - Protocol: Resque/Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable during enqueue | Resque enqueue raises exception | Write request may fall back to synchronous mode or return error |
| Queue depth exceeds threshold | Async Dispatch may apply backpressure logic | Job may be delayed or request throttled |

## Sequence Diagram

```
dmapiWriteOrchestrator -> dmapiAsyncDispatch: Enqueue async job
dmapiAsyncDispatch -> continuumDealManagementApiRedis: Check queue depth (Redis)
continuumDealManagementApiRedis --> dmapiAsyncDispatch: Queue depth response
dmapiAsyncDispatch -> continuumDealManagementApiRedis: Resque.enqueue(job_class, args)
continuumDealManagementApiRedis --> dmapiAsyncDispatch: Job enqueued
dmapiWorkerExecution -> continuumDealManagementApiRedis: Dequeue job (Resque poll)
```

## Related

- Architecture dynamic view: `components-dmapi-dmapiHttpApi`
- Related flows: [Synchronous Deal Write](deal-write-synchronous.md), [Worker Write Execution](worker-write-execution.md)

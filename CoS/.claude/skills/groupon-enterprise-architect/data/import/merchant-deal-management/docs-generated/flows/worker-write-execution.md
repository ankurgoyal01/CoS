---
service: "merchant-deal-management"
title: "Worker Write Execution"
generated: "2026-03-03"
type: flow
flow_name: "worker-write-execution"
flow_type: asynchronous
trigger: "Resque worker dequeues a write-request job from Redis"
participants:
  - "continuumDealManagementApiWorker"
  - "dmapiWorkerExecution"
  - "dmapiHistoryAndPersistence"
  - "dmapiWorkerRemoteClientGateway"
  - "continuumDealManagementApiMySql"
  - "continuumDealManagementApiRedis"
  - "continuumDealCatalogService"
  - "salesForce"
architecture_ref: "components-dmapi-worker"
---

# Worker Write Execution

## Summary

The Worker Write Execution flow covers the lifecycle of a Resque job from dequeue through completion. The `dmapiWorkerExecution` component picks up a queued write-request job, executes the required downstream service calls (deal catalog update, Salesforce sync) via `dmapiWorkerRemoteClientGateway`, and then persists the write request result and history event records to MySQL via `dmapiHistoryAndPersistence`. Metrics and logs are emitted to the platform observability stack throughout the execution.

## Trigger

- **Type**: event
- **Source**: Resque job enqueued in `continuumDealManagementApiRedis` by `dmapiAsyncDispatch`
- **Frequency**: On-demand, per enqueued write-request job

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Worker Execution | Dequeues and drives job execution | `dmapiWorkerExecution` |
| History and Persistence | Persists write request result and history events | `dmapiHistoryAndPersistence` |
| Worker Remote Client Gateway | Calls downstream services during async flow | `dmapiWorkerRemoteClientGateway` |
| Deal Management API Redis | Source of queued jobs | `continuumDealManagementApiRedis` |
| Deal Management API MySQL | Persistence target for write requests and history | `continuumDealManagementApiMySql` |
| Deal Catalog Service | Receives async deal catalog update | `continuumDealCatalogService` |
| Salesforce | Receives async deal/merchant data sync | `salesForce` |

## Steps

1. **Dequeue job**: Worker execution dequeues the write-request job from the Resque queue in Redis.
   - From: `continuumDealManagementApiRedis`
   - To: `dmapiWorkerExecution`
   - Protocol: Resque/Redis

2. **Call downstream services**: Worker Remote Client Gateway invokes required downstream services for the async write flow.
   - From: `dmapiWorkerExecution`
   - To: `dmapiWorkerRemoteClientGateway`
   - Protocol: direct (in-process)

3. **Update Deal Catalog**: Sends asynchronous deal catalog update to the Deal Catalog Service.
   - From: `dmapiWorkerRemoteClientGateway`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

4. **Sync Salesforce**: Sends asynchronous deal/merchant data update to Salesforce.
   - From: `dmapiWorkerRemoteClientGateway`
   - To: `salesForce`
   - Protocol: HTTPS/REST

5. **Persist write request and history**: History and Persistence component records the completed write request and appends a history event to MySQL.
   - From: `dmapiWorkerExecution`
   - To: `dmapiHistoryAndPersistence` → `continuumDealManagementApiMySql`
   - Protocol: ActiveRecord/MySQL

6. **Emit metrics and logs**: Worker publishes execution metrics and structured logs to the platform observability stack.
   - From: `continuumDealManagementApiWorker`
   - To: `metricsStack`, `loggingStack`
   - Protocol: Metrics, Structured Logs

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Downstream service call failure | Resque retry mechanism re-enqueues job on exception | Job retried up to Resque retry limit; lands in Resque failed queue if limit exceeded |
| MySQL write failure | ActiveRecord exception | Job re-enqueued by Resque retry; write request not persisted until retry succeeds |
| Salesforce call failure | Resque retry on HTTPS error | Async Salesforce sync retried; failed queue if retries exhausted |

## Sequence Diagram

```
continuumDealManagementApiRedis -> dmapiWorkerExecution: Dequeue job (Resque poll)
dmapiWorkerExecution -> dmapiWorkerRemoteClientGateway: Execute downstream calls
dmapiWorkerRemoteClientGateway -> continuumDealCatalogService: Update deal catalog (HTTP/JSON)
continuumDealCatalogService --> dmapiWorkerRemoteClientGateway: 200 OK
dmapiWorkerRemoteClientGateway -> salesForce: Sync deal/merchant data (HTTPS/REST)
salesForce --> dmapiWorkerRemoteClientGateway: 200 OK
dmapiWorkerExecution -> dmapiHistoryAndPersistence: Persist write request result and history event
dmapiHistoryAndPersistence -> continuumDealManagementApiMySql: INSERT/UPDATE (ActiveRecord)
continuumDealManagementApiMySql --> dmapiHistoryAndPersistence: Success
```

## Related

- Architecture dynamic view: `components-dmapi-worker`
- Related flows: [Async Write Dispatch](async-write-dispatch.md), [Deal Catalog Synchronization](deal-catalog-sync.md), [Salesforce Deal Sync](salesforce-deal-sync.md)

---
service: "merchant-deal-management"
title: "Salesforce Deal Sync"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-deal-sync"
flow_type: asynchronous
trigger: "Deal write or merchant update requiring CRM record synchronization with Salesforce"
participants:
  - "continuumDealManagementApi"
  - "dmapiRemoteClientGateway"
  - "salesForce"
  - "continuumDealManagementApiWorker"
  - "dmapiWorkerExecution"
  - "dmapiWorkerRemoteClientGateway"
  - "continuumDealManagementApiRedis"
architecture_ref: "components-dmapi-worker"
---

# Salesforce Deal Sync

## Summary

The Salesforce Deal Sync flow describes how deal and merchant data is kept in sync between the Continuum platform and Salesforce CRM. The `continuumDealManagementApi` reads from and writes to Salesforce directly via HTTPS/REST during synchronous deal write orchestration. The `continuumDealManagementApiWorker` processes Salesforce updates asynchronously as background Resque jobs for write flows that do not require a blocking Salesforce response. Both paths use Faraday clients via their respective Remote Client Gateway components.

## Trigger

- **Type**: api-call or event (Resque job)
- **Source**: Inbound deal creation or update that requires Salesforce CRM record synchronization
- **Frequency**: On-demand, per deal write or merchant data change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Handles synchronous Salesforce reads/writes during write orchestration | `continuumDealManagementApi` |
| Remote Client Gateway (API) | Executes synchronous HTTPS/REST calls to Salesforce | `dmapiRemoteClientGateway` |
| Salesforce | External CRM system receiving deal/merchant data | `salesForce` |
| Deal Management API Redis | Stores Resque jobs for async Salesforce sync | `continuumDealManagementApiRedis` |
| Worker Execution | Dequeues and drives async Salesforce sync jobs | `dmapiWorkerExecution` |
| Worker Remote Client Gateway | Executes asynchronous HTTPS/REST calls to Salesforce | `dmapiWorkerRemoteClientGateway` |

## Steps

### Synchronous path (API-side)

1. **Initiate Salesforce call**: Write Orchestrator determines a Salesforce read or write is required and calls the Remote Client Gateway.
   - From: `dmapiWriteOrchestrator`
   - To: `dmapiRemoteClientGateway`
   - Protocol: direct (in-process)

2. **Read/write Salesforce data**: Remote Client Gateway calls Salesforce via HTTPS/REST to read deal/merchant data or update Salesforce records.
   - From: `dmapiRemoteClientGateway`
   - To: `salesForce`
   - Protocol: HTTPS/REST

3. **Return Salesforce response**: Salesforce returns the result; Write Orchestrator incorporates the data into the deal write flow.
   - From: `salesForce`
   - To: `dmapiRemoteClientGateway` → `dmapiWriteOrchestrator`
   - Protocol: HTTPS/REST

### Asynchronous path (Worker-side)

4. **Enqueue Salesforce sync job**: API enqueues a Resque job for Salesforce sync work that does not need to block the HTTP response.
   - From: `dmapiAsyncDispatch`
   - To: `continuumDealManagementApiRedis`
   - Protocol: Resque/Redis

5. **Dequeue and execute**: Worker Execution dequeues the Salesforce sync job from Redis.
   - From: `continuumDealManagementApiRedis`
   - To: `dmapiWorkerExecution`
   - Protocol: Resque/Redis

6. **Call Salesforce asynchronously**: Worker Remote Client Gateway sends HTTPS/REST request to Salesforce to synchronize deal/merchant data.
   - From: `dmapiWorkerRemoteClientGateway`
   - To: `salesForce`
   - Protocol: HTTPS/REST

7. **Persist result**: History and Persistence records the Salesforce sync outcome in MySQL.
   - From: `dmapiWorkerExecution`
   - To: `dmapiHistoryAndPersistence` → `continuumDealManagementApiMySql`
   - Protocol: ActiveRecord/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce unavailable (sync path) | Faraday HTTPS error surfaces to Write Orchestrator | API may return HTTP 5xx or queue for async retry |
| Salesforce unavailable (async path) | Resque retry re-enqueues the Salesforce sync job | Worker retries until success or retry limit exhausted; lands in Resque failed queue |
| Salesforce authentication failure | HTTPS 401/403 from Salesforce | Error logged to `loggingStack`; alert expected via `metricsStack` |
| Salesforce data conflict | Salesforce returns 4xx on record update | Logged; retry may be inappropriate without remediation |

## Sequence Diagram

```
dmapiWriteOrchestrator -> dmapiRemoteClientGateway: Read/write Salesforce (sync)
dmapiRemoteClientGateway -> salesForce: GET/POST/PUT record (HTTPS/REST)
salesForce --> dmapiRemoteClientGateway: 200 OK / record data
dmapiRemoteClientGateway --> dmapiWriteOrchestrator: Salesforce response

dmapiAsyncDispatch -> continuumDealManagementApiRedis: Resque.enqueue(SalesforceSyncJob)
dmapiWorkerExecution -> continuumDealManagementApiRedis: Dequeue job
dmapiWorkerExecution -> dmapiWorkerRemoteClientGateway: Execute Salesforce sync
dmapiWorkerRemoteClientGateway -> salesForce: POST/PUT record (HTTPS/REST)
salesForce --> dmapiWorkerRemoteClientGateway: 200 OK
dmapiWorkerExecution -> dmapiHistoryAndPersistence: Persist sync result
dmapiHistoryAndPersistence -> continuumDealManagementApiMySql: INSERT history event
```

## Related

- Architecture dynamic view: `components-dmapi-worker`
- Related flows: [Worker Write Execution](worker-write-execution.md), [Async Write Dispatch](async-write-dispatch.md)

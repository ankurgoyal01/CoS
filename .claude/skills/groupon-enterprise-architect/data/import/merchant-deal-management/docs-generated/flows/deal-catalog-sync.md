---
service: "merchant-deal-management"
title: "Deal Catalog Synchronization"
generated: "2026-03-03"
type: flow
flow_name: "deal-catalog-sync"
flow_type: synchronous
trigger: "Deal write request requiring deal catalog entity creation or update"
participants:
  - "continuumDealManagementApi"
  - "dmapiWriteOrchestrator"
  - "dmapiRemoteClientGateway"
  - "continuumDealCatalogService"
  - "continuumDealManagementApiWorker"
  - "dmapiWorkerRemoteClientGateway"
architecture_ref: "components-dmapi-dmapiHttpApi"
---

# Deal Catalog Synchronization

## Summary

The Deal Catalog Synchronization flow covers how the Merchant Deal Management service propagates deal entity changes to the Deal Catalog Service. The API calls the Deal Catalog Service synchronously during write orchestration for operations that require an immediate catalog response. The worker calls the Deal Catalog Service asynchronously for catalog updates that are enqueued for background processing. Both the `dmapiRemoteClientGateway` (API-side) and `dmapiWorkerRemoteClientGateway` (worker-side) participate in this flow.

## Trigger

- **Type**: api-call (internal, triggered by inbound deal write request)
- **Source**: Inbound deal write or update to `continuumDealManagementApi` that affects deal catalog entities
- **Frequency**: On-demand, per deal write operation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Write Orchestration | Initiates catalog sync as part of write flow | `dmapiWriteOrchestrator` |
| Remote Client Gateway (API) | Executes synchronous HTTP call to Deal Catalog Service | `dmapiRemoteClientGateway` |
| Deal Catalog Service | Receives and processes deal entity create/update | `continuumDealCatalogService` |
| Worker Execution | Initiates async catalog update from background job | `dmapiWorkerExecution` |
| Worker Remote Client Gateway | Executes asynchronous HTTP call to Deal Catalog Service | `dmapiWorkerRemoteClientGateway` |

## Steps

### Synchronous path (API-side)

1. **Initiate catalog call**: Write Orchestrator determines a deal catalog update is needed and invokes the Remote Client Gateway.
   - From: `dmapiWriteOrchestrator`
   - To: `dmapiRemoteClientGateway`
   - Protocol: direct (in-process)

2. **Call Deal Catalog Service**: Remote Client Gateway sends HTTP/JSON request to the Deal Catalog Service to create or update the deal catalog entity.
   - From: `dmapiRemoteClientGateway`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

3. **Receive catalog response**: Deal Catalog Service returns updated entity data; Write Orchestrator incorporates the response into the overall write flow.
   - From: `continuumDealCatalogService`
   - To: `dmapiRemoteClientGateway` → `dmapiWriteOrchestrator`
   - Protocol: HTTP/JSON

### Asynchronous path (Worker-side)

4. **Worker dequeues catalog update job**: Worker Execution dequeues a Resque job specifically for async deal catalog processing.
   - From: `continuumDealManagementApiRedis`
   - To: `dmapiWorkerExecution`
   - Protocol: Resque/Redis

5. **Call Deal Catalog Service asynchronously**: Worker Remote Client Gateway sends HTTP/JSON request to the Deal Catalog Service for the catalog update.
   - From: `dmapiWorkerRemoteClientGateway`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable (sync path) | Faraday client error surfaces to Write Orchestrator | API may return HTTP 5xx or queue for retry |
| Deal Catalog Service unavailable (async path) | Resque retry re-enqueues the job | Worker retries until success or retry limit exhausted |
| Invalid catalog payload | Deal Catalog Service returns 4xx | Error logged; sync path returns error to caller; async path may retry or fail |

## Sequence Diagram

```
dmapiWriteOrchestrator -> dmapiRemoteClientGateway: Update deal catalog (sync)
dmapiRemoteClientGateway -> continuumDealCatalogService: PUT /deals/:id (HTTP/JSON)
continuumDealCatalogService --> dmapiRemoteClientGateway: 200 OK / updated entity
dmapiRemoteClientGateway --> dmapiWriteOrchestrator: Catalog response

dmapiWorkerExecution -> dmapiWorkerRemoteClientGateway: Update deal catalog (async)
dmapiWorkerRemoteClientGateway -> continuumDealCatalogService: PUT /deals/:id (HTTP/JSON)
continuumDealCatalogService --> dmapiWorkerRemoteClientGateway: 200 OK
```

## Related

- Architecture dynamic view: `components-dmapi-dmapiHttpApi`
- Related flows: [Synchronous Deal Write](deal-write-synchronous.md), [Worker Write Execution](worker-write-execution.md)

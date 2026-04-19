---
service: "etorch"
title: "Deal Update Batch Job"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-update-batch-job"
flow_type: batch
trigger: "HTTP POST to /v1/getaways/extranet/jobs/deal_update or Quartz schedule"
participants:
  - "continuumEtorchApp"
  - "continuumEtorchWorker"
  - "etorchAppControllers"
  - "etorchWorkerScheduler"
  - "continuumDealManagementApi"
  - "larcExternal_ce2d"
  - "getawaysInventoryExternal_b51b"
architecture_ref: "dynamic-etorchDealUpdateBatch"
---

# Deal Update Batch Job

## Summary

A deal update batch job collects pending deal change requests for Getaways hotel offers and pushes them to the Deal Management API. The job can be triggered on-demand via an internal API call to `POST /v1/getaways/extranet/jobs/deal_update` handled by `continuumEtorchApp`, or it may be initiated by the Quartz scheduler inside `continuumEtorchWorker`. The flow consults LARC for approved rate and discount rules, reads current inventory state from Getaways Inventory, and submits the assembled deal update payload to `continuumDealManagementApi`.

## Trigger

- **Type**: api-call (on-demand) or schedule (Quartz)
- **Source**: Internal orchestration process calling `POST /v1/getaways/extranet/jobs/deal_update`, or the Quartz scheduler in `continuumEtorchWorker`
- **Frequency**: On-demand; periodic schedule configured via Quartz (exact cron expression managed in AppConfig)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch App | Exposes the job trigger endpoint; delegates execution | `continuumEtorchApp` |
| Extranet Controllers | Receives and validates the job trigger request | `etorchAppControllers` |
| eTorch Worker | Executes the batch job logic on schedule | `continuumEtorchWorker` |
| Job Scheduler | Triggers the deal update job handler via Quartz | `etorchWorkerScheduler` |
| LARC | Provides approved rates and discount rules for deals | `larcExternal_ce2d` |
| Getaways Inventory | Provides current inventory state for deal validation | `getawaysInventoryExternal_b51b` |
| Deal Management API | Receives assembled deal update payload | `continuumDealManagementApi` |

## Steps

1. **Receives job trigger**: An internal caller sends `POST /v1/getaways/extranet/jobs/deal_update` to eTorch App, or the Quartz scheduler fires in eTorch Worker.
   - From: `Internal orchestration or etorchWorkerScheduler`
   - To: `etorchAppControllers` (API path) or `etorchWorkerJobs` (scheduled path)
   - Protocol: REST (HTTP) for API trigger; Direct (in-process) for Quartz trigger

2. **Validates trigger request**: Extranet Controllers authenticate the API key and confirm the request is from an authorized internal caller.
   - From: `etorchAppControllers`
   - To: `etorchAppOrchestration`
   - Protocol: Direct (in-process)

3. **Loads approved rates**: Orchestration calls LARC to retrieve the current approved rates and discount rules applicable to the hotel deals being updated.
   - From: `continuumEtorchApp` or `continuumEtorchWorker`
   - To: `larcExternal_ce2d`
   - Protocol: REST (HTTP)

4. **Reads current inventory state**: Orchestration queries Getaways Inventory for current availability data needed to compose the deal update payload.
   - From: `continuumEtorchApp` or `continuumEtorchWorker`
   - To: `getawaysInventoryExternal_b51b`
   - Protocol: REST (HTTP)

5. **Assembles deal update payload**: Orchestration combines approved rates, inventory state, and deal change data into the update payload.
   - From: `etorchAppOrchestration` or `etorchWorkerJobs`
   - To: (in-process)
   - Protocol: Direct (in-process)

6. **Submits deal update**: The assembled payload is submitted to Deal Management API.
   - From: `continuumEtorchApp` or `continuumEtorchWorker`
   - To: `continuumDealManagementApi`
   - Protocol: REST (HTTP)

7. **Returns job result**: On success, eTorch returns an HTTP 200 (API-triggered path) or records the job completion in Quartz (scheduled path).
   - From: `etorchAppControllers`
   - To: `Internal caller`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthorized API call | Request rejected by `etorchAppControllers` | HTTP 401; no deals updated |
| LARC unavailable | HTTP error propagated by `etorchAppClients` or `etorchWorkerClients` | Job fails; rate data unavailable; deal update not submitted |
| Getaways Inventory unavailable | HTTP error propagated | Job fails; inventory state cannot be loaded |
| Deal Management API unavailable | HTTP error propagated | Deal updates not applied; merchant changes are not reflected; check `DEAL_MANAGEMENT_API_BASE_URL` |
| Quartz job stuck or not running | Quartz scheduler failure | Scheduled deal updates cease; check `continuumEtorchWorker` logs from `etorchWorkerScheduler` |

## Sequence Diagram

```
InternalCaller -> etorchAppControllers: POST /v1/getaways/extranet/jobs/deal_update
etorchAppControllers -> etorchAppOrchestration: validate and delegate
etorchAppOrchestration -> larcExternal_ce2d: GET approved rates
larcExternal_ce2d --> etorchAppOrchestration: rate rules
etorchAppOrchestration -> getawaysInventoryExternal_b51b: GET inventory state
getawaysInventoryExternal_b51b --> etorchAppOrchestration: inventory data
etorchAppOrchestration -> continuumDealManagementApi: POST deal update payload
continuumDealManagementApi --> etorchAppOrchestration: 200 OK / updated deal IDs
etorchAppOrchestration --> etorchAppControllers: job result
etorchAppControllers --> InternalCaller: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-etorchDealUpdateBatch`
- Related flows: [Hotel Data Management](hotel-data-management.md), [Low Inventory Batch Reporting](low-inventory-batch-reporting.md)
- [API Surface](../api-surface.md) — `POST /v1/getaways/extranet/jobs/deal_update` endpoint definition
- [Integrations](../integrations.md) — Deal Management API and LARC integration details
- [Configuration](../configuration.md) — `DEAL_MANAGEMENT_API_BASE_URL`, `LARC_BASE_URL`

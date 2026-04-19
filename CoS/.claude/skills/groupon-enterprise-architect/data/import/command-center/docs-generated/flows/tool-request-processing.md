---
service: "command-center"
title: "Tool Request Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "tool-request-processing"
flow_type: synchronous
trigger: "Operator submits a tool action via the Command Center web UI"
participants:
  - "continuumCommandCenterWeb"
  - "continuumCommandCenterMysql"
  - "continuumCommandCenterWorker"
  - "continuumDealManagementApi"
  - "continuumVoucherInventoryService"
  - "salesForce"
architecture_ref: "dynamic-cmdcenter-tool-request-processing"
---

# Tool Request Processing

## Summary

An internal operator submits a tool action request through the Command Center web UI. The web layer validates the request, persists the job record and enqueues a delayed job, then returns an acknowledgment to the operator. The worker dequeues the job and executes the required downstream mutations — against the Deal Management API, Voucher Inventory Service, and/or Salesforce — recording the outcome back to MySQL. This flow separates synchronous request acceptance from asynchronous bulk execution to prevent long-running operations from blocking the web process.

## Trigger

- **Type**: user-action
- **Source**: Operator submits a tool form via `continuumCommandCenterWeb` web UI
- **Frequency**: On-demand (per operator action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Command Center Web | Receives request, validates input, persists job, schedules background work | `continuumCommandCenterWeb` |
| Command Center MySQL | Stores the job record and delayed_job queue entry | `continuumCommandCenterMysql` |
| Command Center Worker | Dequeues and executes the job; records result | `continuumCommandCenterWorker` |
| Deal Management API | Receives asynchronous deal/option/distribution-window mutations | `continuumDealManagementApi` |
| Voucher Inventory Service | Provides voucher/inventory state or receives mutations (job-dependent) | `continuumVoucherInventoryService` |
| Salesforce | Receives asynchronous CRM attribute updates (tool-dependent) | `salesForce` |

## Steps

1. **Receive tool request**: Operator submits a tool action form.
   - From: Operator (browser)
   - To: `cmdCenter_webControllers` within `continuumCommandCenterWeb`
   - Protocol: HTTP (form POST or JSON)

2. **Validate and dispatch**: Controllers delegate to domain services for validation and job creation.
   - From: `cmdCenter_webControllers`
   - To: `cmdCenter_webDomainServices`
   - Protocol: direct (in-process)

3. **Persist job record**: Domain services write the tool job and request metadata to MySQL.
   - From: `cmdCenter_webDomainServices` via `cmdCenter_webPersistence`
   - To: `continuumCommandCenterMysql` (`cmdCenter_schema`)
   - Protocol: ActiveRecord / MySQL

4. **Enqueue delayed job**: Domain services enqueue a background job for asynchronous execution.
   - From: `cmdCenter_webDomainServices`
   - To: `cmdCenter_workerRunner` within `continuumCommandCenterWorker` (via delayed_job record in MySQL)
   - Protocol: Delayed Job (MySQL-backed queue)

5. **Acknowledge to operator**: Web layer returns a response confirming the job has been scheduled.
   - From: `continuumCommandCenterWeb`
   - To: Operator (browser)
   - Protocol: HTTP (redirect or JSON acknowledgment)

6. **Dequeue job**: Worker polls MySQL, locks the delayed_job record, and loads the job payload.
   - From: `cmdCenter_workerRunner`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

7. **Execute downstream mutations**: Worker job handler calls applicable platform APIs based on tool type.
   - From: `cmdCenter_workerJobs` via `cmdCenter_workerApiClients`
   - To: `continuumDealManagementApi` (deal/option mutations), `continuumVoucherInventoryService` (voucher workflows, if applicable), `salesForce` (CRM updates, if applicable)
   - Protocol: HTTP / JSON (platform APIs), REST (Salesforce)

8. **Record outcome**: Worker writes the final execution result, audit record, and any report artifact reference to MySQL.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql` (`cmdCenter_schema`)
   - Protocol: ActiveRecord / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure on submission | `cmdCenter_webDomainServices` returns error; job not persisted | Operator sees validation error; no job created |
| Downstream API error during execution | Delayed Job marks job as failed; retries per retry policy | Job retried up to max attempts; marked failed permanently on exhaustion |
| MySQL connectivity loss | Web returns 500; worker loses queue access | No new jobs accepted; worker idles until connectivity restored |
| Worker crash mid-execution | Delayed Job lock timeout releases the record | Job re-queued and retried by next available worker |

## Sequence Diagram

```
Operator        -> continuumCommandCenterWeb  : Submits tool action form (HTTP POST)
cmdCenter_webControllers -> cmdCenter_webDomainServices : Validates and dispatches request
cmdCenter_webDomainServices -> cmdCenter_webPersistence : Writes job record
cmdCenter_webPersistence -> continuumCommandCenterMysql : Persists job and delayed_job entry (ActiveRecord/MySQL)
cmdCenter_webDomainServices -> cmdCenter_workerRunner   : Enqueues delayed job (Delayed Job)
continuumCommandCenterWeb  -> Operator        : Returns acknowledgment (HTTP)
cmdCenter_workerRunner -> continuumCommandCenterMysql  : Polls and locks delayed_job record (ActiveRecord/MySQL)
cmdCenter_workerJobs   -> continuumDealManagementApi   : Executes deal mutation (HTTP/JSON)
cmdCenter_workerJobs   -> continuumVoucherInventoryService : Fetches voucher state if required (HTTP/JSON)
cmdCenter_workerJobs   -> salesForce                   : Updates CRM attributes if required (REST)
cmdCenter_workerPersistence -> continuumCommandCenterMysql : Stores result and audit record (ActiveRecord/MySQL)
```

## Related

- Architecture dynamic view: `dynamic-cmdcenter-tool-request-processing`
- Related flows: [Background Job Execution](background-job-execution.md), [Workflow Notification](workflow-notification.md), [Report Artifact Generation](report-artifact-generation.md)

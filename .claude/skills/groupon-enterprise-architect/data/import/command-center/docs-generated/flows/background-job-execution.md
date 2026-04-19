---
service: "command-center"
title: "Background Job Execution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "background-job-execution"
flow_type: asynchronous
trigger: "Delayed Job worker dequeues a queued job record from continuumCommandCenterMysql"
participants:
  - "continuumCommandCenterWorker"
  - "continuumCommandCenterMysql"
  - "continuumDealManagementApi"
  - "continuumVoucherInventoryService"
  - "continuumOrdersService"
  - "salesForce"
architecture_ref: "dynamic-cmdcenter-tool-request-processing"
---

# Background Job Execution

## Summary

The Command Center Worker (`continuumCommandCenterWorker`) continuously polls the Delayed Job queue in MySQL, dequeues available job records, and dispatches them to the appropriate job handler class. Each handler executes the required downstream API mutations — against Deal Management API, Voucher Inventory Service, Orders Service, and/or Salesforce — depending on the tool type. The worker records execution progress and the final outcome back to MySQL, making results visible to operators via the web layer.

## Trigger

- **Type**: schedule (continuous polling)
- **Source**: `cmdCenter_workerRunner` polls `continuumCommandCenterMysql` for available delayed_job records
- **Frequency**: Continuous; poll interval determined by Delayed Job configuration (typically seconds)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Command Center Worker | Dequeues, dispatches, executes, and records job outcomes | `continuumCommandCenterWorker` |
| Command Center MySQL | Stores queue records, job state, and execution results | `continuumCommandCenterMysql` |
| Deal Management API | Receives deal, option, and distribution-window mutations | `continuumDealManagementApi` |
| Voucher Inventory Service | Receives voucher workflow calls (job-dependent) | `continuumVoucherInventoryService` |
| Orders Service | Receives order-related workflow calls (job-dependent) | `continuumOrdersService` |
| Salesforce | Receives asynchronous CRM update calls (job-dependent) | `salesForce` |

## Steps

1. **Poll queue**: Worker runner queries `continuumCommandCenterMysql` for unlocked delayed_job records with `run_at` in the past.
   - From: `cmdCenter_workerRunner`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

2. **Lock and dequeue**: Worker runner acquires a lock on the job record to prevent duplicate execution.
   - From: `cmdCenter_workerRunner`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL (row-level lock)

3. **Dispatch to job handler**: Runner deserializes the job payload and dispatches to the appropriate `cmdCenter_workerJobs` handler class.
   - From: `cmdCenter_workerRunner`
   - To: `cmdCenter_workerJobs`
   - Protocol: direct (in-process)

4. **Load execution state**: Job handler loads current tool, user, and input data needed for execution.
   - From: `cmdCenter_workerJobs` via `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

5. **Execute downstream mutations**: Job handler calls applicable downstream platform APIs based on tool type.
   - From: `cmdCenter_workerJobs` via `cmdCenter_workerApiClients`
   - To: `continuumDealManagementApi` and/or `continuumVoucherInventoryService` and/or `continuumOrdersService` and/or `salesForce`
   - Protocol: HTTP / JSON (platform APIs), REST (Salesforce)

6. **Record outcome**: Worker writes the execution result, updates job status, and unlocks the delayed_job record.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Downstream API returns error | Delayed Job catches exception; increments attempt count; re-schedules retry | Job retried up to `max_attempts`; marked permanently failed on exhaustion |
| Worker process crash mid-job | Lock timeout expires; job becomes eligible for re-dequeue | Next worker poll picks up and re-executes the job |
| MySQL write failure on result | Exception propagated; job marked failed by Delayed Job | Job retried; operator notified of failure via Mailer on terminal failure |
| Unhandled exception in job handler | Delayed Job records error and backtrace on the delayed_job record | Job marked failed; available for inspection in `continuumCommandCenterMysql` |

## Sequence Diagram

```
cmdCenter_workerRunner   -> continuumCommandCenterMysql     : Polls for available delayed_job records (ActiveRecord/MySQL)
cmdCenter_workerRunner   -> continuumCommandCenterMysql     : Locks job record (ActiveRecord/MySQL)
cmdCenter_workerRunner   -> cmdCenter_workerJobs            : Dispatches deserialized job handler (in-process)
cmdCenter_workerJobs     -> continuumCommandCenterMysql     : Loads execution state (ActiveRecord/MySQL)
cmdCenter_workerJobs     -> continuumDealManagementApi      : Executes deal mutations (HTTP/JSON)
cmdCenter_workerJobs     -> continuumVoucherInventoryService: Processes voucher workflows if required (HTTP/JSON)
cmdCenter_workerJobs     -> continuumOrdersService          : Processes order workflows if required (HTTP/JSON)
cmdCenter_workerJobs     -> salesForce                      : Updates CRM attributes if required (REST)
cmdCenter_workerPersistence -> continuumCommandCenterMysql  : Writes result and audit record (ActiveRecord/MySQL)
```

## Related

- Architecture dynamic view: `dynamic-cmdcenter-tool-request-processing`
- Related flows: [Tool Request Processing](tool-request-processing.md), [Report Artifact Generation](report-artifact-generation.md), [Workflow Notification](workflow-notification.md)

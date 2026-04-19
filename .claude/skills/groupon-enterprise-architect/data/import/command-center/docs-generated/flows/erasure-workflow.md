---
service: "command-center"
title: "Erasure Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "erasure-workflow"
flow_type: event-driven
trigger: "messageBus delivers an erasure event to continuumCommandCenterWorker"
participants:
  - "messageBus"
  - "continuumCommandCenterWorker"
  - "continuumCommandCenterMysql"
  - "continuumOrdersService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-cmdcenter-tool-request-processing"
---

# Erasure Workflow

## Summary

The Erasure Workflow is triggered when the internal `messageBus` delivers a data erasure event to `continuumCommandCenterWorker`. This supports Groupon's data subject erasure obligations (e.g., GDPR right-to-erasure requests). The worker consumes the event, determines which Command Center-owned data and downstream platform data must be removed or anonymized, coordinates with applicable platform services, and records the erasure outcome to MySQL for audit purposes.

## Trigger

- **Type**: event
- **Source**: `messageBus` (MBus) delivers an erasure event to `continuumCommandCenterWorker`
- **Frequency**: On-demand (triggered by data subject erasure requests processed upstream)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers erasure events to the worker | `messageBus` |
| Command Center Worker | Consumes erasure events and orchestrates data removal | `continuumCommandCenterWorker` |
| Command Center MySQL | Stores erasure job state and audit records; holds Command Center-owned user/job data subject to erasure | `continuumCommandCenterMysql` |
| Orders Service | Provides or accepts order-related erasure actions (job-dependent) | `continuumOrdersService` |
| Voucher Inventory Service | Provides or accepts voucher-related erasure actions (job-dependent) | `continuumVoucherInventoryService` |

## Steps

1. **Receive erasure event**: `messageBus` delivers an erasure event payload to `continuumCommandCenterWorker`.
   - From: `messageBus`
   - To: `continuumCommandCenterWorker`
   - Protocol: MBus

2. **Dispatch to erasure job handler**: Worker runner routes the event to the appropriate erasure job handler within `cmdCenter_workerJobs`.
   - From: `cmdCenter_workerRunner`
   - To: `cmdCenter_workerJobs`
   - Protocol: direct (in-process)

3. **Load subject data**: Erasure handler queries MySQL to identify Command Center records associated with the erasure subject.
   - From: `cmdCenter_workerJobs` via `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

4. **Execute erasure against Command Center data**: Handler removes or anonymizes user, job, log, and report artifact records owned by Command Center for the subject.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

5. **Coordinate with downstream services (as applicable)**: Handler calls downstream platform APIs to trigger order-related or voucher-related erasure actions if the erasure scope requires it.
   - From: `cmdCenter_workerApiClients`
   - To: `continuumOrdersService` (if applicable), `continuumVoucherInventoryService` (if applicable)
   - Protocol: HTTP / JSON

6. **Record erasure outcome**: Handler writes an audit record of the erasure completion to MySQL.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus event delivery failure | MBus retry or dead letter handling (outside Command Center) | Event redelivered; Command Center processes on next delivery |
| MySQL write failure during erasure | Delayed Job retry logic applies if event was converted to a job | Erasure retried; audit record written on success |
| Downstream service erasure call failure | Worker retries via Delayed Job retry policy | Retried up to max attempts; failure recorded for manual follow-up |
| Partial erasure (some steps succeed, some fail) | Each step recorded; failed steps eligible for retry or manual remediation | Audit trail in `continuumCommandCenterMysql` enables identification of incomplete erasure |

## Sequence Diagram

```
messageBus               -> continuumCommandCenterWorker    : Delivers erasure event (MBus)
cmdCenter_workerRunner   -> cmdCenter_workerJobs            : Dispatches erasure job handler (in-process)
cmdCenter_workerJobs     -> continuumCommandCenterMysql     : Loads subject-associated records (ActiveRecord/MySQL)
cmdCenter_workerPersistence -> continuumCommandCenterMysql  : Removes/anonymizes Command Center data (ActiveRecord/MySQL)
cmdCenter_workerApiClients -> continuumOrdersService        : Triggers order erasure actions if required (HTTP/JSON)
cmdCenter_workerApiClients -> continuumVoucherInventoryService : Triggers voucher erasure actions if required (HTTP/JSON)
cmdCenter_workerPersistence -> continuumCommandCenterMysql  : Writes erasure audit record (ActiveRecord/MySQL)
```

## Related

- Architecture dynamic view: `dynamic-cmdcenter-tool-request-processing`
- Related flows: [Background Job Execution](background-job-execution.md)

---
service: "etorch"
title: "Low Inventory Batch Reporting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "low-inventory-batch-reporting"
flow_type: scheduled
trigger: "Quartz scheduler in continuumEtorchWorker"
participants:
  - "continuumEtorchWorker"
  - "etorchWorkerScheduler"
  - "getawaysInventoryExternal_b51b"
  - "notificationServiceExternal_5b7e"
architecture_ref: "dynamic-etorchLowInventoryReport"
---

# Low Inventory Batch Reporting

## Summary

`continuumEtorchWorker` runs a periodic Quartz job that scans hotel inventory levels via Getaways Inventory, identifies hotels whose available room inventory has dropped below a threshold, and dispatches alert notifications to hotel operators and internal stakeholders via Notification Service. This flow is entirely internal — it runs without a merchant HTTP trigger and produces no synchronous API response.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`etorchWorkerScheduler`) inside `continuumEtorchWorker`
- **Frequency**: Periodic; exact cron expression managed via AppConfig (may be suppressed or reduced in frequency in non-production environments)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch Worker | Hosts and executes the low inventory batch job | `continuumEtorchWorker` |
| Job Scheduler | Fires the low inventory job on the configured Quartz schedule | `etorchWorkerScheduler` |
| Getaways Inventory | Provides current hotel room availability and inventory levels | `getawaysInventoryExternal_b51b` |
| Notification Service | Delivers low inventory alert emails to hotel operators and stakeholders | `notificationServiceExternal_5b7e` |

## Steps

1. **Scheduler fires**: Quartz triggers the low inventory reporting job on its configured schedule.
   - From: `etorchWorkerScheduler`
   - To: `etorchWorkerJobs`
   - Protocol: Direct (in-process)

2. **Queries inventory levels**: The job handler calls Getaways Inventory to retrieve current availability data for all monitored hotels.
   - From: `continuumEtorchWorker`
   - To: `getawaysInventoryExternal_b51b`
   - Protocol: REST (HTTP)

3. **Identifies low-inventory hotels**: The job handler evaluates returned inventory data against low-inventory thresholds and compiles a list of affected hotel properties.
   - From: `etorchWorkerJobs`
   - To: (in-process evaluation)
   - Protocol: Direct (in-process)

4. **Dispatches alert notifications**: For each hotel identified as low-inventory, the job handler calls Notification Service to send alert emails to the relevant hotel operator contacts and internal stakeholders.
   - From: `continuumEtorchWorker`
   - To: `notificationServiceExternal_5b7e`
   - Protocol: REST (HTTP)

5. **Records job completion**: Quartz records the job outcome (success or failure) in the scheduler context. Failures are logged for monitoring.
   - From: `etorchWorkerJobs`
   - To: `etorchWorkerScheduler`
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Getaways Inventory unavailable | HTTP error from `etorchWorkerClients` | Job fails; low inventory scan cannot complete; no alerts sent; Quartz records failure |
| Notification Service unavailable | HTTP error from `etorchWorkerClients` | Alerts not delivered; non-critical to core extranet operations; job may partially succeed |
| No low-inventory hotels found | Normal exit condition | No notifications sent; job completes successfully |
| Quartz scheduler not running | Worker process not started or scheduler misconfigured | Periodic scans cease entirely; no low inventory alerts generated; verify `continuumEtorchWorker` deployment and `etorchWorkerScheduler` logs |
| Partial notification failure | Error for individual hotel notification | Logged per-hotel; remaining hotels processed; overall job may still succeed |

## Sequence Diagram

```
etorchWorkerScheduler -> etorchWorkerJobs: trigger low inventory job
etorchWorkerJobs -> getawaysInventoryExternal_b51b: GET inventory levels (all hotels)
getawaysInventoryExternal_b51b --> etorchWorkerJobs: inventory data
etorchWorkerJobs -> etorchWorkerJobs: evaluate thresholds; compile low-inventory list
etorchWorkerJobs -> notificationServiceExternal_5b7e: POST low inventory alert (hotel A)
notificationServiceExternal_5b7e --> etorchWorkerJobs: 200 OK
etorchWorkerJobs -> notificationServiceExternal_5b7e: POST low inventory alert (hotel B)
notificationServiceExternal_5b7e --> etorchWorkerJobs: 200 OK
etorchWorkerJobs --> etorchWorkerScheduler: job complete
```

## Related

- Architecture dynamic view: `dynamic-etorchLowInventoryReport`
- Related flows: [Deal Update Batch Job](deal-update-batch-job.md), [Accounting Report Generation](accounting-report-generation.md)
- [Integrations](../integrations.md) — Getaways Inventory and Notification Service integration details
- [Configuration](../configuration.md) — `GETAWAYS_INVENTORY_BASE_URL`, `NOTIFICATION_SERVICE_BASE_URL`
- [Runbook](../runbook.md) — troubleshooting worker jobs not running

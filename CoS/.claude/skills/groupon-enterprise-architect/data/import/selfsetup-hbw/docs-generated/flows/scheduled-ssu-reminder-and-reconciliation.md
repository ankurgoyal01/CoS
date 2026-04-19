---
service: "selfsetup-hbw"
title: "Scheduled SSU Reminder and Reconciliation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-ssu-reminder-and-reconciliation"
flow_type: scheduled
trigger: "Cron schedule (Kubernetes CronJob or in-container cron)"
participants:
  - "ssuPersistence"
  - "continuumSsuDatabase"
  - "selfsetupHbw_ssuSalesforceClient"
  - "salesForce"
  - "ssuLogger"
  - "ssuMetricsReporter"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Scheduled SSU Reminder and Reconciliation

## Summary

Two background cron jobs run on a schedule outside of merchant sessions. The first identifies merchants whose self-setup is incomplete after a defined period and dispatches reminder notifications (emails) to encourage them to complete the process. The second reconciles local MySQL setup state against the data warehouse (DWH), ensuring accurate reporting of setup completion rates across EMEA markets.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (EKS) or in-container cron daemon
- **Frequency**: Scheduled (exact intervals managed in deployment configuration; not evidenced in the inventory)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cron scheduler | Triggers both job entry points on schedule | — (EKS CronJob) |
| Data Access | Queries MySQL for incomplete setups and reconciliation records | `ssuPersistence` |
| SSU HBW Database | Source of setup state; updated with reconciliation results | `continuumSsuDatabase` |
| Salesforce API Client | Queries Salesforce for up-to-date opportunity status during reconciliation | `selfsetupHbw_ssuSalesforceClient` |
| Salesforce | Provides current opportunity status for reconciliation comparison | `salesForce` |
| Logging | Records job execution, errors, and outcomes | `ssuLogger` |
| Metrics Reporter | Emits cron job execution and reminder counts | `ssuMetricsReporter` |

## Steps

### Reminder Job

1. **Job triggered by scheduler**: Cron scheduler executes the reminder job entry point.
   - From: Cron scheduler
   - To: Reminder job handler (PHP CLI / Zend controller action)
   - Protocol: Process exec

2. **Queries incomplete setups**: The job calls `ssuPersistence` to retrieve all setup records with status = in-progress and a creation timestamp older than the reminder threshold.
   - From: Job handler via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

3. **Dispatches reminder notifications**: For each eligible merchant, the job sends a reminder email (via the configured mail transport). Email content is localised using Zend_Translate for the merchant's locale.
   - From: Job handler
   - To: Mail transport (SMTP or mail relay)
   - Protocol: SMTP

4. **Updates reminder sent timestamp**: `ssuPersistence` writes the reminder dispatch timestamp back to the setup record to prevent duplicate reminders.
   - From: Job handler via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

5. **Emits job metrics and logs**: `ssuMetricsReporter` records reminder count; `ssuLogger` logs job completion and any skipped/failed sends.
   - From: `ssuMetricsReporter` / `ssuLogger`
   - To: `telegrafAgent` / `logAggregation`
   - Protocol: InfluxDB line protocol / Splunk HEC

### DWH Reconciliation Job

6. **Job triggered by scheduler**: Cron scheduler executes the reconciliation job entry point.
   - From: Cron scheduler
   - To: Reconciliation job handler (PHP CLI / Zend controller action)
   - Protocol: Process exec

7. **Reads local setup records**: `ssuPersistence` fetches all setup records modified since the last reconciliation run.
   - From: Job handler via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

8. **Queries Salesforce for opportunity status**: `selfsetupHbw_ssuSalesforceClient` checks current Salesforce opportunity statuses for the retrieved records to detect discrepancies.
   - From: `selfsetupHbw_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: REST / HTTPS (SOQL)

9. **Pushes reconciliation data to DWH**: The job delivers the reconciled setup state to the data warehouse (DWH) via the configured reporting pipeline.
   - From: Job handler
   - To: DWH reporting endpoint / database
   - Protocol: > Not fully evidenced — managed externally

10. **Logs reconciliation outcome**: `ssuLogger` records counts of reconciled, mismatched, and failed records.
    - From: `ssuLogger`
    - To: `logAggregation`
    - Protocol: Splunk HEC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL query failure in reminder job | Exception caught; job logs error and aborts | No reminders sent for that run; next scheduled run will retry eligible records |
| Mail send failure for individual merchant | Per-merchant exception caught; error logged | Remaining merchants still processed; failed merchant retried on next run |
| Salesforce query failure in reconciliation | Exception caught; job logs error | Reconciliation aborted for that batch; DWH data may be stale until next run |
| DWH push failure | Exception caught; job logs error | Local MySQL remains source of truth; DWH updated on next successful reconciliation run |

## Sequence Diagram

```
CronScheduler -> ReminderJob: trigger
ReminderJob -> ssuPersistence: getIncompleteSetups(olderThan=threshold)
ssuPersistence -> continuumSsuDatabase: SELECT WHERE status=in-progress AND created_at < X
continuumSsuDatabase --> ssuPersistence: [merchant records]
ReminderJob -> MailTransport: sendReminder(merchant, locale)
ReminderJob -> ssuPersistence: updateReminderSentAt(merchantId)
ssuPersistence -> continuumSsuDatabase: UPDATE reminder_sent_at
ssuMetricsReporter -> telegrafAgent: reminders_sent_count++
ssuLogger -> logAggregation: INFO reminder job complete

CronScheduler -> ReconciliationJob: trigger
ReconciliationJob -> ssuPersistence: getModifiedSetups(since=lastRun)
ssuPersistence -> continuumSsuDatabase: SELECT WHERE updated_at > lastRun
ReconciliationJob -> selfsetupHbw_ssuSalesforceClient: checkOpportunityStatus(ids)
selfsetupHbw_ssuSalesforceClient -> salesForce: SOQL query
salesForce --> selfsetupHbw_ssuSalesforceClient: opportunity statuses
ReconciliationJob -> DWH: pushReconciliationData(records)
ssuLogger -> logAggregation: INFO reconciliation complete
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md), [Health Check and Monitoring](health-check-and-monitoring.md)

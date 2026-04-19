---
service: "merchant-preview"
title: "Cron Salesforce Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cron-salesforce-sync"
flow_type: scheduled
trigger: "Scheduled cron execution (Rake task)"
participants:
  - "continuumMerchantPreviewCronWorker"
  - "mpSfCaseCronJob"
  - "mpSalesforceApiClient"
  - "continuumMerchantPreviewDatabase"
  - "salesForce"
  - "smtpRelay"
architecture_ref: "components-continuum-merchant-preview-cron-worker"
---

# Cron Salesforce Sync

## Summary

This flow describes the scheduled background process run by the Merchant Preview Cron Worker. On a regular schedule, the worker reads unresolved comments and workflow records from the local MySQL database, synchronizes them to Salesforce by querying and updating Opportunity and Task records, and dispatches any pending email notifications. This ensures Salesforce remains a reliable source of truth for deal approval state even when inline Salesforce updates fail.

## Trigger

- **Type**: schedule
- **Source**: System cron scheduler executes the Rake task (`mpSfCaseCronJob`) in `continuumMerchantPreviewCronWorker`
- **Frequency**: Scheduled interval (specific cron schedule not defined in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Preview Cron Worker | Host process executing scheduled Rake tasks | `continuumMerchantPreviewCronWorker` |
| Salesforce Case Sync Job | Rake task implementing comment sync and status update logic | `mpSfCaseCronJob` |
| Salesforce API Client | Executes Salesforce query and mutation operations | `mpSalesforceApiClient` |
| Merchant Preview Database | Source of unresolved comments and workflow records | `continuumMerchantPreviewDatabase` |
| Salesforce | Target for comment and approval state synchronization | `salesForce` |
| SMTP Relay | Delivers any scheduled notification emails | `smtpRelay` |

## Steps

1. **Cron fires Rake task**: The system cron scheduler triggers the Salesforce Case Sync Job.
   - From: Cron scheduler
   - To: `mpSfCaseCronJob`
   - Protocol: OS-level cron / Rake invocation

2. **Read unresolved records**: The job queries the database for unresolved comments and pending workflow records.
   - From: `mpSfCaseCronJob`
   - To: `continuumMerchantPreviewDatabase`
   - Protocol: MySQL

3. **Query Salesforce for current state**: The job calls the Salesforce API Client to fetch current Opportunity and Task state for affected deals.
   - From: `mpSfCaseCronJob`
   - To: `mpSalesforceApiClient`
   - Protocol: direct (in-process)

4. **Fetch Salesforce records**: Salesforce API Client executes queries against Salesforce.
   - From: `mpSalesforceApiClient`
   - To: `salesForce`
   - Protocol: HTTPS (databasedotcom)

5. **Update Salesforce records**: The job pushes local comment and approval changes to Salesforce Task and Opportunity records.
   - From: `mpSalesforceApiClient`
   - To: `salesForce`
   - Protocol: HTTPS (databasedotcom)

6. **Send scheduled notifications**: The cron worker dispatches any pending email notifications via SMTP relay.
   - From: `continuumMerchantPreviewCronWorker`
   - To: `smtpRelay`
   - Protocol: SMTP

7. **Emit task logs**: The cron worker emits execution logs to the logging stack.
   - From: `continuumMerchantPreviewCronWorker`
   - To: `loggingStack`
   - Protocol: — (structured logging)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database read failure | Job aborts with error log to `loggingStack` | No sync performed; retried on next scheduled run |
| Salesforce API unavailable | API error logged; job exits gracefully | Salesforce state remains stale until next scheduled run |
| SMTP relay unavailable | Email delivery failure logged | Notifications not sent; retried on next run |

## Sequence Diagram

```
CronScheduler -> mpSfCaseCronJob: Triggers Rake task
mpSfCaseCronJob -> continuumMerchantPreviewDatabase: Reads unresolved comments and workflow records (MySQL)
continuumMerchantPreviewDatabase --> mpSfCaseCronJob: Returns pending records
mpSfCaseCronJob -> mpSalesforceApiClient: Requests Salesforce query/update (direct)
mpSalesforceApiClient -> salesForce: Queries Opportunity/Task records (HTTPS)
salesForce --> mpSalesforceApiClient: Returns current state
mpSalesforceApiClient -> salesForce: Updates Opportunity/Task records (HTTPS)
salesForce --> mpSalesforceApiClient: Confirms update
continuumMerchantPreviewCronWorker -> smtpRelay: Sends scheduled notifications (SMTP)
continuumMerchantPreviewCronWorker -> loggingStack: Emits cron task logs
```

## Related

- Architecture component view: `components-continuum-merchant-preview-cron-worker`
- Related flows: [Merchant Preview Review](merchant-preview-review.md), [Comment Workflow](comment-workflow.md)

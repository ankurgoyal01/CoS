---
service: "general-ledger-gateway"
title: "Import Applied Invoices Job"
generated: "2026-03-03"
type: flow
flow_name: "import-applied-invoices"
flow_type: batch
trigger: "POST /v1/{ledger}/jobs/import-applied-invoices (ad-hoc) or Quartz CronScheduler trigger (when configured)"
participants:
  - "continuumGeneralLedgerGatewayApi"
  - "continuumGeneralLedgerGatewayPostgres"
  - "netSuiteErpExternalContainerUnknown_1a2c"
  - "accountingServiceExternalContainerUnknown_6d4b"
architecture_ref: "dynamic-ImportAppliedInvoices"
---

# Import Applied Invoices Job

## Summary

This batch flow reconciles applied invoice credits between NetSuite and Accounting Service. A trigger (either an API call or a Quartz scheduler tick) causes the job to page through a NetSuite saved search that returns applied vendor credits, then for each result, calls Accounting Service to apply the credit against the corresponding invoice and updates the ledger entry map in PostgreSQL. This is the primary reconciliation mechanism replacing the `schedule.rb` approach previously used in Accounting Service.

> **Note**: As of August 2022, Quartz cron triggers are commented out in all environment configs. The job is triggered exclusively via `POST /v1/{ledger}/jobs/import-applied-invoices`. The `dryRunTestingAppliedInvoices` feature flag is `true` in production and staging, meaning Accounting Service write calls are currently made in dry-run mode.

## Trigger

- **Type**: api-call (primary) or schedule (when Quartz cron triggers are re-enabled)
- **Source**: Accounting Service or operator via Job Resource endpoint; Quartz CronScheduler (commented-out example: `30 5,9,21 * * * ?` UTC for `NORTH_AMERICA_LOCAL_NETSUITE`)
- **Frequency**: On-demand; intended to run multiple times per day per ledger instance when fully activated

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Resource | Receives the trigger request and delegates to Job Service | `continuumGeneralLedgerGatewayApi` |
| Job Service | Schedules the ImportAppliedInvoicesJob via Quartz AdHocScheduler | `continuumGeneralLedgerGatewayApi` |
| Quartz Scheduler | Fires the ImportAppliedInvoicesJob and manages execution lifecycle | `continuumGeneralLedgerGatewayApi` |
| Import Applied Invoices Job | Quartz job that orchestrates download and processing | `continuumGeneralLedgerGatewayApi` |
| Applied Invoice Service | Processes each applied invoice record and calls Accounting Service | `continuumGeneralLedgerGatewayApi` |
| NetSuite Client | Downloads applied invoice records from NetSuite saved search (paginated) | `continuumGeneralLedgerGatewayApi` |
| NetSuite ERP | Returns applied vendor credit records from saved search | `netSuiteErpExternalContainerUnknown_1a2c` |
| Accounting Service Client | Calls Accounting Service to apply each credit to an invoice | `continuumGeneralLedgerGatewayApi` |
| Accounting Service | Applies the credit; returns confirmation | `accountingServiceExternalContainerUnknown_6d4b` |
| Data Access | Updates ledger entry map records in PostgreSQL | `continuumGeneralLedgerGatewayApi` |
| General Ledger Gateway DB | Persists Quartz job state and ledger entry maps | `continuumGeneralLedgerGatewayPostgres` |

## Steps

1. **Receives job trigger request**: Caller issues `POST /v1/{ledger}/jobs/import-applied-invoices`. Job Resource validates the `{ledger}` parameter and checks that `features.jobResourceEnabled` is `true`.
   - From: Accounting Service (or operator)
   - To: `jobResource`
   - Protocol: REST (HTTPS)

2. **Delegates to Job Service**: Job Resource passes the ledger identifier to Job Service.
   - From: `jobResource`
   - To: `jobService`
   - Protocol: Direct (in-process)

3. **Schedules job via Quartz**: Job Service calls Quartz Scheduler (AdHocScheduler) to schedule and immediately fire `ImportAppliedInvoicesJob` with the `generalLedgerInstanceID` as job data.
   - From: `jobService`
   - To: `generalLedgerGateway_quartzScheduler`
   - Protocol: Quartz API (in-process)

4. **Quartz fires the job**: Quartz Scheduler picks up the scheduled trigger and executes `ImportAppliedInvoicesJob`. Job state is persisted to PostgreSQL Quartz job store tables.
   - From: `generalLedgerGateway_quartzScheduler`
   - To: `importAppliedInvoicesJob`
   - Protocol: Quartz (in-process)

5. **Downloads applied invoices from NetSuite (paginated)**: ImportAppliedInvoicesJob calls NetSuite Client to execute the `IMPORT_APPLIED_INVOICES` saved search (e.g., saved search 134 for `NORTH_AMERICA_LOCAL_NETSUITE`). Results are paged using `PaginationParameters`.
   - From: `importAppliedInvoicesJob`
   - To: NetSuite Client → NetSuite ERP RESTlet (GET)
   - Protocol: HTTPS (OAuth 1.0)

6. **Passes results to Applied Invoice Service**: For each page of `AppliedInvoicesSearch` results, the job delegates each record to Applied Invoice Service for processing.
   - From: `importAppliedInvoicesJob`
   - To: `appliedInvoiceService`
   - Protocol: Direct (in-process)

7. **Looks up invoice in Accounting Service**: Applied Invoice Service calls Accounting Service Client to retrieve the existing invoice record (`showInvoice`) using the ledger and NetSuite ledger ID.
   - From: `appliedInvoiceService`
   - To: `generalLedgerGateway_accountingServiceClient` → Accounting Service
   - Protocol: HTTPS

8. **Applies credit in Accounting Service**: Applied Invoice Service calls Accounting Service Client to apply the credit (`applyInvoice`) against the matched invoice, passing the amount. If `dryRunTestingAppliedInvoices` is `true`, the call is sent with `isDryRun=true`.
   - From: `appliedInvoiceService`
   - To: `generalLedgerGateway_accountingServiceClient` → Accounting Service
   - Protocol: HTTPS

9. **Updates ledger entry map**: Applied Invoice Service persists the updated ledger status to the `ledger_entry_maps` table via Data Access.
   - From: `appliedInvoiceService`
   - To: `generalLedgerGateway_dataAccess` → `continuumGeneralLedgerGatewayPostgres`
   - Protocol: JDBC

10. **Returns job trigger response**: Job Resource returns HTTP response (indicating job was scheduled, not that it completed) to the original caller.
    - From: `jobResource`
    - To: Caller
    - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| NetSuite saved search failure | Resilience4j retry | Retried; job fails if retries exhausted; Wavefront alert may fire |
| Accounting Service `showInvoice` failure | Resilience4j retry | Retried; record skipped or job fails on persistent error |
| Accounting Service `applyInvoice` failure | Resilience4j retry | Retried; if dry-run enabled, no state change in Accounting Service |
| Invalid `{ledger}` path parameter | JAX-RS validation | HTTP 400 returned; job not triggered |
| `features.jobResourceEnabled` is `false` | Feature flag check in Job Resource | HTTP 404 or 405 returned; job not triggered |
| Quartz misfire (job delayed beyond threshold) | Quartz misfireThreshold: 5000ms | Job is re-fired by Quartz according to misfire policy |

## Sequence Diagram

```
Caller -> JobResource: POST /v1/{ledger}/jobs/import-applied-invoices
JobResource -> JobService: trigger(ledger)
JobService -> QuartzScheduler: schedule(ImportAppliedInvoicesJob, ledgerInstanceID)
QuartzScheduler -> ImportAppliedInvoicesJob: execute()
ImportAppliedInvoicesJob -> NetSuiteClient: downloadAppliedInvoices(paginationParams)
NetSuiteClient -> NetSuiteERP: GET savedSearch (OAuth 1.0)
NetSuiteERP --> NetSuiteClient: AppliedInvoicesSearch results
NetSuiteClient --> ImportAppliedInvoicesJob: AppliedInvoicesSearch
ImportAppliedInvoicesJob -> AppliedInvoiceService: process(appliedInvoice)
AppliedInvoiceService -> AccountingServiceClient: showInvoice(ledger, ledgerID)
AccountingServiceClient -> AccountingService: GET invoice
AccountingService --> AccountingServiceClient: ShowResponseInvoice
AppliedInvoiceService -> AccountingServiceClient: applyInvoice(ledger, invoiceUUID, creditUUID, amount, isDryRun)
AccountingServiceClient -> AccountingService: PUT apply invoice
AccountingService --> AccountingServiceClient: 200 OK
AppliedInvoiceService -> DataAccess: updateLedgerEntryMap(invoiceUUID, status)
DataAccess -> PostgreSQL: UPDATE ledger_entry_maps
PostgreSQL --> DataAccess: OK
JobResource --> Caller: HTTP response (job scheduled)
```

## Related

- Architecture dynamic view: `dynamic-ImportAppliedInvoices`
- Related flows: [Send Invoice to NetSuite](send-invoice-to-netsuite.md), [Ledger Entry Lookup](ledger-entry-lookup.md)
- Jira: FED-10260 (responsibility transfer), FED-10167/10168/10169 (ImportPaymentsJob — planned next)

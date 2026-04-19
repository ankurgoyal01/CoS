---
service: "accounting-service"
title: "Scheduled Reporting and Reconciliation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-reporting-and-reconciliation"
flow_type: scheduled
trigger: "Cron schedule or Delayed Job timer fires a reporting or reconciliation task"
participants:
  - "continuumAccountingService"
  - "acctSvc_reportingExports"
  - "acctSvc_paymentAndInvoicing"
  - "continuumAccountingMysql"
  - "continuumAccountingRedis"
architecture_ref: "components-continuum-accounting-service"
---

# Scheduled Reporting and Reconciliation

## Summary

The Scheduled Reporting and Reconciliation flow runs periodic finance jobs that aggregate accounting data, produce financial statements, reconcile transaction records, and generate outbound export files for downstream finance systems. Jobs are scheduled via Delayed Job (ActiveRecord-backed) and may also be triggered by the completion of a merchant payment run. This flow is the primary mechanism by which Accounting Service produces authoritative financial reports for the Finance Operations team.

## Trigger

- **Type**: schedule
- **Source**: Delayed Job scheduler or Resque scheduled job; may also be triggered by `acctSvc_paymentAndInvoicing` upon payment run completion
- **Frequency**: Periodic — daily, weekly, and monthly cadences depending on report type

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Reporting and Export Jobs | Executes scheduled reporting, reconciliation, and export tasks | `acctSvc_reportingExports` |
| Payment and Invoicing Engine | Provides finalized payment and invoice data; triggers post-payment reporting | `acctSvc_paymentAndInvoicing` |
| Accounting MySQL | Source of all transaction, invoice, payment, and statement data read by reporting jobs | `continuumAccountingMysql` |
| Accounting Redis | Hosts Resque queues and locks used during export job execution | `continuumAccountingRedis` |

## Steps

1. **Schedule fires**: Delayed Job or Resque scheduled job timer fires, enqueuing a reporting or reconciliation job; alternatively `acctSvc_paymentAndInvoicing` directly triggers a post-payment reporting job
   - From: Delayed Job scheduler or `acctSvc_paymentAndInvoicing`
   - To: `continuumAccountingRedis` (Resque queue) or Delayed Job queue in `continuumAccountingMysql`
   - Protocol: Resque or Delayed Job

2. **Dequeues reporting job**: Resque worker or Delayed Job worker picks up the scheduled task
   - From: `continuumAccountingRedis` or `continuumAccountingMysql`
   - To: `acctSvc_reportingExports`
   - Protocol: Resque or Delayed Job

3. **Queries financial data**: Reporting job reads the relevant accounting records from `continuumAccountingMysql` — transactions, invoices, payments, and statements — scoped to the reporting period
   - From: `acctSvc_reportingExports`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

4. **Generates financial statements**: Job aggregates transaction data into period-level financial statements and writes statement records to `continuumAccountingMysql`
   - From: `acctSvc_reportingExports`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

5. **Performs reconciliation**: Job compares transaction totals, invoice amounts, and payment records against expected values; flags discrepancies for investigation
   - From: `acctSvc_reportingExports`
   - To: `continuumAccountingMysql`
   - Protocol: ActiveRecord / SQL

6. **Generates outbound export files**: Job produces structured export files (e.g., for NetSuite or file sharing) representing the reconciled financial data for the period
   - From: `acctSvc_reportingExports`
   - To: External file systems (File Transfer Service / File Sharing Service — stubs) or internal storage
   - Protocol: File transfer or REST (stub dependencies)

7. **Marks job complete**: Job updates its Delayed Job or Resque record as complete; logs output for audit purposes
   - From: `acctSvc_reportingExports`
   - To: `continuumAccountingMysql` or `continuumAccountingRedis`
   - Protocol: Delayed Job / Resque

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL read failure during reporting | Job fails; Delayed Job or Resque retries | Report not generated for period; retried until database recovers |
| Reconciliation discrepancy detected | Discrepancy flagged in report output or logged as an alert | Finance Operations team investigates flagged discrepancy; no automatic remediation |
| Export file write failure | Job fails; retry attempted | Export not delivered; Finance Operations must re-trigger after investigating root cause |
| Duplicate job execution | Distributed lock in `continuumAccountingRedis` prevents concurrent runs for the same period | Second job waits or is skipped; reports are not duplicated |
| Downstream stub unavailable (NetSuite, File Sharing) | Export step fails; job retries or moves to failed queue | Financial data remains in MySQL; external systems do not receive export until service recovers |

## Sequence Diagram

```
Delayed Job / Resque Scheduler -> continuumAccountingRedis: Enqueue reporting job
continuumAccountingRedis -> acctSvc_reportingExports: Dequeue job
acctSvc_reportingExports -> continuumAccountingMysql: Query transactions, invoices, payments (SQL)
continuumAccountingMysql --> acctSvc_reportingExports: Financial records
acctSvc_reportingExports -> continuumAccountingMysql: Write statement records (SQL)
acctSvc_reportingExports -> acctSvc_reportingExports: Perform reconciliation checks
acctSvc_reportingExports -> File Transfer / File Sharing (stub): Write export files
acctSvc_reportingExports -> continuumAccountingMysql / continuumAccountingRedis: Mark job complete
```

## Related

- Architecture dynamic view: not yet defined — see `components-continuum-accounting-service`
- Related flows: [Merchant Payment and Invoice Generation](merchant-payment-and-invoice-generation.md)
- See [Data Stores](../data-stores.md) for MySQL entity details (statements, transactions, payments)
- See [Integrations](../integrations.md) for NetSuite, File Transfer, and File Sharing stub details
- See [Runbook](../runbook.md) for troubleshooting failed reporting jobs

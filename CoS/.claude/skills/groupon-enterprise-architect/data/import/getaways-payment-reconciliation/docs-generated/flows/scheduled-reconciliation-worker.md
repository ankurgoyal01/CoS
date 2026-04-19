---
service: "getaways-payment-reconciliation"
title: "Scheduled Reconciliation Worker"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-reconciliation-worker"
flow_type: scheduled
trigger: "Periodic timer (reconciliationWorkerPeriod interval)"
participants:
  - "reconciliationWorker"
  - "invoicePaymentsService"
  - "getawaysPaymentReconciliation_notificationService"
  - "jdbiDaos"
  - "continuumGetawaysPaymentReconciliationDb"
architecture_ref: "components-getaways-payment-reconciliation-components"
---

# Scheduled Reconciliation Worker

## Summary

This scheduled flow performs automated periodic reconciliation of all pending merchant invoices. The Reconciliation Worker runs on a configurable timer (`reconciliationWorkerPeriod`) and processes pending invoices: it reads invoice and reservation data from MySQL via JDBI DAOs, delegates total validation to the Invoice Payments Service, writes back reconciliation results, and concludes each run by sending a status notification to the operations team via the Notification Service (SMTP).

## Trigger

- **Type**: schedule
- **Source**: `reconciliationWorker` Java component; fires after `reconciliationWorkerInitialDelay` and then every `reconciliationWorkerPeriod` seconds
- **Frequency**: Periodic; configured in JTier YAML (`reconciliationWorkerIsActive` must be `true`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Reconciliation Worker | Orchestrates the reconciliation pass | `reconciliationWorker` |
| Invoice Payments Service | Validates invoice totals against reservation data | `invoicePaymentsService` |
| Notification Service | Sends SMTP notification on run completion | `getawaysPaymentReconciliation_notificationService` |
| JDBI DAOs | Reads and writes all reconciliation data | `jdbiDaos` |
| Getaways Payment Reconciliation DB | Persistent store | `continuumGetawaysPaymentReconciliationDb` |

## Steps

1. **Timer fires**: `reconciliationWorker` wakes on the configured schedule and checks that `reconciliationWorkerIsActive=true`.
   - From: JVM scheduler
   - To: `reconciliationWorker`
   - Protocol: direct

2. **Read pending invoices**: `reconciliationWorker` calls `jdbiDaos` to retrieve all merchant invoices in a pending reconciliation state.
   - From: `reconciliationWorker`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

3. **Validate totals**: For each pending invoice, `reconciliationWorker` invokes `invoicePaymentsService` to check that the invoice total matches the sum of associated reservation amounts.
   - From: `reconciliationWorker`
   - To: `invoicePaymentsService`
   - Protocol: direct

4. **Read reservation data**: `invoicePaymentsService` reads reservation records from `jdbiDaos` to perform the total computation.
   - From: `invoicePaymentsService`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

5. **Write reconciliation results**: `reconciliationWorker` calls `jdbiDaos` to update the reconciliation status of each processed invoice (reconciled, discrepancy, etc.).
   - From: `reconciliationWorker`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

6. **Send notification**: `reconciliationWorker` calls `getawaysPaymentReconciliation_notificationService` to dispatch an SMTP notification summarising the run results.
   - From: `reconciliationWorker`
   - To: `getawaysPaymentReconciliation_notificationService`
   - Protocol: direct

7. **Dispatch email**: `notificationService` sends the notification via the Groupon SMTP server.
   - From: `getawaysPaymentReconciliation_notificationService`
   - To: Groupon SMTP Server (`grouponSmtpServer_unk_2f8c`)
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `reconciliationWorkerIsActive=false` | Worker skips execution | No reconciliation; no notification |
| DB read failure | Exception logged; worker run aborts | Partial or no reconciliation; next run retries |
| Validation exception for a single invoice | Error logged; worker continues with remaining invoices | Failed invoice remains in pending state |
| SMTP notification failure | Exception logged; worker run still completes | Notification not delivered; reconciliation results still written to DB |

## Sequence Diagram

```
Scheduler -> reconciliationWorker: timer fires
reconciliationWorker -> jdbiDaos: read pending invoices
jdbiDaos -> MySQL: SELECT merchant_invoices WHERE status = pending
MySQL --> jdbiDaos: invoice list
jdbiDaos --> reconciliationWorker: invoices
reconciliationWorker -> invoicePaymentsService: validate totals (per invoice)
invoicePaymentsService -> jdbiDaos: read reservations for invoice
jdbiDaos -> MySQL: SELECT reservations
MySQL --> jdbiDaos: reservations
jdbiDaos --> invoicePaymentsService: reservation data
invoicePaymentsService --> reconciliationWorker: validation result
reconciliationWorker -> jdbiDaos: write reconciliation status
jdbiDaos -> MySQL: UPDATE invoice status
MySQL --> jdbiDaos: OK
reconciliationWorker -> notificationService: send reconciliation notification
notificationService -> GrouponSMTPServer: SMTP send
```

## Related

- Architecture dynamic view: `components-getaways-payment-reconciliation-components`
- Related flows: [EAN Invoice Email Import](ean-invoice-email-import.md), [Invoice Reconciliation and Payment](invoice-reconciliation-and-payment.md)

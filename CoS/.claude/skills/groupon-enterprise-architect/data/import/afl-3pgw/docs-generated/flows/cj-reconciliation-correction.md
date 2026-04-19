---
service: "afl-3pgw"
title: "CJ Reconciliation and Correction Submission"
generated: "2026-03-03"
type: flow
flow_name: "cj-reconciliation-correction"
flow_type: scheduled
trigger: "Quartz scheduler — daily jobs (ReconciliationJob, CjSubmitNewOrdersJob, CjCorrectionSubmissionJob)"
participants:
  - "continuumAfl3pgwService"
  - "continuumAfl3pgwDatabase"
  - "cjAffiliate"
architecture_ref: "dynamic-rta-order-registration-flow"
---

# CJ Reconciliation and Correction Submission

## Summary

AFL-3PGW runs a set of Quartz-scheduled jobs that reconcile Groupon's internal order records against what was previously submitted to Commission Junction. The reconciliation process identifies four types of discrepancies — new sales missed in real time, refunds, cancellations, and chargebacks — and creates correction records in the database. Separate submission jobs then forward these corrections to CJ in batches. The Optimus Prime data import is a prerequisite step that populates the raw attribution and cancellation data before reconciliation can run.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler configured in the service YAML under the `quartz` block; jobs are persisted in MySQL for clustered execution
- **Frequency**: Daily (configured per-job in deployment YAML)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFL 3PGW Service (Job Orchestration) | Executes all Quartz jobs | `continuumAfl3pgwService` (`jobOrchestrationComponent`) |
| AFL 3PGW MySQL | Holds attribution data, correction records, job checkpoints | `continuumAfl3pgwDatabase` |
| Commission Junction | Receives correction submission payloads | `cjAffiliate` |
| Optimus Prime (external) | Prerequisite: imports MA attribution and cancellation data into AFL-3PGW DB | External Optimus jobs |

## Steps

1. **Optimus import (prerequisite)**: External Optimus Prime jobs import raw data into the AFL-3PGW MySQL database:
   - `AFL-3PGW-IMPORT-MA-ATTRIBUTIONS-ORDERS` — imports MA attribution v2 records into `ma_attribution_v2`
   - `AFL-3PGW-IMPORT-CJ-COMMISSIONS` — imports CJ commission data
   - `AFL-3PGW-IMPORT-MA-CANCELLED-ORDERS` — imports cancellation data into `cj_cancellation`
   - From: Optimus Prime
   - To: `continuumAfl3pgwDatabase`
   - Protocol: direct DB insert

2. **Reconciliation job runs**: `ReconciliationJob` (`jobOrchestrationComponent`) reads from `ma_attribution_v2`, `cj_cancellation`, and the submitted orders audit tables to compute four correction types:
   - `new_sale` — orders attributed to CJ but not yet submitted in real time
   - `refund` — merchant-initiated repayments to customers
   - `cancelled` — cancelled orders
   - `chargeback` — bank-initiated transaction reversals
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase` (reads and writes to `order_correction` / `correction_submission`)
   - Protocol: JDBC/MySQL

3. **New-sale correction submission**: `CjSubmitNewOrdersJob` reads new-sale corrections from the database from the last checkpoint, builds CJ submission payloads, and calls the CJ S2S API.
   - From: `continuumAfl3pgwService`
   - To: `cjAffiliate` (CJ S2S endpoint)
   - Protocol: REST/HTTP (Retrofit `cjClient`)
   - Updates: job checkpoint in `jobs` table after each batch

4. **Correction (declined) submission**: `CjCorrectionSubmissionJob` reads refund/cancellation/chargeback corrections from the database from the last checkpoint and submits them to CJ.
   - From: `continuumAfl3pgwService`
   - To: `cjAffiliate`
   - Protocol: REST/HTTP (Retrofit `cjClient` or `cjRestatementClient` for restatement-type corrections)
   - Updates: job checkpoint in `jobs` table after each batch

5. **Persist submission outcomes**: After each batch submission, `persistenceComponent` updates correction records as submitted and records the new checkpoint in the `jobs` table.
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Optimus import job fails | Optimus alert fires (`AFL-3PGW-IMPORT-MA-ATTRIBUTIONS-ORDERS` severity-3); must be fixed within 3 days | Reconciliation has stale/missing input data; retrigger Optimus job manually |
| ReconciliationJob fails | Reconciliation discrepancy alert may fire after 2 consecutive days; ELK logs contain the exception | Investigate CorrectionDao queries; corrections not created for that day |
| CjSubmitNewOrdersJob fails / does not run | `CjSubmitNewOrdersJob Not run in last 48 hrs` alert fires | Corrections accumulate in DB; next successful run will pick them up from the last checkpoint |
| CJ API returns error during submission | Failsafe retry applied; if all retries exhausted, exception is logged | Correction remains in DB at the last checkpoint; next job run retries from the checkpoint |
| CjCorrectionSubmissionJob fails | `CjCorrectionSubmission Job Not run in last 48 hrs` alert fires | Similar to above; corrections picked up on next run |

## Sequence Diagram

```
Quartz             -> ReconciliationJob:         Trigger reconciliation (daily)
ReconciliationJob  -> afl-3pgwDatabase:          READ ma_attribution_v2, cj_cancellation, audit tables
afl-3pgwDatabase   --> ReconciliationJob:         Attribution and cancellation records
ReconciliationJob  -> afl-3pgwDatabase:          WRITE order_correction records (new_sale, refund, cancelled, chargeback)
Quartz             -> CjSubmitNewOrdersJob:       Trigger new-sale submission (daily)
CjSubmitNewOrdersJob -> afl-3pgwDatabase:         READ new_sale corrections since checkpoint
afl-3pgwDatabase   --> CjSubmitNewOrdersJob:      New sale correction records
CjSubmitNewOrdersJob -> cjAffiliate:              POST/GET correction payload (CJ S2S / restatement API)
cjAffiliate        --> CjSubmitNewOrdersJob:      HTTP 200 / success response
CjSubmitNewOrdersJob -> afl-3pgwDatabase:         UPDATE checkpoint, mark corrections submitted
Quartz             -> CjCorrectionSubmissionJob:  Trigger declined-order submission (daily)
CjCorrectionSubmissionJob -> afl-3pgwDatabase:    READ refund/cancellation/chargeback corrections
afl-3pgwDatabase   --> CjCorrectionSubmissionJob: Correction records
CjCorrectionSubmissionJob -> cjAffiliate:         POST correction payload
cjAffiliate        --> CjCorrectionSubmissionJob: HTTP 200 / success response
CjCorrectionSubmissionJob -> afl-3pgwDatabase:    UPDATE checkpoint, mark corrections submitted
```

## Related

- Architecture dynamic view: `dynamic-rta-order-registration-flow`
- Related flows: [Real-Time Order Registration](rta-order-registration.md), [CJ Report and Commission Processing](cj-report-processing.md)

---
service: "afl-3pgw"
title: "Awin Transaction Processing"
generated: "2026-03-03"
type: flow
flow_name: "awin-transaction-processing"
flow_type: scheduled
trigger: "Quartz scheduler — Awin jobs (transaction reporting, approval workflows, verification)"
participants:
  - "continuumAfl3pgwService"
  - "continuumAfl3pgwDatabase"
  - "awinAffiliate"
architecture_ref: "components-afl3pgw-service"
---

# Awin Transaction Processing

## Summary

AFL-3PGW runs Quartz-scheduled jobs that manage the Awin affiliate network's transaction lifecycle beyond real-time submission. These jobs fetch network transaction reports, process pending transaction approvals, validate processed transactions, and submit corrections for cancelled or refunded orders. All Awin jobs use the `AwinClient` and `AwinConversionClient` Retrofit interfaces and operate against the service-owned MySQL database for state management. Each Awin job can be independently configured to run in `http` or `logging` mode via the `outputType` configuration.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler configured in the service YAML `quartz` block
- **Frequency**: Periodic (configured per-job in deployment YAML; specific cron expressions are in the service configuration files)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFL 3PGW Service (Job Orchestration) | Executes all Awin Quartz jobs | `continuumAfl3pgwService` (`jobOrchestrationComponent`) |
| AFL 3PGW MySQL | Holds Awin transaction state, cancellation records, report data | `continuumAfl3pgwDatabase` |
| Awin | Source and sink for Awin transaction and report data | `awinAffiliate` |

## Steps

### Awin Network Report Job

1. **Job triggers**: Quartz fires the Awin network report job on its configured schedule.
   - From: Quartz
   - To: `continuumAfl3pgwService` (`jobOrchestrationComponent`)

2. **Fetch network report**: The job calls `AwinClient` to retrieve the network report for the configured date range (advertiser IDs are looked up from `AwinConfiguration.advertiserIds`).
   - From: `continuumAfl3pgwService` (`affiliateNetworkGatewayComponent`)
   - To: `awinAffiliate`
   - Protocol: REST/HTTP (Retrofit `awinClient`)

3. **Persist report data**: Network report line items are written to the relevant report tables in MySQL.
   - From: `continuumAfl3pgwService` (`persistenceComponent`)
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

### Awin Transaction Approval Job

4. **Job triggers**: Quartz fires the Awin transaction approval job.

5. **Fetch pending transactions**: The job calls `AwinClient` to retrieve transactions in pending/unvalidated state from Awin.
   - From: `continuumAfl3pgwService`
   - To: `awinAffiliate`
   - Protocol: REST/HTTP (Retrofit `awinClient`)

6. **Validate transactions**: The job evaluates each transaction against local state (e.g., checks `awin_cancellation` table for cancellations within the `saleThresholdPeriod`) and determines approval or rejection.
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

7. **Submit approval/rejection**: The job calls `AwinClient` to submit approval or correction decisions back to Awin.
   - From: `continuumAfl3pgwService` (`affiliateNetworkGatewayComponent`)
   - To: `awinAffiliate`
   - Protocol: REST/HTTP (Retrofit `awinClient`)

8. **Persist outcome**: Transaction processing results are written to the database.
   - From: `continuumAfl3pgwService`
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

### Awin Correction Submission Job

9. **Job triggers**: Quartz fires the Awin correction job.

10. **Read corrections**: The job reads Awin cancellation/correction records from `awin_cancellation` table based on region and `enabledCountries` filter.
    - From: `continuumAfl3pgwService`
    - To: `continuumAfl3pgwDatabase`
    - Protocol: JDBC/MySQL

11. **Submit corrections to Awin**: The job calls `AwinConversionClient` (or `AwinClient`) to submit corrections for cancelled/refunded orders.
    - From: `continuumAfl3pgwService`
    - To: `awinAffiliate`
    - Protocol: REST/HTTP (Retrofit `awinConversionClient`)

12. **Update correction status**: After submission, records are marked as processed in the database.
    - From: `continuumAfl3pgwService`
    - To: `continuumAfl3pgwDatabase`
    - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Awin API unavailable | Failsafe retry with configured retry policy | Job logs failure; retried on next scheduled run |
| Transaction validation discrepancy | Logged as `AwinException`; problematic transactions skipped | Unvalidated transactions remain; next run reattempts |
| Awin correction submission failure | Exception logged; record remains in `awin_cancellation` as unprocessed | Next job run picks up unprocessed records |
| `outputType: logging` mode enabled | All Awin calls replaced by log-only adapter (`AwinLoggingAdapter`) | No live submissions made; dry-run mode for testing |

## Sequence Diagram

```
Quartz               -> AwinNetworkReportJob:    Trigger (scheduled)
AwinNetworkReportJob -> awinAffiliate:            GET network report (advertiser IDs from config)
awinAffiliate        --> AwinNetworkReportJob:    NetworkReport response
AwinNetworkReportJob -> afl-3pgwDatabase:         INSERT report data
Quartz               -> AwinApprovalJob:          Trigger (scheduled)
AwinApprovalJob      -> awinAffiliate:            GET pending transactions
awinAffiliate        --> AwinApprovalJob:          Pending transaction list
AwinApprovalJob      -> afl-3pgwDatabase:         READ awin_cancellation / local validation state
AwinApprovalJob      -> awinAffiliate:            POST approval / correction decisions
awinAffiliate        --> AwinApprovalJob:          Confirmation
AwinApprovalJob      -> afl-3pgwDatabase:         UPDATE processed transaction state
Quartz               -> AwinCorrectionJob:        Trigger (scheduled)
AwinCorrectionJob    -> afl-3pgwDatabase:         READ awin_cancellation corrections
AwinCorrectionJob    -> awinAffiliate:            POST correction payload (AwinConversionClient)
awinAffiliate        --> AwinCorrectionJob:        Confirmation
AwinCorrectionJob    -> afl-3pgwDatabase:         UPDATE correction status
```

## Related

- Related flows: [Real-Time Order Registration](rta-order-registration.md)
- Architecture component view: `components-afl3pgw-service`
- Awin integration configuration: `AwinConfiguration` — `token`, `advertiserIds`, `conversionBaseUrl`, `supportedBrands`, `enabledCountries`, `saleThresholdPeriod`, `outputType`

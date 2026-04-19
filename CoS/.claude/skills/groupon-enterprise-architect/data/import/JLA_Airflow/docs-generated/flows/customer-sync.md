---
service: "JLA_Airflow"
title: "Customer Sync Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "customer-sync"
flow_type: scheduled
trigger: "Daily cron at 13:00 UTC (`0 13 * * *`)"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "netsuite-integration-service"
  - "googleChat"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# Customer Sync Pipeline

## Summary

The Customer Sync pipeline (`jla-pipeline-customers`) runs daily to stage accounts receivable customer records from ads and voucher distribution partner data into the JLA data mart, then calls the JLA NetSuite integration service to create or update corresponding customer records in NetSuite ERP. The pipeline concludes with a final status report that validates record counts between Teradata staging and NetSuite, alerting engineering and stakeholders on the outcome and failing the DAG if any variance is detected.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron `"0 13 * * *"` (13:00 UTC daily)
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Schedules and runs the customer sync DAG | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes customer staging SQL against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores process UUID and process log state | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`) | Source (`user_gp.ads_billing_report`, `user_edwprod`) and target (`ACCT_JLA_CUSTOMER_STAGING`, `ACCT_JLA_CUSTOMER`) | `unknown_teradata_platform` (stub) |
| NetSuite Integration Service | Creates/updates AR customer records in NetSuite ERP | `unknown_netsuiteintegrationservice_700f4412` (stub) |
| Google Chat | Receives stakeholder and engineering alerts on completion | `googleChat` |

## Steps

1. **Start pipeline**: Marks DAG start with `start_pipeline_customers` empty operator.
   - From: Airflow scheduler (13:00 UTC)

2. **Generate process UUID**: Creates a UUID `process_id` and pushes to XCom.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

3. **Create process log**: Inserts process tracking record via `ProcessLog.create()` into `acct_jla_run_process`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

4. **Stage ads customers**: Executes `stage_ads_customers.sql` — reads from `user_gp` (ads schema) and stages records into `ACCT_JLA_CUSTOMER_STAGING`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

5. **Stage voucher distribution partners**: Executes `stage_voucher_distro_partners.sql` — stages voucher distribution partner customer records into `ACCT_JLA_CUSTOMER_STAGING`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

6. **Stage customers for NetSuite**: Executes `stage_customers_ns.sql` — finalises staging and writes into `ACCT_JLA_CUSTOMER` ready for NetSuite integration.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

7. **Invoke NetSuite integration service**: HTTP GET to `Groupon.JLA.Services.NetSuite/NetsuiteService.svc/ProcessCustomers/jla-pipeline-customers` (connection `http_jla_services_root`) — creates or updates AR customer records in NetSuite.
   - From: `continuumJlaAirflowOrchestrator`
   - To: NetSuite integration service
   - Protocol: HTTP GET

8. **Final status report**: Queries `acct_jla_customer_staging` to compare staged vs. NetSuite-processed counts. Sends summary to `STAKEHOLDER_ALERTS` Google Chat if records processed; sends detail alert to `ENGINEERING_ALERTS` if errors, variance, or historical records are outstanding.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd` (read), `googleChat` (webhook)
   - Protocol: JDBC/SQL, HTTPS Webhook

9. **Update process log**: Marks process as successful via `ProcessLog.success()`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No new customer data for > 7 days | Checks `alert_on_no_data_in_days` parameter; raises `AirflowFailException` | DAG fails with detailed error; source data staleness checked |
| Source data stale (`ads_billing_report`) | Checks `alert_source_lookback_days`; raises `AirflowFailException` if source stale | DAG fails with alert identifying stale source |
| NetSuite processes zero records | Detected in final status report (`count_netsuite = 0`) | `AirflowFailException` raised; engineering alert sent |
| Variance detected (`count_variance > 0`) | Final status report raises `AirflowFailException(ExceptionStates.HANDLED)` | DAG fails; detailed Google Chat alert sent to `ENGINEERING_ALERTS`; no double-alert from failure callback |
| Any other task failure | `on_failure_callback` fires | Google Chat `ENGINEERING_ALERTS` alert |

## Sequence Diagram

```
Scheduler -> jla-pipeline-customers: trigger (0 13 * * * daily)
jla-pipeline-customers -> teradata (dwh_fsa_prd): stage_ads_customers.sql -> ACCT_JLA_CUSTOMER_STAGING
jla-pipeline-customers -> teradata (dwh_fsa_prd): stage_voucher_distro_partners.sql -> ACCT_JLA_CUSTOMER_STAGING
jla-pipeline-customers -> teradata (dwh_fsa_prd): stage_customers_ns.sql -> ACCT_JLA_CUSTOMER
jla-pipeline-customers -> NetSuite integration service: HTTP GET ProcessCustomers
NetSuite integration service --> teradata (dwh_fsa_prd): update customer records status
jla-pipeline-customers -> teradata (dwh_fsa_prd): final_status_report.sql (validate counts)
jla-pipeline-customers -> googleChat (STAKEHOLDER_ALERTS): summary (if records processed)
jla-pipeline-customers -> googleChat (ENGINEERING_ALERTS): detail (if variance or errors)
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [Ads Billing and Invoicing Pipeline](ads-billing-invoicing.md)

---
service: "JLA_Airflow"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for JLA Airflow.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [JLA ETL Pipeline (Daily Data Mart Load)](jla-etl-pipeline.md) | scheduled | Cron (`etl_schedule` Variable, default `30 9 * * *`) | Sequential 8-step ETL pipeline that loads and transforms JLA accounting data from Teradata into the JLA data mart and publishes the final dataset to BigQuery |
| [Ads Billing and Invoicing Pipeline](ads-billing-invoicing.md) | scheduled | Cron (`10 13 * * *`) | Daily ingestion of ads billing data into `ACCT_JLA_ADS_BILLING`, followed by AGGS aggregation and NetSuite invoice creation |
| [Customer Sync Pipeline](customer-sync.md) | scheduled | Cron (`0 13 * * *`) | Daily staging of accounts receivable customer records from ads and voucher data, followed by NetSuite customer creation/update |
| [EBA Rules Execution](eba-rules-execution.md) | scheduled | Cron (`eba_schedule` Variable) | Triggers the JLA Event Based Accounting service to process active rules, aggregate data, and stage journal entries for NetSuite |
| [DB Watchman — Database Monitoring](db-watchman.md) | scheduled | Cron (`15 1 * * *`) | Nightly harvest of Teradata database object metadata, DDL snapshots, index and stats history, and configurable alerting |
| [DB Gatekeeper — Governed SQL Execution](db-gatekeeper.md) | manual | Manual trigger with `script_list` config | On-demand execution of audited SQL scripts against FSA databases with naming validation, Jira ticket verification, and execution logging |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |
| Manual / On-demand | 1 |

## Cross-Service Flows

- **JLA ETL Pipeline** → BigQuery: The final step (8.1) publishes the JLA dataset to `bigQueryWarehouse`. See [JLA ETL Pipeline](jla-etl-pipeline.md).
- **Ads Billing and Invoicing** → NetSuite: The invoicing step calls the NetSuite integration service to create invoice objects. See [Ads Billing and Invoicing Pipeline](ads-billing-invoicing.md).
- **Customer Sync** → NetSuite: Calls the NetSuite integration service to create/update AR customer records. See [Customer Sync Pipeline](customer-sync.md).
- **EBA Rules Execution** → JLA EBA Service: Makes REST call to the JLA Event Based Accounting service. See [EBA Rules Execution](eba-rules-execution.md).

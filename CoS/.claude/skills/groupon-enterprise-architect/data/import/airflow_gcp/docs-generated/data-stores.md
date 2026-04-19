---
service: "airflow_gcp"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSfdcEtlWorkingStorageGcs"
    type: "gcs"
    purpose: "Temporary staging for intermediate CSV datasets during ETL runs"
  - id: "continuumTeradataEdwStub"
    type: "teradata"
    purpose: "Source of merchant, deal, and customer data for Salesforce sync"
  - id: "continuumHiveStub"
    type: "hive"
    purpose: "Source of analytics datasets for Salesforce sync"
---

# Data Stores

## Overview

The Airflow GCP service uses Google Cloud Storage as its primary working store for all intermediate ETL data. It does not own any relational database. Source data is read from Teradata EDW and Hive (both external, read-only from this service's perspective). Processed results and bulk update outcomes are also written back to GCS. Salesforce itself is the destination system — records updated there are not cached locally.

## Stores

### SFDC ETL Working Storage — GCS (`continuumSfdcEtlWorkingStorageGcs`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | `continuumSfdcEtlWorkingStorageGcs` |
| Purpose | Temporary staging area for intermediate CSV datasets, bulk update result files, JDBC artifacts, and secrets |
| Ownership | owned |
| Migrations path | Not applicable — object storage, no schema migrations |

#### Key Bucket Paths (Production)

| Bucket / Path | Purpose | Key Files |
|---------------|---------|-----------|
| `grpn-us-central1-airflow-sfdc-etl-production` | Production working bucket | All staging CSVs and result files |
| `grpn-us-central1-airflow-sfdc-etl-staging` | Staging working bucket | All staging CSVs and result files |
| `test-sfdc-etl-bucket` | Development working bucket | All staging CSVs and result files |
| `<bucket>/secrets/variable-secrets.json` | Runtime secret store | Airflow variable secrets loaded by `secrets_reloader_dag` |
| `<bucket>/bulk_upload_all_results.csv` | Bulk upload result log | Per-run Salesforce bulk job result output |
| `<bucket>/bulk_upload_failed_results.csv` | Failed record log | Records that failed the initial bulk upload attempt |

#### Access Patterns

- **Read**: DAG Helper reads staging CSVs using `row_generator_from_file_in_gcs`; reads secrets JSON via `smart_open`; reads JDBC artifact files for Hive connector
- **Write**: DAG Helper writes query result CSVs via `upload_rows_to_gcs_as_a_csv_file`; writes bulk update result files; Salesforce Hook writes CSV batches during bulk upload preparation
- **Indexes**: Not applicable — object storage

---

### Teradata Enterprise Data Warehouse (`continuumTeradataEdwStub`)

| Property | Value |
|----------|-------|
| Type | Teradata |
| Architecture ref | `continuumTeradataEdwStub` (stub — not in federated model) |
| Purpose | Source of merchant, deal, voucher, refund, and customer data for all Teradata-based DAGs |
| Ownership | external — read-only |
| Host | `teradata.groupondev.com` |
| User | `ab_SalesForceDC` |

#### Key Source Tables / Queries

| Query File | SF Object Updated | Key Fields |
|------------|-------------------|-----------|
| `sql/dwh_dag.sql` | `Account` | `Id`, `DWH_Merchant_ID__c` |
| `sql/rad_deal_score_dag.sql` (inline) | `Account` | `Id`, `RAD_Score__c` |
| `sql/high_refunder_dag.sql` | `Account` | `Id`, `High_Refunder__c` |
| `sql/aggregated_refunds_data_dag.sql` | `Opportunity` | `Id`, `Total_Deal_Units_Sold__c`, `Total_Refunds_Units__c`, `Current_Month_Units_Sold__c`, `Current_Month_Units_Refunded__c` |
| `sql/sf_deal_alerts_dag.sql` | `Deal_Alert__c` | `Opportunity__c`, `Alert_Type__c`, `Alert_Description__c`, `Alert_Priority__c`, and others |
| `sql/sf_supply_pyramid_dag.sql` | `Account` | `Id`, `TMC_Wave__c` |
| `sql/ogp_and_vouchers_sold_mtd_qtd_ytd_dag.sql` | `Opportunity` | MTD/QTD/YTD voucher metrics |
| `sql/ogp_and_vouchers_sold_last_year_dag.sql` | `Opportunity` | Last-year voucher metrics |
| `sql/last_voucher_sold_na_dag.sql` | `Account` | Last voucher sold date (NA) |
| `sql/last_voucher_sold_intl_dag.sql` | `Account` | Last voucher sold date (INTL) |
| `sql/customer_satisfaction_dag.sql` | Salesforce custom object | Customer satisfaction metrics |
| `sql/cs_contacts_per_unit_dag.sql` | Salesforce custom object | CS contacts per unit |
| `sql/intl_refunds_oppty_dag.sql` | `Opportunity` | International refund opportunity data |
| `sql/intl_refunds_multi_deal_dag.sql` | `Opportunity` | Multi-deal refund data |
| `sql/gp_repeatability_dag.sql` | Salesforce custom object | GP repeatability metrics |
| `sql/md_acc_prioritization_na_dag.sql` | `Account` | Merchant account prioritization (NA) |
| `sql/md_acc_prioritization_intl_dag.sql` | `Account` | Merchant account prioritization (INTL) |
| `sql/mindbody_booking_status_dag.sql` | Salesforce custom object | Mindbody booking status |
| `sql/da_consistent_refunders_dag.sql` | Salesforce custom object | Consistent refunder flags |
| `sql/da_longtail_refund_offenders_dag.sql` | Salesforce custom object | Longtail refund offender flags |
| `sql/da_uk_deal_investigations_dag.sql` | Salesforce custom object | UK deal investigation flags |
| `sql/da_redemption_offender_dag.sql` | Salesforce custom object | Redemption offender flags |
| `sql/low_engagement_mc_onboarding_dag.sql` | Salesforce custom object | Low engagement merchant onboarding |
| `sql/sf_five_nvr_fields_dag.sql` | Salesforce custom object | Five NVR fields |
| `sql/sf_is_giftable_deal_dag.sql` | Salesforce custom object | Giftable deal flag |
| `sql/gp_field_aggregated_dag.sql` | Salesforce custom object | GP field aggregation |

#### Access Patterns

- **Read**: All Teradata access is read-only via `teradatasql` library queries executed by `airflowGcp_teradataConnector`
- **Write**: None — Teradata is source-only for this service
- **Indexes**: Not visible from this service

---

### Hive Analytics Cluster (`continuumHiveStub`)

| Property | Value |
|----------|-------|
| Type | Hive (Cloudera) via JDBC |
| Architecture ref | `continuumHiveStub` (stub — not in federated model) |
| Purpose | Analytics datasets as source for selected DAGs |
| Ownership | external — read-only |
| Host | `analytics.data-comp.prod.gcp.groupondev.com:8443` |
| User | `svc_gcp_sfdc_etl` |
| Driver | `com.cloudera.hive.jdbc.HS2Driver` |
| SSL Truststore | `orchestrator/certificates/DigiCertGlobalRootG2.jks` |

#### Access Patterns

- **Read**: Hive SQL executed via JDBC (`jaydebeapi`); connection requires SSL with JKS truststore
- **Write**: None — Hive is source-only for this service
- **Indexes**: Not visible from this service

## Caches

> This service does not use any cache layer (Redis, Memcached, or in-memory). All state is stored in GCS or managed by Airflow's internal XCom mechanism.

## Data Flows

Data moves through the service in a unidirectional pipeline pattern:

1. Source data is read from Teradata EDW or Hive via SQL query.
2. Results are written as CSV files to GCS working storage under a unique run UUID prefix.
3. For delta DAGs: current Salesforce state is also extracted via SOQL and saved to GCS; then the two datasets are compared to produce a delta CSV.
4. The delta CSV (or full result CSV for append-only DAGs) is submitted to Salesforce Bulk API for batch update.
5. Bulk job results are retrieved and written back to GCS for audit (`bulk_upload_all_results.csv`, `bulk_upload_failed_results.csv`).
6. Failed records from the bulk job are re-submitted individually.
7. Temporary GCS staging files are deleted after each successful run.

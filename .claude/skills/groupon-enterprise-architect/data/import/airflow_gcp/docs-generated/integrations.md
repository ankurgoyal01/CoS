---
service: "airflow_gcp"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

The Airflow GCP SFDC ETL service integrates with four external systems: Salesforce (as the primary data destination), Teradata EDW and Hive (as data sources), and Google Secret Manager (for runtime credentials). It has no internal service dependencies within the Continuum platform beyond the Cloud Composer infrastructure it runs on. It is not consumed by any internal service — it is an outbound-only integrator.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS (Bulk API v1, REST SOQL) | Primary destination — bulk updates merchant and deal fields | yes | `salesForce` |
| Teradata EDW | JDBC (teradatasql) | Source of merchant, deal, voucher, refund, customer data | yes | `continuumTeradataEdwStub` |
| Hive Analytics Cluster | JDBC over SSL (jaydebeapi) | Source of analytics datasets for selected DAGs | yes | `continuumHiveStub` |
| Google Secret Manager | REST (Google Secret Manager API) | Retrieves TLS certificate secrets and runtime credentials | yes | `continuumGoogleSecretManagerStub` |
| Google Cloud Storage | GCS API (google-cloud-storage) | Working storage for intermediate CSVs, result files, and secrets blob | yes | `continuumSfdcEtlWorkingStorageGcs` |

### Salesforce Detail

- **Protocol**: HTTPS — Salesforce Bulk API v1 for batch inserts/updates; Salesforce REST API for SOQL queries
- **Base URL / SDK**: Production: `groupon.my.salesforce.com`; Dev/Staging: `groupon-dev.my.salesforce.com` — via `simple-salesforce` and `salesforce-bulk` libraries
- **Auth**: Username + password + security token stored as Airflow connection (`sf_prod_conn`, `sf_staging_conn`, `sf_dev_conn`); password resolved from Airflow Variable `sfdc_etl_sf_conn_password`
- **Purpose**: Receives bulk data updates for 28+ Salesforce objects including `Account`, `Opportunity`, `Deal_Alert__c`, and others; updates merchant and deal performance fields used by sales and account management
- **Failure mode**: DAG retries once (2-minute delay); failed records within a successful bulk job are re-submitted individually; email alert sent to `sfint-dev-alerts@groupon.com` on task failure
- **Circuit breaker**: None configured — relies on Airflow retry mechanism and Salesforce Bulk API job status polling

### Teradata EDW Detail

- **Protocol**: JDBC via `teradatasql` Python library
- **Base URL / SDK**: Host: `teradata.groupondev.com`; User: `ab_SalesForceDC`
- **Auth**: Username/password; password managed via Airflow Variables (retrieved from GCS secrets blob)
- **Purpose**: SQL-based extraction of merchant IDs, deal scores, refund metrics, voucher sales, customer satisfaction data, and other fields to be synced into Salesforce
- **Failure mode**: DAG task fails on query error; Airflow retries once after 2 minutes; email alert on failure
- **Circuit breaker**: None configured

### Hive Analytics Cluster Detail

- **Protocol**: JDBC over HTTPS/SSL via `jaydebeapi` using Cloudera Hive JDBC driver (`com.cloudera.hive.jdbc.HS2Driver`)
- **Base URL / SDK**: `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default`; HTTP path: `gateway/analytics-adhoc-query/hive`
- **Auth**: Username `svc_gcp_sfdc_etl` + password (stored as Airflow Variable `sfdc_etl_hive_password`); SSL with JKS truststore at `orchestrator/certificates/DigiCertGlobalRootG2.jks`
- **Purpose**: Extraction of analytics datasets (Hive tables) for DAGs that require Hive as data source rather than Teradata
- **Failure mode**: SSL certificate expiry causes Hive DAG failures; requires manual truststore update process (see [Runbook](runbook.md)); Airflow retries once; email alert on failure
- **Circuit breaker**: None configured

### Google Secret Manager Detail

- **Protocol**: REST via Google Secret Manager API (Python client)
- **Base URL / SDK**: Google Cloud Secret Manager; secret name: `tls--salesforce-sfdc-etl`
- **Auth**: GCP service account via Cloud Composer Workload Identity
- **Purpose**: Retrieves TLS certificate (`cert.pem`) and private key (`key.pem`) for mTLS connections; loaded by `secrets_reloader_dag` into GCS and Airflow Variables
- **Failure mode**: `secrets_reloader_dag` task fails; downstream DAGs that require the certificate may fail on next run
- **Circuit breaker**: None configured

### Google Cloud Storage Detail

- **Protocol**: GCS API via `google-cloud-storage` Python library and `smart-open`
- **Base URL / SDK**: Prod bucket: `grpn-us-central1-airflow-sfdc-etl-production`; Staging bucket: `grpn-us-central1-airflow-sfdc-etl-staging`; Dev bucket: `test-sfdc-etl-bucket`; GCP project IDs vary per environment
- **Auth**: `sfdc_etl_gcloud_connection` Airflow connection (GCP service account)
- **Purpose**: Temporary working storage for all inter-task data passing; audit trail of bulk upload results
- **Failure mode**: Task fails on GCS I/O error; Airflow retries once; email alert on failure
- **Circuit breaker**: None configured

## Internal Dependencies

> No evidence found. The Airflow GCP service has no runtime dependencies on other internal Continuum platform services beyond the Cloud Composer managed infrastructure.

## Consumed By

> Upstream consumers are tracked in the central architecture model. No internal Continuum services directly consume data from this service. Salesforce CRM is the end consumer of all data written by this service.

## Dependency Health

- All external dependencies are called synchronously within Airflow task functions with no circuit breaker pattern
- Salesforce Bulk API jobs are polled for completion status before the DAG proceeds to the results-saving task
- Failed Salesforce bulk records are automatically re-submitted once per run
- Teradata and Hive connections have no health check mechanism beyond task-level failure detection
- GCS connectivity is validated implicitly on first read/write operation per task

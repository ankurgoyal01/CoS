---
service: "JLA_Airflow"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 2
---

# Integrations

## Overview

JLA Airflow integrates with seven external systems and two internal FSA services. All outbound calls are initiated by DAG tasks; there are no inbound integrations (no consumers call JLA Airflow directly). The primary integration patterns are: SQL over JDBC to Teradata, HTTP REST calls to JLA internal services and SnapLogic, SFTP for Kyriba file ingestion and AWS SFTP file migration, and Google Chat webhooks for alerting.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Teradata (`dwh_fsa_prd`) | JDBC/SQL | JLA data mart ETL source and target | yes | `unknown_teradata_platform` (stub) |
| BigQuery | SQL | Analytics dataset reads and publication | yes | `bigQueryWarehouse` |
| Kyriba | SFTP | Downloads payment clearing files (`GROUPON.NC4.REPORT.*.PAYMENTS*`) | yes | `kyriba` |
| Google Chat | Webhook (HTTP) | Sends DAG failure alerts and operational summaries | no | `googleChat` |
| Jira API | REST | Validates ticket references in DB Gatekeeper script filenames | no | No architecture ref |
| SnapLogic | REST (HTTP) | Triggers Salesforce contract PDF to NetSuite file cabinet pipeline | no | No architecture ref |
| AWS SFTP | SFTP | File migration (SFTP Mover DAG) | no | `unknown_awssftp_platform` (stub) |

### Teradata Detail

- **Protocol**: JDBC via SQLAlchemy (`teradatasql://`)
- **Connection ID**: `teradata` (Airflow connection)
- **Port**: 1025
- **Auth**: Username/password stored in Airflow connection
- **Purpose**: Primary ETL source and target for all JLA mart tables; also used by DB Gatekeeper DDL execution and DB Watchman metadata harvesting
- **Failure mode**: DAG task fails; `on_failure_callback` sends Google Chat alert
- **Circuit breaker**: No evidence found

### BigQuery Detail

- **Protocol**: SQL via `BigQueryEngine` (SQLAlchemy `bigquery://`)
- **Connection ID**: `bigquery_default` (Airflow connection)
- **Auth**: GCP service account keyfile (from Airflow connection `extra.keyfile_dict`)
- **Purpose**: Analytics dataset reads (some ETL DAGs) and JLA dataset publication (step 8.1)
- **Failure mode**: DAG task fails; `on_failure_callback` sends Google Chat alert
- **Circuit breaker**: No evidence found

### Kyriba Detail

- **Protocol**: SFTP (`paramiko`)
- **Connection ID**: `kyriba_sftp` (Airflow connection)
- **Remote path**: `/out/`
- **File mask**: `GROUPON.NC4.REPORT.*.PAYMENTS*`
- **Auth**: SFTP credentials in Airflow connection
- **Purpose**: Downloads payment clearing files daily; files are processed into Teradata and archived in GCS
- **Failure mode**: DAG task fails; `on_failure_callback` sends Google Chat alert
- **Circuit breaker**: No evidence found

### Google Chat Detail

- **Protocol**: HTTPS Webhook
- **Connection ID**: `gchat_spaces` (Airflow connection)
- **Variables**: `GChatSpaces.ENGINEERING_ALERTS`, `GChatSpaces.JLA_ALERTS`, `GChatSpaces.STAKEHOLDER_ALERTS` (Airflow Variables)
- **Purpose**: Sends DAG failure notifications, EBA run summaries, customer sync summaries, and DB Watchman alerts
- **Failure mode**: Alert silently fails; does not affect DAG run state
- **Circuit breaker**: No

### Jira API Detail

- **Protocol**: REST (HTTP Basic Auth)
- **Connection ID**: `jira_api` (Airflow connection)
- **Endpoint prefix**: `/rest/api/2/issue/`
- **Purpose**: DB Gatekeeper validates that each SQL script filename contains a valid Jira ticket number before executing
- **Failure mode**: Pre-validation step fails; DAG aborts before executing any SQL
- **Circuit breaker**: No

### SnapLogic Detail

- **Protocol**: REST (HTTP GET)
- **Connection ID**: `http_snaplogic_sftons` (Airflow connection)
- **Purpose**: Triggers SnapLogic pipeline that fetches Salesforce contract PDFs and uploads them to the NetSuite file cabinet for attachment to merchant invoices (Ads Billing DAG)
- **Failure mode**: DAG task fails; pipeline continues if task is non-critical
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| JLA EBA Service | REST (HTTP GET) | Triggers EBA rules processing (`EventBasedAccountingService.svc/ProcessRules/airflow`) | `unknown_netsuiteintegrationservice_700f4412` (stub) |
| JLA NetSuite Integration Service | REST (HTTP GET) | Triggers NetSuite customer and invoice creation (`NetsuiteService.svc/ProcessCustomers/...`) | `unknown_netsuiteintegrationservice_700f4412` (stub) |

### JLA EBA Service Detail

- **Protocol**: HTTP GET
- **Connection ID**: `http_jla_services_root` (Airflow connection)
- **Endpoint pattern**: `Groupon.JLA.Services.EventBasedAccounting/EventBasedAccountingService.svc/ProcessRules/airflow/{start_date}/{end_date}/{process_id}`
- **Purpose**: Executes all active EBA accounting rules against JLA mart data and stages journal entries for NetSuite
- **Failure mode**: DAG task fails; `on_failure_callback` sends Google Chat alert

### JLA NetSuite Integration Service Detail

- **Protocol**: HTTP GET
- **Connection ID**: `http_jla_services_root` (Airflow connection)
- **Endpoints used**:
  - `Groupon.JLA.Services.NetSuite/NetsuiteService.svc/ProcessCustomers/jla-pipeline-customers`
- **Purpose**: Creates and updates accounts receivable customer records and invoices in NetSuite
- **Failure mode**: Final status report DAG task detects variance and raises `AirflowFailException`

## Consumed By

Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All DAG tasks use `on_failure_callback = ErrorUtils.failure_callback` which fires a Google Chat alert to the `ENGINEERING_ALERTS` space on any task failure.
- No circuit breaker or retry patterns are configured (DAGs use `retries: 0`).
- The `db_summoner` Airflow Variable can redirect Teradata connections to a sandbox environment for non-production use.

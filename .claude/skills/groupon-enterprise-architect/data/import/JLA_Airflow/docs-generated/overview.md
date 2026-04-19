---
service: "JLA_Airflow"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Financial Systems & Analytics — JLA Accounting"
platform: "Continuum"
team: "FSA Engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "3.x"
  framework: "Apache Airflow"
  framework_version: "2.x (Google Cloud Composer)"
  runtime: "Google Cloud Composer"
  runtime_version: "GCS Composer"
  build_tool: "Jenkins"
  package_manager: "pip"
---

# JLA Airflow Overview

## Purpose

JLA Airflow is the Financial Systems & Analytics (FSA) team's Apache Airflow deployment on Google Cloud Composer. It schedules and executes the full suite of accounting, reconciliation, and financial ETL DAGs for the JLA (Journal Ledger Accounting) domain. Pipelines cover the daily JLA data mart ETL chain, ads billing and invoicing, customer management, payment service provider (PSP) settlement ingestion, event-based accounting (EBA) rule execution, and NetSuite integration workflows.

## Scope

### In scope

- Daily JLA data mart ETL pipeline (startup through dataset publication, steps 1–8.1)
- Ads billing and invoicing pipeline including AGGS aggregation and NetSuite invoice creation
- Customer staging and NetSuite accounts receivable creation
- Payment service provider (PSP) settlement ingestion: Adyen, Amex, PayPal, Paymentech
- Kyriba payment clearing file ingestion via SFTP
- Event-based accounting (EBA) rule execution against the JLA service
- Journal entry mass reversal orchestration
- FSA database governance utilities (DB Gatekeeper, DB Watchman, DB Summoner)
- Operational DAGs: Airflow DB cleanup, PyPI version checks, global functionality tests
- Scheduled financial reports and month-end close reporting

### Out of scope

- JLA application logic and EBA rule definitions (owned by the JLA application service)
- NetSuite ERP business configuration (managed by the Accounting team)
- Teradata data warehouse schema ownership (managed by the data warehouse team)
- BigQuery dataset schema ownership (managed downstream)

## Domain Context

- **Business domain**: Financial Systems & Analytics — JLA Accounting
- **Platform**: Continuum
- **Upstream consumers**: Airflow Scheduler (cron triggers), FSA engineers triggering manual DAG runs
- **Downstream dependencies**: Teradata data warehouse (`dwh_fsa_prd`), BigQuery analytics warehouse, NetSuite integration service, JLA EBA service, Kyriba (SFTP), Google Chat webhooks, SnapLogic HTTP pipelines

## Stakeholders

| Role | Description |
|------|-------------|
| FSA Engineering | Owns and maintains all DAGs (`fsa-eng@groupon.com`) |
| Accounting Team | Primary consumers of JLA data mart outputs and NetSuite records |
| FSA Operations | Monitors DAG runs via Airflow UI and Google Chat alerts |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.x | `orchestrator/**/*.py` |
| Framework | Apache Airflow | 2.x | `from airflow import DAG` in all DAG files |
| Runtime | Google Cloud Composer | Composer-managed | `COMPOSER_DAGS_BUCKET` env var in `.deploy_bot.yml` |
| Build tool | Jenkins | — | `Jenkinsfile` |
| Package manager | pip | — | `requirements-lint.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `apache-airflow` | 2.x | scheduling | DAG scheduling, task execution, XCom, TriggerDagRunOperator |
| `teradatasql` | — | db-client | SQLAlchemy connection to Teradata data warehouse via JDBC |
| `sqlalchemy` | — | orm | Database engine abstraction for Teradata and BigQuery |
| `pandas` | — | data-processing | DataFrame-based result processing, SCD-type delta logic in DB Watchman |
| `jinja2` | — | templating | SQL template rendering inside DAG tasks (EBA, Customers, Kyriba) |
| `paramiko` | — | sftp | SFTP access for Kyriba file ingestion |
| `requests` | — | http-client | HTTP calls to JLA EBA service, NetSuite integration service, Jira API |
| `sqlparse` | — | sql-parsing | Splitting and parsing multi-statement SQL scripts in DB Gatekeeper |
| `flake8` | >=6.0.0 | linting | Code quality enforcement |
| `pandas-vet` | >=0.2.3 | linting | Pandas anti-pattern detection |
| `airflow.providers.http` | — | http-framework | `SimpleHttpOperator` for REST service calls |
| `airflow.providers.ssh` | — | integration | SSH/SFTP file transfers for PSP and SFTP Mover DAGs |

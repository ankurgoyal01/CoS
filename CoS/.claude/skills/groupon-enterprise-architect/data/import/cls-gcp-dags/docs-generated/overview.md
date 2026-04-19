---
service: "cls-gcp-dags"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data, Analytics & Reporting"
platform: "Continuum"
team: "CLS (Customer Lifecycle Science)"
status: active
tech_stack:
  language: "Python"
  language_version: ""
  framework: "Apache Airflow"
  framework_version: ""
  runtime: "Google Cloud Composer"
  runtime_version: ""
  build_tool: ""
  package_manager: ""
---

# CLS GCP DAGs Overview

## Purpose

CLS GCP DAGs defines and orchestrates Cloud Scheduler-triggered Apache Airflow DAGs for CLS data ingestion and transformation pipelines on Google Cloud Platform. The service encapsulates the full pipeline lifecycle — from scheduled trigger events through data validation to curated load — enabling the Customer Lifecycle Science team to maintain reliable, repeatable data workflows. It provides a structured orchestration layer that enforces data quality gates before any downstream storage targets are written.

## Scope

### In scope

- Defining Airflow DAG structures for CLS data pipelines on GCP Cloud Composer
- Accepting Cloud Scheduler-triggered events that initiate CLS DAG execution windows
- Coordinating task dependencies and runtime branching logic for CLS DAG runs
- Validating source data completeness and schema expectations before loading
- Loading validated outputs into curated downstream storage targets
- Managing the sequential flow from schedule trigger through validation to load

### Out of scope

- Defining or managing the underlying Google Cloud Composer environment infrastructure
- Operating source systems that produce the raw data consumed by DAGs
- Providing a REST or RPC API surface for external consumers
- Real-time or event-driven data processing (batch/scheduled only)
- Analytics query serving or reporting UI

## Domain Context

- **Business domain**: Data, Analytics & Reporting
- **Platform**: Continuum
- **Upstream consumers**: Google Cloud Scheduler (schedule-based trigger); upstream consumers of orchestration output are tracked in the central architecture model
- **Downstream dependencies**: Curated downstream storage targets (e.g., BigQuery or equivalent GCP data store) written to by the Curated Load Task

## Stakeholders

| Role | Description |
|------|-------------|
| CLS Data Engineering | Owns DAG definitions, pipeline logic, and validation rules |
| CLS Analytics / Science | Relies on curated data outputs for analytics and ML model inputs |
| Data Platform / Cloud Composer Admins | Manages the underlying Airflow/Composer environment on GCP |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | Not specified | architecture DSL: `Python, Apache Airflow DAGs` |
| Framework | Apache Airflow | Not specified | architecture DSL: `continuumClsGcpDags` container description |
| Runtime | Google Cloud Composer | Not specified | architecture DSL: container tag `DataPipeline`; service name `cls-gcp-dags` |
| Build tool | No evidence found in codebase. | | |
| Package manager | No evidence found in codebase. | | |

### Key Libraries

> No evidence found in codebase. The import-repos directory contains only architecture DSL files; no Python source files (requirements.txt, setup.py, pyproject.toml) were available for analysis. The DSL confirms Apache Airflow operators are used: Python validation operators, Python load operators, and Airflow scheduler integration.

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache-airflow | Not specified | scheduling | DAG definition, task orchestration, and scheduler integration |
| Airflow Python operators | Not specified | scheduling | Custom Python validation and load task operators |

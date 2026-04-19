---
service: "megatron-gcp"
title: "megatron-gcp Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumMegatronGcp"]
tech_stack:
  language: "Python 3.8"
  framework: "Apache Airflow 2.10.5"
  runtime: "Docker / GCP Cloud Composer"
---

# Megatron GCP Documentation

Megatron GCP is an Apache Airflow-based orchestration service that generates and runs data ingestion DAGs to migrate MySQL and PostgreSQL on-premises data to Google Cloud (BigQuery and Teradata), with full validation, audit, and data-quality coverage.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Python 3.8 |
| Framework | Apache Airflow 2.10.5 |
| Runtime | Docker / GCP Cloud Composer |
| Build tool | Jenkins (dataPipeline DSL) |
| Platform | GCP (us-central1) |
| Domain | Data Ingestion / ETL |
| Team | DnD Ingestion (dnd-ingestion-ops) |

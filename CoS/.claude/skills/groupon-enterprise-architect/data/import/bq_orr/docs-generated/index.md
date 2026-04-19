---
service: "bq_orr"
title: "BigQuery Orchestration Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBigQueryOrchestration"]
tech_stack:
  language: "Python 3"
  framework: "Apache Airflow"
  runtime: "Google Cloud Composer"
---

# BigQuery Orchestration Service Documentation

Repository-managed Apache Airflow DAG package that deploys and executes data warehouse workloads against Google BigQuery through shared Google Cloud Composer environments.

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
| Language | Python 3 |
| Framework | Apache Airflow |
| Runtime | Google Cloud Composer |
| Build tool | Jenkins (dataPipeline shared library) |
| Platform | Continuum / GCP Data Platform |
| Domain | Data Engineering / Data Warehouse |
| Team | EDW Admin (edw-admin@groupon.com) |

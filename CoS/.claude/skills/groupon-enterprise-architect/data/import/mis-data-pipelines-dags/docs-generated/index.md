---
service: "mis-data-pipelines-dags"
title: "MIS Data Pipelines DAGs Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumMisDataPipelinesDags"]
tech_stack:
  language: "Python"
  framework: "Apache Airflow"
  runtime: "GCP Cloud Composer"
---

# MIS Data Pipelines DAGs Documentation

Airflow DAG repository orchestrating MIS archival, deal performance, Janus streaming, backfill, and cluster lifecycle jobs in GCP.

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
| Language | Python |
| Framework | Apache Airflow (Cloud Composer) |
| Runtime | GCP Cloud Composer |
| Build tool | Jenkins (dataPipeline shared library) |
| Platform | GCP (us-central1) |
| Domain | Marketing Intelligence / Data Engineering |
| Team | MIS Engineering |

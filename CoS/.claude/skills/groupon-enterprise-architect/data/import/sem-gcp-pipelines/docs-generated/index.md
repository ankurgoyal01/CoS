---
service: "sem-gcp-pipelines"
title: "sem-gcp-pipelines Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSemGcpPipelinesComposer"
  containers: ["continuumSemGcpPipelinesComposer"]
tech_stack:
  language: "Python 3"
  framework: "Apache Airflow"
  runtime: "GCP Composer / Dataproc"
---

# sem-gcp-pipelines Documentation

Airflow DAG collection that orchestrates SEM and Display Marketing data pipelines, ad-platform feed generation, and conversion reporting jobs on Google Cloud Platform.

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
| Framework | Apache Airflow (GCP Composer) |
| Runtime | GCP Composer / Dataproc (image 1.5-debian10) |
| Build tool | Jenkins (dataPipeline DSL) |
| Platform | GCP (us-central1) |
| Domain | Search & Display Marketing (SEM / DM) |
| Team | SEM Engineering (sem-devs@groupon.com) |

---
service: "cas-data-pipeline-dags"
title: "cas-data-pipeline-dags Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumCasDataPipelineDags", "continuumCasSparkBatchJobs"]
tech_stack:
  language: "Python 3 / Scala 2.12"
  framework: "Apache Airflow / Apache Spark 2.4.8"
  runtime: "GCP Cloud Composer / GCP Dataproc"
---

# CAS Data Pipeline DAGs Documentation

Airflow DAG definitions and Scala Spark batch jobs that orchestrate the Consumer Arbitration System (CAS) machine-learning, ranking, upload, and reporting pipelines for both NA and EMEA regions on GCP Cloud Composer and Dataproc.

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
| Language | Python 3 / Scala 2.12 |
| Framework | Apache Airflow / Apache Spark 2.4.8 |
| Runtime | GCP Cloud Composer / GCP Dataproc |
| Build tool | sbt (Scala), Fabric (Python deploy) |
| Platform | Continuum (GCP) |
| Domain | Consumer Arbitration System — ML pipelines |
| Team | CAS (Consumer Arbitration System) |

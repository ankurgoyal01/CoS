---
service: "afgt"
title: "afgt Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAfgtAirflowDag, continuumAfgtDataprocBatch, continuumAfgtHiveDataset]
tech_stack:
  language: "Python 3"
  framework: "Apache Airflow"
  runtime: "Google Cloud Dataproc"
---

# AFGT Documentation

Daily batch data pipeline that extracts global financial transaction data from Teradata (EDW), enriches it across multiple staging steps, and loads a final analytics table into the IMA Hive data lake on GCS.

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
| Framework | Apache Airflow (DAG: `afgt_sb_td`) |
| Runtime | Google Cloud Dataproc (Pig/Hive/Shell/Sqoop) |
| Build tool | Jenkins (`java-pipeline-dsl`) |
| Platform | Continuum / GCP Data Engineering |
| Domain | Revenue Management Analytics (RMA) / Business Intelligence |
| Team | dnd-bia-data-engineering (owner: rev_mgmt_analytics) |

---
service: "pre_task_tracker"
title: "pre_task_tracker Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumPreTaskTracker"
  containers: ["continuumPreTaskTracker", "continuumPreTaskTrackerAirflowDb", "continuumPreTaskTrackerMysqlDb"]
tech_stack:
  language: "Python 3"
  framework: "Apache Airflow"
  runtime: "Google Cloud Composer"
---

# pre_task_tracker Documentation

Apache Airflow DAG package that monitors Megatron data pipeline delays and failures, tracks Dataproc cluster health, manages SLA records, and automates runbook creation across Groupon's data engineering platforms.

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
| Build tool | Jenkins (dataPipeline DSL) |
| Platform | Google Cloud Platform |
| Domain | Platform Reliability Engineering (PRE) |
| Team | Platform Reliability Engineering |

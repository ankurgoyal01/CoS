---
service: "JLA_Airflow"
title: "JLA Airflow Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumJlaAirflow"
  containers: ["continuumJlaAirflowOrchestrator", "continuumJlaAirflowMetadataDb"]
tech_stack:
  language: "Python"
  framework: "Apache Airflow"
  runtime: "Google Cloud Composer"
---

# JLA Airflow Documentation

Airflow-based orchestration platform owned by the Financial Systems & Analytics (FSA) team, scheduling and executing accounting, reconciliation, and financial data pipeline DAGs for the JLA (Journal Ledger Accounting) domain.

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
| Framework | Apache Airflow |
| Runtime | Google Cloud Composer (GCS) |
| Build tool | Jenkins (`Jenkinsfile`) |
| Platform | Continuum / FSA |
| Domain | Financial Systems & Analytics — JLA Accounting |
| Team | FSA Engineering (`fsa-eng@groupon.com`) |

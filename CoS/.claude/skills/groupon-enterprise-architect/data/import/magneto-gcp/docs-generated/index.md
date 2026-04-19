---
service: "magneto-gcp"
title: "magneto-gcp Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMagnetoDagGenerator, continuumMagnetoOrchestrator, continuumMagnetoConfigStorage]
tech_stack:
  language: "Python 3.8"
  framework: "Apache Airflow 2.10.5"
  runtime: "Docker / Kubernetes (GCP)"
---

# magneto-gcp Documentation

Salesforce Data Ingestion Automation framework that generates and runs Apache Airflow DAGs to incrementally extract Salesforce objects and load them into Hive tables on Google Cloud Dataproc.

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
| Runtime | Docker on Kubernetes (GCP) |
| Build tool | Docker / Jenkins |
| Platform | Continuum (GCP Data Platform) |
| Domain | Data Ingestion — Salesforce to Hive |
| Team | dnd-ingestion |

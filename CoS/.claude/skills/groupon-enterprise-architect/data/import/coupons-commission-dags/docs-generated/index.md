---
service: "coupons-commission-dags"
title: "coupons-commission-dags Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCouponsCommissionDags"]
tech_stack:
  language: "Python"
  framework: "Apache Airflow"
  runtime: "GCP Cloud Composer"
---

# Coupons Commission DAGs Documentation

Airflow DAGs that orchestrate coupons commission reporting data pipelines in GCP, executing Spark jobs on ephemeral Dataproc clusters.

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
| Framework | Apache Airflow (GCP Cloud Composer) |
| Runtime | GCP Cloud Composer |
| Build tool | Jenkins (Jenkinsfile / `dataPipeline` shared library) |
| Platform | Continuum |
| Domain | Coupons / Finance / Affiliate Commission Reporting |
| Team | mis-deployment (Slack channel) |

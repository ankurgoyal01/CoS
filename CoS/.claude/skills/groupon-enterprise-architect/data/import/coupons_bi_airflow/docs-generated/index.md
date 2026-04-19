---
service: "coupons_bi_airflow"
title: "coupons_bi_airflow Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumCouponsBiAirflow"
  containers: [continuumCouponsBiAirflowDags]
tech_stack:
  language: "Python 3.x"
  framework: "Apache Airflow"
  runtime: "GCP Cloud Composer"
---

# Coupons BI Airflow Documentation

Orchestrates Groupon Coupons business intelligence data pipelines via Apache Airflow on GCP Cloud Composer, ingesting data from marketing and analytics APIs into Teradata and BigQuery.

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
| Language | Python 3.x |
| Framework | Apache Airflow |
| Runtime | GCP Cloud Composer |
| Build tool | pip / requirements.txt |
| Platform | GCP (Cloud Composer, BigQuery, GCS) |
| Domain | Data Engineering / Business Intelligence |
| Team | Coupons BI |

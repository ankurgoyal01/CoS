---
service: "seo-deal-redirect"
title: "seo-deal-redirect Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumSeoDealRedirectDag", "continuumSeoDealRedirectJobs", "continuumSeoHiveWarehouse"]
tech_stack:
  language: "Python 3"
  framework: "Apache Airflow / PySpark"
  runtime: "GCP Dataproc (Spark on YARN)"
---

# SEO Deal Redirect Documentation

Automated daily pipeline that redirects expired Groupon deal URLs to relevant active deals from the same merchant, preserving SEO value and user experience.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints called and published by this service |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Hive tables, GCS buckets, reference data |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment variables, config files, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Python 3 |
| Framework | Apache Airflow (GCP Composer), PySpark |
| Runtime | GCP Dataproc 1.5 (Spark on YARN) |
| Build tool | Jenkins (`Jenkinsfile`) |
| Platform | GCP (Cloud Composer + Dataproc) |
| Domain | SEO / Computational SEO |
| Team | SEO — computational-seo@groupon.com |

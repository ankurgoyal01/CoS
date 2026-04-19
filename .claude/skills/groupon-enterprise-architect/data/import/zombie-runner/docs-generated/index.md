---
service: "zombie-runner"
title: "Zombie Runner Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumZombieRunner, continuumZombieRunnerStateStore, continuumZombieRunnerExternalTargets]
tech_stack:
  language: "Python 2.7 / 3.x"
  framework: "Custom ETL runtime"
  runtime: "Google Cloud Dataproc"
---

# Zombie Runner Documentation

Python-based ETL orchestration runtime that parses YAML workflow definitions, constructs directed acyclic graphs (DAGs), and executes task operators across data platform targets including Hive, Spark, Snowflake, Solr, Salesforce, and external REST services on Google Cloud Dataproc clusters.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | CLI interface and programmatic API |
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
| Language | Python 2.7 / 3.x |
| Framework | Custom ETL task runtime |
| Runtime | Google Cloud Dataproc |
| Build tool | setuptools / Jenkins |
| Platform | Continuum (GCP migration) |
| Domain | Data Engineering / ETL Orchestration |
| Team | GCP Migration Tooling POD (gcp-groupon-tooling-pod) |

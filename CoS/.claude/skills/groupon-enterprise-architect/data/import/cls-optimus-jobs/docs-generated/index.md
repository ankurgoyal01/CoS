---
service: "cls-optimus-jobs"
title: "CLS Optimus Jobs Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumClsOptimusJobs", "continuumClsHiveWarehouse"]
tech_stack:
  language: "HQL (Hive SQL) / Bash"
  framework: "Optimus Job Framework"
  runtime: "Apache Hive / Tez on Cerebro"
---

# CLS Optimus Jobs Documentation

Optimus-managed Hive job suite that ingests billing, shipping, and Consumer Data Service (CDS) location data from NA and EMEA sources, then coalesces all non-ping datasets into a unified location table in `grp_gdoop_cls_db`.

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
| Language | HQL (Hive SQL) / Bash |
| Framework | Optimus Job Framework (YAML-defined) |
| Runtime | Apache Hive on Tez (Cerebro cluster) |
| Build tool | None (YAML job definitions deployed via Optimus UI) |
| Platform | Continuum |
| Domain | Consumer Location Service (CLS) |
| Team | cls-engineering@groupon.com / #consumer-location-data |

---
service: "cls-optimus-jobs"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Location Service"
platform: "Continuum"
team: "cls-engineering@groupon.com"
status: active
tech_stack:
  language: "HQL (Hive SQL) / Bash"
  language_version: "Hive 2.x (Tez engine)"
  framework: "Optimus Job Framework"
  framework_version: "on-premise (optimus.groupondev.com)"
  runtime: "Apache Hive / Apache Tez"
  runtime_version: "Cerebro cluster"
  build_tool: "None (YAML job definitions)"
  package_manager: "None"
---

# CLS Optimus Jobs Overview

## Purpose

The Consumer Location Service (CLS) Optimus Jobs are a suite of scheduled Hive batch jobs that aggregate user location signals from billing, shipping, and Consumer Data Service (CDS) sources. Jobs ingest raw records from Teradata and Janus data sources into Hive staging tables within `grp_gdoop_cls_db`, then coalesce these non-ping datasets into a single unified location table to support search, advertising, and retargeting use cases.

## Scope

### In scope

- Ingesting NA and EMEA billing address data from `user_gp.user_billing_records` and EMEA billing system into `cls_billing_address_na` and `cls_billing_address_emea` Hive tables.
- Ingesting NA and EMEA shipping address data from `user_gp.orders` and EMEA order tables into `cls_shipping_na` and `cls_shipping_emea` Hive tables.
- Ingesting CDS user profile location data from `user_gp.user_profile_locations` into `cls_user_profile_locations_na` Hive table.
- Ingesting Janus-derived consumer location events into `cls_user_profile_locations_na` via the `janus_all` dataset.
- Normalising postal codes, validating country codes, filtering invalid UUIDs across all ingestion pipelines.
- Coalescing billing, shipping, and CDS non-ping records into `coalesce_nonping` and `coalesce_nonping_staging` target tables with latitude/longitude enrichment via `country_pincode_lat_lng_lookup_optimized`.
- Supporting both backfill (full historical load) and delta (daily incremental load) job variants for all data sources.

### Out of scope

- Real-time (ping) location tracking — handled by separate CLS ping pipelines.
- Serving real-time location queries to downstream consumers — handled by the CLS API service.
- GRP20 location history ingestion from Janus (managed as a separate Optimus group not part of the primary coalesce flow).
- Data quality alerting beyond job failure notifications.

## Domain Context

- **Business domain**: Consumer Location Service — aggregates user location signals for search, advertising, and retargeting.
- **Platform**: Continuum
- **Upstream consumers**: CLS API, advertising targeting systems, search relevance pipelines (consumers of `coalesce_nonping` tables in `grp_gdoop_cls_db`).
- **Downstream dependencies**: Teradata (`user_gp` schema via NA and EMEA DSNs), Janus dataset (`grp_gdoop_pde.janus_all`), HDFS landing zone, Cerebro Hive cluster.

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering team | cls-engineering@groupon.com — owns job definitions and deployment |
| Slack channel | #consumer-location-data (CKFBQ8UNR) — operational notifications |
| PagerDuty | consumer-location-service@groupon.pagerduty.com — receives job failure alerts |
| Data consumers | Advertising, search, and retargeting teams consuming `coalesce_nonping` tables |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Query language | HQL (Hive SQL) | Hive 2.x (Tez engine) | All job YAML files |
| Job orchestration | Optimus (on-premise) | optimus.groupondev.com | OWNERS_MANUAL.md |
| Execution engine | Apache Tez | `tez.queue.name = public` | All job YAML `hql` config |
| Cluster | Cerebro (Hadoop) | `cerebro-namenode.snc1:8020` | All job YAML context |
| Job definition format | YAML | — | `*.yml`, job spec files |
| Script runner | Bash / ScriptTask | — | `__start__` / `__end__` tasks |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| HQLExecute.py | Optimus built-in | scheduling | Executes Hive SQL statements within Optimus job steps |
| RemoteHadoopClient.py | Optimus built-in | scheduling | Copies local export files to HDFS landing paths |
| SQLExport (Optimus) | Optimus built-in | db-client | Exports rows from Teradata databases to local delimited files |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted.

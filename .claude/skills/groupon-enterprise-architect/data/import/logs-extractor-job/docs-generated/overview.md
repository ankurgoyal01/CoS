---
service: "logs-extractor-job"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Observability / Log Analytics"
platform: "Continuum"
team: "Orders"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES Modules (ESM)"
  framework: "none"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: "20"
  build_tool: "npm"
  package_manager: "npm"
---

# Log Extractor Job Overview

## Purpose

The Log Extractor Job is a scheduled batch job that extracts operational logs from Elasticsearch for the previous hour and uploads transformed datasets to Google BigQuery and optionally MySQL. It centralizes log data from multiple Groupon platform sources — PWA, proxy (api_proxy), Lazlo, and orders — into analytical and relational stores, enabling downstream reporting, monitoring, and user-journey analysis.

## Scope

### In scope

- Extracting time-bounded logs from Elasticsearch via the `@groupon/logs-processor` SDK
- Transforming raw Elasticsearch documents into structured records for each log type (pwa_logs, proxy_logs, lazlo_logs, orders_logs)
- Creating and partitioning BigQuery tables automatically before upload
- Creating MySQL tables via DDL automatically before insert
- Generating per-bCookie session summaries (`bcookie_summary`) from PWA logs
- Producing denormalized combined log records that join PWA, proxy, Lazlo, and orders data by requestId (`combined_logs`)
- Supporting US and EU Elasticsearch region selection via the `REGION` environment variable
- Accepting CLI overrides for time range, BigQuery dataset name, and MySQL database name

### Out of scope

- Log ingestion into Elasticsearch (handled upstream by platform services)
- Real-time or streaming log processing (this is a batch hourly job)
- Log retention management or deletion policies in BigQuery/MySQL
- Alert evaluation or anomaly detection on extracted log data
- Elasticsearch cluster management

## Domain Context

- **Business domain**: Observability / Log Analytics
- **Platform**: Continuum
- **Upstream consumers**: Scheduled Kubernetes CronJob (`cron-job` and `cron-job2` components); human operators running ad-hoc backfills
- **Downstream dependencies**: Elasticsearch (source), Google BigQuery (primary sink), MySQL (optional sink)

## Stakeholders

| Role | Description |
|------|-------------|
| Orders Engineering | Service owner; maintains job configuration and deployment |
| Data / Analytics | Consumers of BigQuery log datasets for reporting and analysis |
| Platform Oncall | Monitors job execution health; responds to extraction failures |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (ESM) | ES2020+ | `package.json` — `"type": "module"` |
| Runtime | Node.js | 20 | `Dockerfile` — `FROM docker-dev.groupondev.com/node:20` |
| Build tool | npm | — | `package.json`, `npm ci` in Dockerfile |
| Package manager | npm | — | `package-lock.json` present |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `@groupon/logs-processor` | git#main | integration | Elasticsearch log extraction SDK providing `extractLogsForTimeRangeExact`, logger, and utility functions |
| `@google-cloud/bigquery` | ^7.5.2 | db-client | BigQuery client for dataset/table creation, schema management, and batch row insertion |
| `mysql2` | ^3.9.7 | db-client | Promise-based MySQL client for connection pooling and batched inserts |
| `dotenv` | ^16.4.5 | configuration | Loads `.env` file into `process.env` at startup |
| `config` | ^3.3.11 | configuration | Environment-layered configuration merging (`default.js`, `staging.js`, `production.js`) |
| `moment` | ^2.30.1 | scheduling | UTC time range calculation utilities for previous-hour extraction windows |

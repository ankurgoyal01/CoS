---
service: "emailsearch-dataloader"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumEmailSearchPostgresDb"
    type: "postgresql"
    purpose: "Stores email search operational data, stat-sig metrics, and Quartz job state"
  - id: "continuumDecisionEnginePostgresDb"
    type: "postgresql"
    purpose: "Stores decision engine campaign state"
  - id: "continuumCampaignPerformanceMysqlDb"
    type: "mysql"
    purpose: "Read-only access to campaign performance data"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Analytics export of statistical significance metrics"
---

# Data Stores

## Overview

The Email Search Dataloader owns or accesses four data stores. It has read/write access to two PostgreSQL databases (Email Search and Decision Engine), read-only access to a MySQL database (Campaign Performance), and read/write access to the Hive analytics warehouse for metrics export. PostgreSQL connection pooling is managed via JTier DaaS (HikariCP). The Hive connection uses a dedicated HikariCP pool configured through `HiveConfig`. Quartz job scheduling state is persisted in PostgreSQL via `jtier-quartz-postgres-migrations`.

## Stores

### Email Search Postgres (`continuumEmailSearchPostgresDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumEmailSearchPostgresDb` |
| Purpose | Stores email search operational data and statistical significance metrics; also hosts Quartz job scheduler state |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` and `jtier-quartz-postgres-migrations` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `campaign_stat_sig_metrics` | Stores per-treatment statistical significance results for each campaign decision run | `campaign_send_id`, `campaign_id`, `experiment_type`, `significance`, `significance_threshold`, `decision_flag`, `stat_sig_flag`, `email_click`, `email_send`, `email_open`, `push_click`, `push_send`, `created_at` |
| Quartz tables | Quartz scheduler job state (triggers, job details, locks) | Managed by JTier Quartz bundle |

#### Access Patterns

- **Read**: `StatSigMetricsDao` reads `campaign_stat_sig_metrics` for the latest timestamp when preparing Hive export batches
- **Write**: `StatSigMetricsDao.addStatSigMetric()` inserts statistical significance results after each decision run; Quartz tables written by the job scheduler
- **Indexes**: Not directly observable from source; timestamp-based queries suggest index on `created_at`

---

### Decision Engine Postgres (`continuumDecisionEnginePostgresDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumDecisionEnginePostgresDb` |
| Purpose | Stores decision engine state used to track campaign rollout decisions |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Order / GP data tables | Stores order gross revenue data per UTM campaign for GP metric evaluation | `utm_campaign`, `grossRevenue` (inferred from `OrderDao` and `OrderDto`) |

#### Access Patterns

- **Read**: `OrderDao.findByUtmCampaigns()` reads order/GP data for campaigns needing GP metric evaluation during decision tasks
- **Write**: `CampaignPerformanceService.updateGpMetrics()` updates GP metrics per campaign send ID and platform

---

### Campaign Performance MySQL (`continuumCampaignPerformanceMysqlDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCampaignPerformanceMysqlDb` |
| Purpose | Read-only access to campaign performance data (click, open, send counts) |
| Ownership | shared (external owner) |
| Migrations path | Not owned by this service |

#### Access Patterns

- **Read**: `CampaignPerformanceDao` reads performance metrics per campaign send ID for use in statistical evaluation
- **Write**: This service does not write to this database
- **Indexes**: Not observable from this codebase

---

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `hiveWarehouse` |
| Purpose | Analytics export destination for campaign statistical significance metrics |
| Ownership | external (shared analytics platform) |
| Migrations path | Tables created dynamically by the MetricsExportJob |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `campaign_stat_sig_metrics` | External ORC table partitioned by `record_date`, bucketed by `campaign_id` | `campaign_send_id`, `campaign_id`, `experiment_type`, `significance`, `significance_threshold`, `decision_flag`, `stat_sig_flag`, `email_click`, `email_send`, `email_open`, `push_click`, `push_send`, `created_at`, `record_date` |
| `campaign_stat_sig_metrics_temp` | Staging text file table used as intermediate target during export | Same fields, no partitioning |

#### Access Patterns

- **Read**: `HiveQueryExecutor` queries the latest timestamp from the Hive table to determine the incremental export window
- **Write**: `MetricsExportJob` creates temp table, bulk inserts from Postgres, then inserts-selects into the partitioned external table with ORC/Snappy compression
- **Indexes**: Table is bucketed by `campaign_id` (10 buckets), sorted by `created_at DESC`; partitioned by `record_date`

## Caches

> No evidence found in codebase of any caching layer (Redis, Memcached, or in-memory cache).

## Data Flows

1. Kafka events arrive and update campaign performance state in `continuumEmailSearchPostgresDb` (via `emailSearchService` and `daoLayer_EmaDat`)
2. Quartz `DecisionJob` and `EngageUploadJob` read performance data from `continuumCampaignPerformanceMysqlDb` (via Campaign Performance Service client) and order/GP data from `continuumDecisionEnginePostgresDb`
3. After decision evaluation, stat-sig metrics are written to `continuumEmailSearchPostgresDb` (`campaign_stat_sig_metrics` table)
4. `MetricsExportJob` reads new metrics from `continuumEmailSearchPostgresDb` since last Hive export timestamp, inserts into Hive staging table, then merges into partitioned ORC table in `hiveWarehouse`

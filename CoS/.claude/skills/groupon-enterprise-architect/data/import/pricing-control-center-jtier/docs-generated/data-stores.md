---
service: "pricing-control-center-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPricingControlCenterJtierPostgres"
    type: "postgresql"
    purpose: "Transactional datastore for sales, products, scheduling state, versions, and Quartz metadata"
  - id: "gcpDynamicPricingBucket"
    type: "gcs"
    purpose: "Object storage for RPO model extract files"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Read-only source for flux model schedules, superset deal data, and Custom ILS model outputs"
---

# Data Stores

## Overview

The service's primary transactional store is a PostgreSQL database managed by GDS (Google Data Services) in GCP. All sale lifecycle state, product records, scheduling task tracking, version management, user access control, and Quartz scheduler metadata are persisted there. Schema migrations are managed via JTier's migration framework (Flyway-based). In addition, the service reads ML model output data from Hive (on-prem and GCP-backed gateway) and downloads RPO extract files from a GCS bucket.

## Stores

### Pricing Control Center PostgreSQL (`continuumPricingControlCenterJtierPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPricingControlCenterJtierPostgres` |
| Purpose | Primary transactional datastore — sale and product lifecycle, scheduling state, user roles, analytics upload tracking, Quartz job store |
| Ownership | owned |
| Migrations path | `jtier-migrations` (JTier migration bundle; Flyway-based, managed via `jtier-migrations` and `jtier-quartz-postgres-migrations` dependencies) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `sale` | Represents one ILS sale event across a channel | `sale_id` (UUID), `status`, `channel`, `start_time`, `end_time`, `analytics_status`, `scheduled_by`, `program_id` |
| `sale_product` (from CSV) | Individual product rows within a sale | `product_id` (UUID), `sale_id`, `status`, `quote_id`, `marginal_cost`, `exclusion_reason` |
| `task` | Quartz sub-job execution tracking | `task_id`, `sale_id`, `status` (RUNNING/COMPLETE/PAUSE) |
| `control_center_users` | RBAC user registry for the Control Center | `email`, `role` (IM/IMTL/SUPER/SEARCH), `channel[]` |
| `sale_flux_run` | Mapping of Custom ILS sales to ML model run IDs | `sale_id`, `model_id`, `run_id`, `algorithm`, `score_timestamp` |
| `sale_division` | Division groupings within a Custom ILS sale | `sale_id`, `division`, `start_time` |
| `custom_ils_flux_model` | Cached flux model schedule data synced from Hive | `model_id`, `target_date` |
| `superset_version` | Version tracking for superset deal data loads | `version_id`, `create_date`, `status` |
| `superset_deals` | Pre-fetched superset deal eligibility data (per deal permalink) | `deal_permalink`, `version_id` |
| `superset_deal_options` | Pre-fetched superset deal options (per inventory product) | `inventory_product_id`, `version_id` |
| `sellout_version` | Tracks processed Gdoop flux output files for Sellout | `file_name`, `status` |
| `rpo_version` | Tracks processed GCS extract files for RPO | `file_name`, `status` |
| `log_raw_internal` | Internal analytics records for scheduled products | `sale_id`, `product_id`, `quote_id` |
| Quartz tables | Clustered Quartz scheduler job store | Standard Quartz PostgreSQL schema (`qrtz_*`) |

#### Access Patterns

- **Read**: Sales polled every 15 minutes by `CheckForPendingSalesJob` for `SCHEDULING_PENDING` / `UNSCHEDULING_PENDING` status. Products loaded in batches of 10 by scheduling sub-jobs. Superset data queried during scheduling for deal eligibility. User roles looked up on every authenticated request.
- **Write**: Sale and product statuses updated atomically during job transitions. Quartz job store used for clustered trigger persistence. Version records created on each Sellout/RPO/Superset data load cycle. Analytics (log raw) rows inserted after successful scheduling.
- **Indexes**: Not directly inspectable from source; schema managed via JTier migrations. Key indexed columns are expected on `sale.status`, `sale_product.sale_id`, `sale_product.status`, and `control_center_users.email`.

### Dynamic Pricing GCS Bucket (`gcpDynamicPricingBucket`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | `gcpDynamicPricingBucket` |
| Purpose | Stores RPO model extract files in CSV format consumed by `RetailPriceOptimizationJob` |
| Ownership | external (GDS-managed) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `extract-{date}.out` | RPO model output CSV file containing product IDs and pricing for the next day | Date-stamped filename pattern, product rows with pricing data |

#### Access Patterns

- **Read**: `RetailPriceOptimizationJob` downloads the expected file for the next day using GCS SDK (`google-cloud-storage` 1.25.0). Configured via `gcpConfiguration.gcpBucket`.
- **Write**: Not applicable — files are produced by external Data Science pipelines.

### Hive Warehouse (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | Hive (JDBC) — on-prem (`cerebro-hive-server3.snc1`) and GCP-backed gateway (`datalake-connect.data-comp.prod.gcp.groupondev.com`) |
| Architecture ref | `hiveWarehouse` |
| Purpose | Read-only source for Custom ILS flux model schedules, ILS flux model location mappings, Sellout flux output files, and superset deal data |
| Ownership | external (Data Warehouse team) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_local_ds_db.ils_flux_model_schedule_view` | Maps ILS start dates to flux model IDs for Custom ILS | `model_id`, `target_date` |
| `grp_gdoop_local_ds_db.ils_flx_model_location` | Maps model IDs to Hive output table names | `model_id`, `output_table` |
| Model output tables (per model) | Contains deal options (inventory product IDs and prices) for a given model run | `run_id`, `target_ils_start_date`, `inventory_product_id`, `score_timestamp_in_utc` |
| Superset tables | Pre-computed deal eligibility and pricing data | `deal_permalink`, `inventory_product_id`, `create_date` |

#### Access Patterns

- **Read**: Periodic polling by `CustomILSFluxModelSyncJob` (hourly) and `SupersetFetchJob` (every 6 hours). On-demand queries by `CustomILSFetchDealOptionsJob` when processing upcoming Custom ILS sales. Retry policy configured: up to 7 attempts with 5-minute wait intervals (`retryPolicy.hive`).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `TaskStatusCache` | in-memory | Tracks sub-job task completion status within a single `ILSSchedulingJob` execution | Duration of single job execution |

## Data Flows

1. Hive model data is periodically synced to PostgreSQL (`custom_ils_flux_model` table) by `CustomILSFluxModelSyncJob` — this populates the model picker UI.
2. Hive superset data is periodically fetched into PostgreSQL (`superset_deals`, `superset_deal_options`) by `SupersetFetchJob` — this enables fast eligibility lookups during scheduling without live Hive queries.
3. GCS RPO extract files are downloaded by `RetailPriceOptimizationJob`, parsed, and inserted as sale/product records in PostgreSQL, then scheduled via the Pricing Service.
4. After successful scheduling, product data (with quote IDs) flows from PostgreSQL into internal log raw tables and optionally into external Teradata tables via `AnalyticsUploadJob`.

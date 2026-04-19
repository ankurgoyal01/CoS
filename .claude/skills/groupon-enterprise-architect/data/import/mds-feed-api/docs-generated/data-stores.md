---
service: "mds-feed-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMdsFeedApiPostgres"
    type: "postgresql"
    purpose: "Transactional store for all feed metadata, schedules, batches, upload profiles, metrics"
---

# Data Stores

## Overview

The Marketing Feed Service owns a single PostgreSQL database as its primary transactional datastore. All feed configuration, group, schedule, batch, metrics, upload profile, and SSH key pair records are persisted here. Schema migrations are managed via the `jtier-migrations` bundle. The service does not own a cache; generated feed file artifacts are stored externally in Google Cloud Storage (GCS), which is accessed via the `bigQuery`/GCS integration (not owned by this service).

## Stores

### MDS Feed API Postgres (`continuumMdsFeedApiPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumMdsFeedApiPostgres` |
| Purpose | Transactional store for feed definitions, groups, schedules, batch records, metrics, upload profiles, upload batches, SSH key pairs, and audit log |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (PostgresMigrationBundle) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| feeds | Feed configuration definitions | `feedUuid`, `clientId`, `status` (ACTIVE/DRAFT/PENDING/DELETED), `uploadable`, `configuration` (JSON), `uploadConfig` (JSON) |
| feed_groups | Groups of feed configurations | `feedGroupUuid`, `name`, `createdBy` |
| feed_group_schedules | Cron schedules for feed groups | `scheduleUuid`, `feedGroupUuid`, `cronExpr`, `status` |
| batches | Spark job batch tracking records | `uuid`, `feedUuid`, `livyId`, `applicationId`, `state`, `creationDate` |
| metrics | Feed generation metrics posted by Spark job | `feedUuid`, metric values, `creationDate` |
| upload_batches | Upload operation tracking | `uuid`, `feedUuid`, `feedBatchUuid`, `state` |
| upload_profiles | Upload destination configurations (S3, SFTP, GCP) | `uuid`, `name`, profile configuration |
| ssh_key_pairs | SSH key pairs for SFTP upload destinations | `uuid`, `name`, encrypted private/public keys |
| audit | Audit log of configuration change events | `type`, `uuid`, event details |
| quartz_* | Quartz scheduler persistence tables (via jtier-quartz-postgres-migrations) | Quartz standard schema |

#### Access Patterns

- **Read**: Feed configurations fetched by UUID or `clientId`; batches queried by state, feed UUID, date, Livy ID, or YARN application ID; upload batches queried by feed UUID, batch UUID, date, and state; metrics queried by feed UUID for statistics computation
- **Write**: Feed configurations created/updated/deleted via REST; batch records created on Spark submission and updated on status poll; metrics written by the Spark job callback on `/metrics`; upload batch records created and updated during upload orchestration
- **Indexes**: Not directly visible from the repository; Quartz uses its standard index schema from `jtier-quartz-postgres-migrations`

## Caches

> No evidence found in codebase. The service does not use a cache layer.

## Data Flows

- Feed configuration JSON (datasources, transformers, filters, fields, file formats) is stored as structured JSON in the `feeds` table and read by the Spark job at generation time.
- Batch state is written on Spark submission and updated periodically by the `CheckBatchStateJob` Quartz cron by polling the Livy API.
- Metrics are written by the `mds-feed-job` Spark job after successful file generation via POST to `/metrics`.
- The `CleanOldDataJob` Quartz cron deletes batch and metrics records older than 30 days on the 27th of each month at 12:00 UTC.
- Upload profile credentials (private keys for SFTP) are stored encrypted in PostgreSQL using the configured `SecurityConfig` RSA key.

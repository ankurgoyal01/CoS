---
service: "aes-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAudienceExportPostgres"
    type: "postgresql"
    purpose: "Primary operational datastore for audiences, jobs, metadata, and filtered users"
  - id: "continuumAudienceExportPostgresS2S"
    type: "postgresql"
    purpose: "Customer info mapping lookups (email, device ID resolution)"
---

# Data Stores

## Overview

AES owns two PostgreSQL datastores. The primary database (`continuumAudienceExportPostgres`) holds all operational data: audience metadata, Quartz job state, partner audience registrations, filtered-user records, and erasure denylist. The secondary S2S database (`continuumAudienceExportPostgresS2S`) is used for customer info mapping — resolving Groupon customer IDs to hashed email addresses and device IDs before export. In addition, AES reads from the Cerebro/Hive data warehouse (an external, shared store it does not own) to fetch source audience datasets.

## Stores

### AES Postgres (`continuumAudienceExportPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumAudienceExportPostgres` |
| Purpose | Primary operational store: audience metadata, job state, partner registrations, filtered users, denylist |
| Ownership | owned |
| Migrations path | `jtier-migrations` (managed via JTier migrations bundle) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `aes_service.aes_metadata` | Core audience record: schedule, type, status, targets | `id`, `ciaId`, `audienceType`, `scheduleType`, `jobStatus`, `jobSubStatus`, `active`, `targets` |
| Audience targets | Per-target (Facebook/Google/TikTok/Microsoft) status tracking | `aesId`, `target`, `status`, `updateCount` |
| Facebook audience lists (`DAAudienceLists`) | Facebook custom audience registrations per account/country | `id`, `audienceId`, `accountId`, `country`, `source` |
| Custom audiences (`CustomAudience`) | Generic partner audience entries for Google/TikTok/Microsoft | `id`, `audienceId`, `accountId`, `target`, `type`, `usersCount` |
| Filtered users | Users excluded from export (GDPR denylist, consent withdrawal) | customer identifiers |
| Quartz job tables | Scheduler state for all audience cron triggers | Quartz schema |

#### Access Patterns

- **Read**: Fetch audience metadata by ID or paginated list; read partner audience registrations; look up Quartz trigger states; query filtered-user denylist.
- **Write**: Insert new audience records on creation; update `jobStatus` / `jobSubStatus` throughout each export pipeline run; upsert partner audience IDs after creation on ad networks; insert denylist records on GDPR erasure.
- **Indexes**: Not visible from source; standard PK-indexed access by `id` and `ciaId`.

---

### AES Postgres S2S (`continuumAudienceExportPostgresS2S`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumAudienceExportPostgresS2S` |
| Purpose | Customer info mapping — resolving customer IDs to hashed emails and device IDs for export payloads |
| Ownership | owned |
| Migrations path | Managed separately; accessed via `AmsAudienceDAO` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| AMS customer info / IDFA tables | Maps Groupon customer IDs to email addresses and device IDs (IDFA/DID) | `customerId`, `email`, `deviceId` |

#### Access Patterns

- **Read**: Batch lookups of customer email and device-ID records during the MAP_CUSTOMER_INFO pipeline stage; daily IDFA table sync reads from Cerebro juno tables.
- **Write**: Daily import of new device-ID records from Cerebro juno tables (UpdateIdfaTablesJob).
- **Indexes**: Not visible from source.

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| AMS audience info cache | in-memory | Caches extended audience info (AES + AMS + Facebook + Google) to avoid repeated DB lookups | Refreshed on demand via `POST /api/v1/audiences/updateAmsCache` and `POST /api/v1/audiences/updateFBCache` |

## Data Flows

1. On audience job execution, AES reads source customer data from `continuumCerebroWarehouse` (Hive via JDBC).
2. Delta records are computed and written to `continuumAudienceExportPostgres` (INSERT_DATA_TO_DELTA stage).
3. Customer IDs are resolved to emails/device IDs via `continuumAudienceExportPostgresS2S` (MAP_CUSTOMER_INFO stage).
4. Resolved and hashed user lists are uploaded to ad platforms; partner audience IDs are written back to `continuumAudienceExportPostgres`.
5. GDPR erasure events result in deletion rows being written to `continuumAudienceExportPostgres` denylist tables and removal calls to each ad platform.

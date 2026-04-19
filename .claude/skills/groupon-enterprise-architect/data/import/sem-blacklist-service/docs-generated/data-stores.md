---
service: "sem-blacklist-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSemBlacklistPostgres"
    type: "postgresql"
    purpose: "Stores all denylist/blacklist entries with full audit trail"
---

# Data Stores

## Overview

The SEM Blacklist Service owns a single PostgreSQL database provisioned via Groupon's DaaS (Database-as-a-Service) platform. All denylist entries are stored in one primary table (`sem_raw_blacklist`). The service manages schema migrations using `jtier-migrations` and Quartz job store tables via `jtier-quartz-postgres-migrations`. There are no caches or secondary data stores.

## Stores

### SEM Blacklist Postgres (`continuumSemBlacklistPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumSemBlacklistPostgres` |
| Purpose | Stores all denylist entries with full lifecycle (created, deleted, active status) and audit fields |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` dependency (migration files not directly visible in repo root) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `sem_raw_blacklist` | Central denylist store — one row per unique denylist entry per client/country/search-engine combination | `entity_id`, `entity_option_id`, `client`, `country_code`, `search_engine`, `active`, `brand_merchant_id`, `brand_blacklist_type`, `created_by`, `create_at`, `deleted_by`, `deleted_at` |
| Quartz tables | Quartz scheduler job store for `DenylistAsanaTaskProcessingJob` and `GDocRefreshBlacklistJob` | Managed by `jtier-quartz-postgres-migrations` |

#### Access Patterns

- **Read**: Queries filter on `client`, `country_code`, and `active` as primary predicates. Optional secondary filters include `entity_option_id` (program-channel composite), `search_engine`, and date range (`create_at BETWEEN :startAt AND :endAt`). Batch reads accept multiple country codes using SQL `IN` clauses. Pagination is applied with `OFFSET :page*:size LIMIT :size`.
- **Write**: Inserts new entries with a conditional `WHERE NOT EXISTS` guard to prevent duplicates. Updates existing inactive entries back to active when re-added. Soft-deletes by setting `active = FALSE`, `deleted_by`, and `deleted_at`. Full refresh (for Google Sheets sync) computes set difference between current active entries and incoming entries, then inserts new and soft-deletes removed entries in a single transaction.
- **Indexes**: Not directly visible in source; the unique constraint key used in business logic is `(entity_id, entity_option_id, brand_merchant_id, client, country_code, search_engine)`.

## Caches

> No evidence found in codebase. No caching layer is configured.

## Data Flows

- **REST API writes**: Caller sends `POST /denylist` or `DELETE /denylist` → `RawBlacklistDAO.insertAll()` or `RawBlacklistDAO.deletePrevious()` → `sem_raw_blacklist`
- **Asana task processing**: Quartz job polls Asana API → `DenylistAsanaTaskProcessor` validates task → `RawBlacklistDAO.insertAll()` or `RawBlacklistDAO.deletePrevious()` → `sem_raw_blacklist`
- **Google Sheets refresh**: Quartz job polls Google Sheets API → `GDocBlacklistStore.refreshGDocBlacklists()` → `RawBlacklistDAO.refreshRawBlacklist()` (transactional full replace) → `sem_raw_blacklist`
- **REST API reads**: Caller sends `GET /denylist` → `RawBlacklistDAO.fetch()` → `sem_raw_blacklist` → response

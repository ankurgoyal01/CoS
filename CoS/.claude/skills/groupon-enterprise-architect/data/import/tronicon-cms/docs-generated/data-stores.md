---
service: "tronicon-cms"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTroniconCmsDatabase"
    type: "mysql"
    purpose: "Primary persistence for CMS content, audit logs, and usability statistics"
---

# Data Stores

## Overview

Tronicon CMS uses a single MySQL database as its primary and only data store, provisioned via Groupon's DaaS (Database-as-a-Service) team. Schema migrations are applied automatically at startup using the JTier Flyway integration (`jtier-migrations`). There are no caches or secondary data stores.

## Stores

### Tronicon CMS MySQL (`continuumTroniconCmsDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumTroniconCmsDatabase` |
| Purpose | Primary persistence for CMS content, audit logs, and usability statistics |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| CMS Content | Stores versioned content items for legal and static pages | `id`, `path`, `contentKey`, `content`, `contentType`, `status`, `locale`, `brand`, `version`, `team`, `created`, `createdBy`, `modified`, `modifiedBy`, `md5Checksum` |
| CMS Content Audit Log | Tracks all changes to content items for audit trail | Path, brand, locale, version, minor version, content key, modification author, timestamps |
| CMS Usability Stats | Records usability analysis metrics per content item | `id`, `cmsContentId`, `scriptCount`, `contentWarningCount` |

#### Access Patterns

- **Read**: Queries by path (exact and partial via `subPath`), by content key, by integer ID, by team, by brand/locale/version combinations; paginated listing of all content and unique paths; audit log lookups by path + brand + locale + version + key; statistics lookup by content ID
- **Write**: Upsert of content items (insert on new path + locale + brand; update on existing integer ID); draft creation via clone (auto-increment version); state transitions (DRAFT → VALIDATED → ARCHIVED) affecting all items under a path/locale/brand; audit log writes on every content mutating operation; usability statistics upsert by content ID
- **Indexes**: Not directly visible from source; standard indexes inferred on `path`, `locale`, `brand`, `status`, and `version` fields based on query patterns

#### Migration Tooling

- Uses Flyway via `jtier-migrations` dependency
- Migration script naming convention: `V<version>__<WhatTheScriptIsDoing>.sql`
- Flyway history table: `schema_version`
- Migrations run automatically on application startup — no manual migration step required

#### Database Environments

| Environment | Database name |
|-------------|---------------|
| Production | `tronicon_cms_prod` |
| Staging | `tronicon_stg` |
| UAT | `tronicon_cms_uat` |

#### DaaS Operations

- **Replication strategy**: Main/secondary replica set (managed by GDS team)
- **Backup**: Managed by GDS team per standard DaaS backup policy
- **Database support**: Slack `#gds-daas`; instance catalog at `https://pages.github.groupondev.com/ops/paver/catalog/cloud.html`

## Caches

> No evidence found in codebase. This service does not use any caching layer.

## Data Flows

Content is written directly to the MySQL database by the `CMSContentDao`, `CMSContentAuditLogDao`, and `CMSUsabilityStatsDao` JDBI components. All reads are served from the same MySQL primary/secondary cluster. The DaaS team manages backup and replication. There is no CDC pipeline, ETL, or materialized view derived from this data store.

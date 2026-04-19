---
service: "custom-fields-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCustomFieldsDatabase"
    type: "postgresql"
    purpose: "Stores custom field templates and metadata"
---

# Data Stores

## Overview

Custom Fields Service owns a single primary data store — a PostgreSQL database provisioned via Groupon's DaaS (Database as a Service) platform. It holds all custom field template definitions. An in-memory Guava cache is used as a short-lived read cache for user service client responses. No external caching services (Redis, Memcached) are used.

## Stores

### Custom Fields Database (`continuumCustomFieldsDatabase`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumCustomFieldsDatabase` |
| Purpose | Stores custom field template definitions (field types, localized labels, validation rules, template metadata) |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (Flyway-style migrations bundled with the application) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Custom field set | Root record for a group of fields | `id` (UUID), `created_at`, `version`, `template_type` (COMMON/PRIVATE), `internal_admin_name` |
| Custom field template | Individual field definition within a set | `property`, `type` (GROUP/TEXT/EMAIL/PHONE/BOOLEAN/NUMBER/MESSAGE), `required`, `prepopulation_source`, `pattern`, `min_length`, `max_length`, `min_value`, `max_value`, `country_codes` |
| Localized content | Per-locale labels and hints for each field | `locale`, `label`, `hint`, `error_messages` |

#### Access Patterns

- **Read**: Point-lookup by UUID (primary key) for `GET /v1/fields/{uuid}` and validate flows; full table scan with limit/offset for `GET /v1/fields` listing; multi-UUID batch reads for merged field set operations
- **Write**: Insert on `POST /v1/fields` (create template); hard delete on `DELETE /v1/fields/{uuid}` (admin)
- **Indexes**: Primary key on field set UUID; no additional indexes visible from source

#### Production Connection Details

| Region | Host | Database | Port (transaction) | Port (session) |
|--------|------|----------|--------------------|----------------|
| US (GCP us-central1) | `custom-fields-service-rw-na-production-db.gds.prod.gcp.groupondev.com` | `customfieldsapp_prod` | 5432 | 6432 |
| NA (legacy AWS us-west-1) | `customfieldsapp-prod-1.czlsgz0xic0p.us-west-1.rds.amazonaws.com` | `customfieldsapp_prod` | — | — |
| EU (AWS eu-west-1) | `customfieldsapp-prod.cqgqresxrenm.eu-west-1.rds.amazonaws.com` | `customfieldsapp_prod` | — | — |

Connection is managed by the DaaS connection pool. Transaction pool size: 50 (JTier default). Session pool size: 2 (JTier default).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `userServiceClientCache` | In-memory (Guava) | Caches user profile data fetched from Users Service to reduce outbound HTTP calls | Short-lived (milliseconds, configurable via `cacheSize`/`cacheExpire`; production: 10,000 entries, 5 units) |
| `localizedCustomFieldsFetcher` cache | In-memory (Guava) | Caches localized field sets to reduce repeated database reads | Production cache size: 0 (disabled in production; used in development) |
| `customFieldsValidatorFetcher` cache | In-memory (Guava) | Caches validator instances for field templates | Production cache size: 0 (disabled in production) |

## Data Flows

All data originates from administrative `POST /v1/fields` calls that create field templates in PostgreSQL. At read time, templates are loaded from PostgreSQL, optionally cached in-memory, translated to the requested locale, and optionally enriched with user profile data from the Users Service before being returned to the caller. No ETL pipelines, CDC streams, or cross-region replication is managed by this service — DaaS handles underlying persistence infrastructure.

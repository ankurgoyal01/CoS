---
service: "deal-book-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumDealBookMysql"
    type: "mysql"
    purpose: "Primary store for fine print clauses, attributes, categories, rules, persisted fine prints, content versions, and mappings"
  - id: "continuumDealBookRedis"
    type: "redis"
    purpose: "API response cache"
---

# Data Stores

## Overview

Deal Book Service uses two owned data stores: a MySQL database as the primary operational store for all fine print data, and a Redis cache for API response caching. The canonical source of fine print content is Google Sheets, which is periodically synchronized into MySQL by scheduled rake tasks. Redis reduces read load by caching frequently requested clause and fine print data.

## Stores

### MySQL Database (`continuumDealBookMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumDealBookMysql` |
| Purpose | Primary data store for fine print clauses, compiled fine prints, taxonomy mappings, content versioning, and Salesforce UUID mappings |
| Ownership | owned |
| Migrations path | `db/migrate/` (Rails convention) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `fine_print_clauses` | Core fine print clause records, including multi-language content | id, content, category_id, rule_id, locale |
| `attributes` | Attributes associated with fine print clauses | id, fine_print_clause_id, key, value |
| `categories` | Taxonomy category associations for clause filtering | id, taxonomy_id, name |
| `rules` | Business rules determining clause applicability | id, clause_id, conditions |
| `persisted_fine_prints` | Compiled fine print sets saved per deal | id, deal_id, external_uuid, content, version |
| `content_versions` | Tracks the version of fine print content for cache invalidation | id, version, created_at |
| `mappings` | Salesforce and external system UUID mappings for fine print records | id, entity_id, external_uuid, system |

#### Access Patterns

- **Read**: Fine print clause lookups by taxonomy category and geography; persisted fine print retrieval by deal ID; content version queries
- **Write**: Clause content sync from Google Sheets; taxonomy mapping updates from message bus events; persisted fine print creation/update/deletion via API
- **Indexes**: Not fully discoverable from inventory — expected indexes on `fine_print_clauses.category_id`, `persisted_fine_prints.deal_id`, `mappings.external_uuid`

### Redis Cache (`continuumDealBookRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumDealBookRedis` |
| Purpose | Caches fine print clause API responses to reduce MySQL read load |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

> Cache key structure not fully discoverable from inventory.

#### Access Patterns

- **Read**: Cache hit serves API response directly without MySQL query
- **Write**: Cache populated on first API response; invalidated on content version change
- **Indexes**: Not applicable

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealBookRedis` | redis | Fine print clause API response cache | Not discoverable from inventory |

## Data Flows

1. **Google Sheets to MySQL**: Scheduled rake tasks (`dealBookRakeTasks`) periodically call the Google Sheets API via `google_drive` to pull updated fine print clause content and reconcile it into `continuumDealBookMysql`.
2. **Taxonomy events to MySQL**: `dealBookMessageWorker` consumes `jms.topic.taxonomyV2.content.update` events and updates clause-category mappings in MySQL.
3. **MySQL to Redis**: API reads populate Redis cache. Cache is invalidated on content version increment.
4. **MySQL to API consumers**: `dealBookServiceApp` reads from MySQL (or Redis cache) and serves responses to Deal Wizard and other consumers.

---
service: "deal-catalog-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealCatalogDb"
    type: "mysql"
    purpose: "Primary relational store for deal catalog metadata"
  - id: "continuumDealCatalogRedis"
    type: "redis"
    purpose: "PWA queueing and short-lived coordination state"
---

# Data Stores

## Overview

The Deal Catalog Service uses a MySQL database as its primary relational store for deal metadata, accessed via JPA/JDBC. A Redis instance provides PWA queueing and short-lived coordination state. Data from the MySQL database is replicated to the Enterprise Data Warehouse (EDW) and BigQuery for analytics and reporting.

## Stores

### Deal Catalog DB (`continuumDealCatalogDb`)

| Property | Value |
|----------|-------|
| Type | MySQL (DaaS) |
| Architecture ref | `continuumDealCatalogDb` |
| Purpose | Primary relational data store for deal catalog metadata including titles, categories, availability, and merchandising attributes |
| Ownership | owned |
| Migrations path | > No evidence found in codebase (source code not available) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal | Core deal record with merchandising metadata | deal_id, uuid, title, subtitle, category_id, status |
| Deal Category | Category taxonomy for deal classification | category_id, name, parent_id, level |
| Deal Availability | Availability windows for deals | deal_id, start_date, end_date, timezone |
| Merchandising Attribute | Key-value merchandising attributes for deals | deal_id, attribute_key, attribute_value |
| Node Payload | Cached remote node payload metadata | node_id, payload_data, last_fetched, status |

> Entity names are inferred from the architecture model and component responsibilities. Exact table schemas require source code access.

#### Access Patterns

- **Read**: High-volume reads from multiple upstream consumers (Lazlo, inventory services, booking, affiliates) fetching deal metadata by ID, by category, by availability window, and by region. Catalog Repository (`dealCatalog_repository`) provides JPA-based data access.
- **Write**: Writes driven by Salesforce deal pushes, Deal Management API registrations, merchandising rule application, and Node Payload Fetcher scheduled updates.
- **Indexes**: Likely indexed on deal_id/uuid (primary key), category_id, status, availability dates, and region for efficient query patterns.

#### Data Replication

| Destination | Protocol | Purpose |
|-------------|----------|---------|
| EDW (`edw`) | Batch | Replicates deal catalog data for enterprise analytics and reporting |
| BigQuery (`bigQuery`) | Batch | Replicates deal catalog data for cloud-based analytics |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Deal Catalog Redis (`continuumDealCatalogRedis`) | Redis | PWA queueing and short-lived coordination state -- enqueues and de-duplicates PWA work items | Varies by key (short-lived coordination state) |

### Deal Catalog Redis (`continuumDealCatalogRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumDealCatalogRedis` |
| Purpose | PWA queueing and de-duplication of work items; short-lived coordination state |
| Ownership | owned |

#### Access Patterns

- **Write**: The Deal Catalog Service enqueues PWA work items and writes coordination state for de-duplication.
- **Read**: The service reads queue entries and coordination state to avoid duplicate processing.
- **Eviction**: Short-lived keys with TTL-based expiration for coordination state.

## Data Flows

```
Salesforce / Deal Mgmt API
        |
        v
  [Catalog API] --> [Catalog Repository (JPA)] --> [Deal Catalog DB (MySQL)]
                                                          |
                                                          |--> EDW (Batch replication)
                                                          |--> BigQuery (Batch replication)

  [Deal Catalog Service] --> [Deal Catalog Redis] (PWA queueing / coordination)
```

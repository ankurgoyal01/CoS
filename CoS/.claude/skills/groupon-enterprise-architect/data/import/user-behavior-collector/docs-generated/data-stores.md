---
service: "user-behavior-collector"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDealViewNotificationDb"
    type: "postgresql"
    purpose: "Primary behavioral data store: deal views, purchases, searches, ratings, email opens, wishlist flags, audience state, key-value configuration"
  - id: "continuumDealInfoRedis"
    type: "redis"
    purpose: "Deal info metadata cache: enriched deal objects and adult category IDs"
---

# Data Stores

## Overview

User Behavior Collector owns two data stores: a PostgreSQL database (`deal_view_notification`) that serves as the primary behavioral record store and job-state registry, and a Redis cache that holds enriched deal info objects for downstream notification use. Additionally, the job produces intermediate result files on Groupon's Hadoop/GCS cluster (HDFS) as part of the Spark pipeline and writes audience CSV files to Cerebro HDFS, but these are ephemeral outputs rather than owned persistent stores.

## Stores

### Deal View Notification DB (`continuumDealViewNotificationDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumDealViewNotificationDb` |
| Purpose | Stores deal views, purchases, searches, ratings, email opens, wishlist flags, sendlogs, audience state, and key-value job state |
| Ownership | owned |
| Migrations path | Hibernate auto-DDL (evidenced by `Hibernate.will populate the database with the correct tables` in README) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| deal view records | Tracks which user (bcookie/consumerId) viewed which deal | `dealUUID`, `bcookie`, `consumerId`, `platform`, `appVersion`, `viewTime`, `country` |
| deal purchase records | Tracks deal purchases per user | `dealUUID`, `bcookie`, `consumerId`, `country`, `eventTime`, `platform` |
| user search records | Tracks mobile and web search events | `bcookie`, `consumerId`, `searchString`, `eventTime`, `extraInfo`, `brand`, `country` |
| user rating data | Tracks user deal ratings | `consumerId`, `dealUUID`, `locale`, `ratingTime`, `dealRating`, `country` |
| email open records | Tracks email opens for targeted_deal channel | `bcookie`, `consumerId`, `dealUUID`, `country`, `eventTime`, `campaign` |
| audience info | Aggregated audience records used for publishing segments | `userId`, `countryCode` |
| wishlist flags | Per-consumer wishlist state | `consumerId`, `dealId` |
| sendlog | Record of previously sent notifications (normal and wishlist) | retention controlled by config |
| `key-value-store` | Job state store; holds `next-kafka-file` pointer for Spark file cursor | `key`, `value` |
| incentive campaigns | Stores incentive campaign definitions | queried by `getIncentiveCampaigns()` |
| sold-out deal IDs | Tracks deal options that are sold out (used for back-in-stock flow) | `dealOptionId`, `country` |

#### Access Patterns

- **Read**: Read-only JDBC transactions via `beginReadOnlyJdbc()` used for audience queries, deal view queries, and search audience queries; read-write JDBC via `beginJdbc()` for state updates and cleanups
- **Write**: Hibernate transactions (`beginHibernate()`) used for bulk batch-persisting event records (deal views, purchases, searches, ratings, email opens) during and after Spark job; JDBC transactions for key-value state updates (`next-kafka-file`), sendlog cleanup, and wishlist updates
- **Indexes**: Not directly visible in source; schema managed by Hibernate auto-DDL

### Deal Info Redis (`continuumDealInfoRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumDealInfoRedis` |
| Purpose | Cache for enriched deal info objects (from GAPI/Deal Catalog) and adult category IDs; read by downstream notification logic |
| Ownership | owned |
| Migrations path | Not applicable (cache; populated each batch run) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal info cache entries | Enriched `RedisDealInfo` objects per deal UUID | deal UUID (key), serialized deal info JSON (value) |
| Adult category IDs | Set of adult-content category identifiers used for content filtering | `AdultCategories` set |

#### Access Patterns

- **Read**: Not read by this job; downstream notification services consume cache entries
- **Write**: `DealInfoRefresher` component writes enriched deal objects on each batch run via Jedis client
- **Indexes**: Redis key-value; deal UUID as key

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumDealInfoRedis` | redis | Holds enriched deal metadata (availability, options, inventory) for triggered notification use | No evidence found in codebase |

## Data Flows

1. Spark Pipeline reads Janus Kafka parquet files from HDFS/GCS and writes classified event records to HDFS intermediate folders (`/grp_gdoop_emerging_channels/<user>-deal-views-<suffix>`, `-deal-purchases-<suffix>`, `-user-searches-<suffix>`, `-user-ratings-<suffix>`, `-email-opens-<suffix>`).
2. Data Access Layer reads HDFS intermediate files and batch-inserts records into `continuumDealViewNotificationDb`.
3. Deal Info Refresher fetches deal data from GAPI and Deal Catalog, then writes enriched deal objects to `continuumDealInfoRedis`.
4. Audience Publisher reads audience segments from `continuumDealViewNotificationDb`, writes per-country CSV files to Cerebro HDFS (`cerebro_host`/`cerebro_folder`), and notifies the Audience Management Service via REST.
5. Wishlist Updater reads consumer IDs from `continuumDealViewNotificationDb`, fetches current wishlists from the Wishlist Service, and writes updated wishlist flags back to `continuumDealViewNotificationDb`.
6. EMEA cleanupDB cron job (daily 02:00) removes aged records from `continuumDealViewNotificationDb` via `clearOldSendlog()` and `clearOldEmailOpen()`.

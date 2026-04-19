---
service: "travel-affiliates-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTravelAffiliatesDb"
    type: "mysql"
    purpose: "Operational data storage for the Travel Affiliates API"
  - id: "continuumTravelAffiliatesFeedBucket"
    type: "s3"
    purpose: "Hotel feed XML artifact storage"
---

# Data Stores

## Overview

The Travel Affiliates API uses two data stores: a MySQL database (accessed via JNDI) for operational data, and an AWS S3 bucket for storing generated hotel feed XML files. The MySQL database is conditionally enabled; the `doc/OWNERS_MANUAL.md` notes MySQL as the data store platform with master/slave replication. The S3 bucket is actively used by both the API container (on-demand feed generation) and the cron container (scheduled feed export jobs). No caching layer is configured; the owners manual explicitly states "No caching is currently done in the application."

## Stores

### Travel Affiliates DB (`continuumTravelAffiliatesDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumTravelAffiliatesDb` |
| Purpose | Relational datasource configured via JNDI (GpnDataDb); stores operational data when enabled |
| Ownership | owned |
| Migrations path | > No evidence found in codebase of a migrations directory. |

#### Key Entities

> No evidence found in codebase of specific table schemas. The database is referenced as a JNDI datasource (`GpnDataDb`) but no entity classes with `@Table` or ORM mappings are visible in the source tree.

#### Access Patterns

- **Read**: Reads operational data via JNDI-configured JDBC datasource
- **Write**: Writes operational data via JNDI-configured JDBC datasource
- **Indexes**: > No evidence found in codebase.

### Travel Affiliates S3 Feed Bucket (`continuumTravelAffiliatesFeedBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumTravelAffiliatesFeedBucket` |
| Purpose | Blob storage for generated hotel feed XML artifacts pushed by the cron container and on-demand feed endpoints |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Hotel feed XML files | Per-region hotel feed XML exports consumed by Google Hotel Ads and other partners | Region-scoped file paths with configurable bucket prefix |

#### Access Patterns

- **Read**: Feed files are read by external partners (Google Hotel Ads) directly from S3
- **Write**: `continuumTravelAffiliatesApi_awsFileUploadService` and `continuumTravelAffiliatesCron_awsFileUploadService` upload XML files using AWS SDK v2 (`software.amazon.awssdk:s3` 2.20.102)
- **Indexes**: Not applicable for S3 object storage

## Caches

> No caching is currently configured. The owners manual explicitly states: "No caching is currently done in the application."

## Data Flows

- The cron container (`continuumTravelAffiliatesCron`) runs daily at 10:00 UTC (`jobSchedule: "0 10 * * *"`), queries `continuumGetawaysApi` for active hotel deals and details, generates hotel feed XML per region, and writes the resulting files to `continuumTravelAffiliatesFeedBucket`.
- The API container (`continuumTravelAffiliatesApi`) can also trigger feed generation on demand via `POST /getaways/v2/feed` (handled by `HotelFeedController`), which follows the same path to S3.
- The MySQL database (`continuumTravelAffiliatesDb`) stores supplementary operational data accessed via JNDI.

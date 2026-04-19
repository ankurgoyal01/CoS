---
service: "coffee-to-go"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "coffeeDb"
    type: "postgresql"
    purpose: "Primary data store for accounts, deals, opportunities, usage events, and authentication"
---

# Data Stores

## Overview

Coffee To Go uses a single PostgreSQL 15+ database (`coffeeDb`) as its primary data store. The database holds CRM-sourced account and opportunity data, deal details, competitor/prospect data, review aggregations, usage tracking events, and authentication state. Performance-critical deal queries are served through a materialized view (`mv_deals_cache_v6` / `v_deals_cache_dev`) with PostGIS spatial indexing for efficient location-based lookups. An in-memory node-cache layer sits in front of the API for frequently accessed reference data like taxonomy groups and primary deal services.

## Stores

### Coffee DB (`coffeeDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL 15+ |
| Architecture ref | `coffeeDb` |
| Purpose | Primary data store for all application data |
| Ownership | owned |
| Migrations path | `apps/coffee-api/db/migrations/` |
| Migration tool | dbmate |
| Schema | `coffee_to_go` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `accounts` | Stores account/merchant information with location and billing data | account_id, location (geography), billing_location (geography) |
| `opportunities` | Stores opportunity data linked to accounts | account_id (FK), stages, owner |
| `deal_details` | Stores deal information and status | uuid, status, start_at, end_at |
| `redemption_locations` | Stores geographic locations for deal redemption | uuid (linked to deal_details), latitude, longitude |
| `prospects` | Stores competitor/prospect data from DeepScout | source, category, vertical |
| `reviews` | Stores review data from external sources | account_id (FK), rating_stars, rating_reviews |
| `account_reviews` | Aggregated review data per account | account_id (FK) |
| `usage_events` | Stores user interaction and usage tracking events | user_id (FK to auth_user), event_type, event_data (JSONB), event_timestamp |
| `job_metadata` | Tracks n8n workflow job status and progress | job status, progress |
| `pds_tg_map` | Maps Primary Deal Services to Taxonomy Groups by country | primary_deal_services, taxonomy_group, country |
| `auth_user` | User authentication and profile data (Better Auth) | id, email, name |
| `auth_session` | User session management (Better Auth) | token, user_id |
| `auth_api_key` | API key management for service-to-service access (Better Auth) | key, permissions |
| `config` | Application runtime configuration key-value store | key, value |

#### Materialized Views

| View | Purpose | Source Tables |
|------|---------|-------------|
| `mv_deals_cache_v6` | Production materialized view for optimized deal queries with spatial indexing and full-text search | accounts, opportunities, deal_details, redemption_locations, prospects |
| `v_deals_cache_dev` | Development version of deals cache view (toggled via `dev_view` feature flag) | Same as above |

#### Database Functions

| Function | Purpose |
|----------|---------|
| `refresh_deals_cache()` | Refreshes the materialized view |
| `get_deals_cache_stats()` | Returns cache statistics |
| `update_location_geography()` | Trigger function to update geography columns on location changes |
| `update_billing_location_geography()` | Trigger function for account billing location updates |
| `update_last_updated_at()` | Trigger function to auto-update timestamp columns |

#### Access Patterns

- **Read (deals)**: Spatial queries via `ST_DWithin` on the materialized view with PostGIS geography indexing; full-text search via `tsvector`/`tsquery`; filtered by category, vertical, stage, activity, priority, owner type, PDS, and TG. Served from a read-only connection pool (`dbRo`).
- **Read (reference)**: Taxonomy groups and primary deal services queried with in-memory caching (24-hour TTL for taxonomy/PDS, 10-minute TTL for config).
- **Write (tracking)**: Batch inserts of usage events (up to 50 per request) via the read-write pool.
- **Write (data ingestion)**: Bulk writes from n8n workflows for accounts, opportunities, deals, prospects, and reviews.
- **Indexes**: PostGIS spatial index on the materialized view `location` column; GIN index on `search_vector` for full-text search.

#### Connection Pools

The API maintains two connection pools:

| Pool | Purpose | Max connections | Idle timeout | Connection timeout |
|------|---------|----------------|-------------|-------------------|
| Primary (read-write) | Tracking writes, auth, config | Configurable via `APP_POOL_SIZE` (default: 10) | 30s | 5s |
| Read-only | Deal queries, taxonomy lookups | Configurable via `APP_POOL_SIZE` (default: 10) | 30s | 5s |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Taxonomy groups | in-memory (node-cache) | Caches taxonomy group lists per country | 24 hours |
| Primary deal services | in-memory (node-cache) | Caches PDS lists per country | 24 hours |
| Config | in-memory (node-cache) | Caches runtime configuration values | 10 minutes |
| Excluded users | in-memory (node-cache) | Caches developer user IDs for analytics exclusion | 24 hours |

## Data Flows

1. **n8n workflows** pull data on a schedule from Salesforce (accounts, opportunities), EDW (reviews, historical deals), and DeepScout S3 (competitor data mapped to Groupon taxonomy). Enriched datasets are bulk-written into the core tables.
2. The `refresh_deals_cache()` function is called to rebuild the materialized view, which joins accounts, opportunities, deal_details, redemption_locations, and prospects into a denormalized view with spatial indexing.
3. The **Express API** reads from the materialized view via the read-only pool for deal queries, and writes usage events directly to the `usage_events` table via the primary pool.
4. **Database migrations** are managed by dbmate with sequential numbered SQL files in `apps/coffee-api/db/migrations/`.

---
service: "email_campaign_management"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCampaignManagementPostgres"
    type: "postgresql"
    purpose: "Primary durable store for campaigns, programs, deal queries, sends, event types, and business groups"
  - id: "continuumCampaignManagementRedis"
    type: "redis"
    purpose: "Deal query metadata cache and request-scoped caching"
---

# Data Stores

## Overview

CampaignManagement uses two owned data stores: a PostgreSQL database as the primary durable store for all campaign-domain entities, and a Redis cache for deal query metadata to reduce database round-trips on high-frequency audience resolution reads. There is no shared database with other services; both stores are owned exclusively by this service.

## Stores

### CampaignManagement PostgreSQL (`continuumCampaignManagementPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCampaignManagementPostgres` |
| Purpose | Primary read/write and read-only datastore for all campaign-domain entities |
| Ownership | owned |
| Migrations path | `> No evidence found — migration path not discoverable from architecture inventory` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `campaigns` | Stores campaign definitions, metadata, status, and template configuration | id, name, status, program_id, business_group_id, template |
| `campaign_sends` | Tracks individual campaign send attempts and their statuses | id, campaign_id, status, sent_at, audience_size |
| `programs` | Program definitions that group campaigns for send routing and prioritization | id, name, priority, business_group_id |
| `deal_queries` | Audience targeting rule sets used to resolve eligible deal/user combinations | id, campaign_id, query_definition, division |
| `event_types` | Catalog of campaign event type taxonomy entries | id, name, description |
| `business_groups` | Business group definitions that scope campaign and program associations | id, name, config |

#### Access Patterns

- **Read**: Campaign orchestration reads campaign metadata and deal query definitions on every send-resolution request; audience resolution reads send state and deal query state; program management reads program priority ordering.
- **Write**: Campaign creation and update write to `campaigns`; send execution writes send records to `campaign_sends`; archival updates status flags; program management writes program entity state.
- **Indexes**: `> No evidence found — specific index definitions not visible from architecture inventory.`

### CampaignManagement Redis Cache (`continuumCampaignManagementRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumCampaignManagementRedis` |
| Purpose | In-memory cache for deal query metadata and request-scoped caching |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deal query metadata | Cached deal query definitions to avoid repeated PostgreSQL reads during audience resolution | campaign_id, deal_query_id, resolved_divisions |

#### Access Patterns

- **Read**: `cmAudienceResolution` and `cmCampaignOrchestration` read cached deal query metadata on send-resolution and preflight requests.
- **Write**: Written on cache miss after PostgreSQL read; invalidated on deal query create/update/archive.
- **Indexes**: Not applicable — key-value store.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCampaignManagementRedis` | redis | Deal query metadata and request-scoped caching | `> No evidence found` |

## Data Flows

PostgreSQL is the system of record. Redis serves as a read-through cache layered in front of PostgreSQL for deal query metadata. On a cache miss, `cmPersistenceAdapters` reads from PostgreSQL and populates the Redis cache. Writes to campaign/deal query entities invalidate or bypass the cache. There is no CDC, ETL pipeline, or materialized view between the two stores.

Deal assignment files are ingested from Google Cloud Storage (and archived to HDFS) as part of the campaign send execution flow, but GCS/HDFS are not owned data stores — they are transient sources read by `cmIntegrationClients`.

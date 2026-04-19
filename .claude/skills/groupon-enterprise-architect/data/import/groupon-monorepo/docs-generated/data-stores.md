---
service: "groupon-monorepo"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "deal"
    type: "postgresql"
    purpose: "Deal lifecycle data"
  - id: "accounts"
    type: "postgresql"
    purpose: "Merchant accounts"
  - id: "brands"
    type: "postgresql"
    purpose: "Brand data and metrics"
  - id: "custom_fields"
    type: "postgresql"
    purpose: "Custom field definitions and values"
  - id: "tagging"
    type: "postgresql"
    purpose: "Entity tagging"
  - id: "faq"
    type: "postgresql"
    purpose: "FAQ entries"
  - id: "reports"
    type: "postgresql"
    purpose: "Report definitions and results"
  - id: "notifications"
    type: "postgresql"
    purpose: "Notification records"
  - id: "workflows"
    type: "postgresql"
    purpose: "Workflow registrations"
  - id: "video"
    type: "postgresql"
    purpose: "Video metadata"
  - id: "images"
    type: "postgresql"
    purpose: "Image metadata"
  - id: "deal_sync"
    type: "postgresql"
    purpose: "Deal synchronization state"
  - id: "deal_reviews"
    type: "postgresql"
    purpose: "Deal review aggregations"
  - id: "partner_order_sync"
    type: "postgresql"
    purpose: "Partner order sync state"
  - id: "checkoutDb"
    type: "postgresql"
    purpose: "Checkout event records"
  - id: "redis"
    type: "redis"
    purpose: "Caching and session data"
  - id: "mongodb"
    type: "mongodb"
    purpose: "AIDG document storage"
---

# Data Stores

## Overview

The Encore Platform follows a database-per-service pattern using Encore's managed PostgreSQL databases. Each service that requires persistent state declares its own `SQLDatabase` instance with Drizzle ORM for schema management and migrations. Redis is used as a shared caching layer (primarily for deal data enrichment and session state). MongoDB is used by the AIDG service for flexible document storage. BigQuery and Teradata EDW serve as read-only analytics stores accessed through proxy services.

## Stores

### Deal Database (`deal`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Deal lifecycle data: versions, options, pricing, redemption, publishing state |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/deal/db/migrations/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| deals | Core deal records | id, uuid, title, status, division |
| deal_versions | Version history with approval workflow | id, deal_id, version, status, approved_by |
| deal_options | Pricing options per deal | id, deal_id, price, value, quantity |

#### Access Patterns

- **Read**: Deal listing with pagination/filtering, single deal lookup by ID/UUID, version history
- **Write**: Deal creation, version updates, option modifications, status transitions
- **Indexes**: Primary key, UUID unique, status + division composite for listing queries

### Accounts Database (`accounts`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Merchant account records with Salesforce sync state |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/accounts/db/migrations/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| accounts | Merchant account master records | id, salesforce_id, name, status |
| account_deals_structured_data | Denormalized deal data per account | account_id, deal_count, metrics |

#### Access Patterns

- **Read**: Account lookup by ID or Salesforce ID, listing with search
- **Write**: Account creation, Salesforce sync updates, metrics recalculation
- **Indexes**: salesforce_id unique, name search index

### Brands Database (`brands`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Brand records and computed metrics |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/brands/db/migrations/` |

### Custom Fields Database (`custom_fields`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Custom field definitions, schemas, and values |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/custom-fields/db/migrations/` |

### Tagging Database (`tagging`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Entity tagging and bulk tagging job tracking |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/tagging/db/migrations/` |

### FAQ Database (`faq`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | FAQ entries and categories |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/faq/db/migrations/` |

### Reports Database (`reports`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Report definitions, queries, and cached results |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/reports/db/migrations/` |

### Notifications Database (`notifications`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Notification records and delivery status |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_core_system/notifications/db/migrations/` |

### Workflows Database (`workflows`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Temporal workflow registrations and execution metadata |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_core_system/workflow_management/db/migrations/` |

### Video Database (`video`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Video upload metadata and Mux asset references |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_core_system/video/db/migrations/` |

### Images Database (`images`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Image upload metadata and processing status |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_core_system/images/db/migrations/` |

### Deal Sync Database (`deal_sync`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Deal synchronization state and Continuum DMAPI mapping |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2b/deal_sync/db/migrations/` |

### Deal Reviews Database (`deal_reviews`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Deal review aggregations, dimension scores, UGC answers |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_b2c/deal-reviews/db/deal-reviews/migrations/` |

### Partner Order Sync Database (`partner_order_sync`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Partner order synchronization tracking |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_marketing/partner_order_sync_service/db/migrations/` |

### Checkout Events Database (`checkoutDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (Encore-managed) |
| Architecture ref | `encoreTs` |
| Purpose | Janus tier-3 checkout event records |
| Ownership | owned |
| Migrations path | `apps/encore-ts/services/_tribe_core/checkout-events/db/migrations/` |

### AIDG MongoDB

| Property | Value |
|----------|-------|
| Type | MongoDB |
| Architecture ref | `encoreTs` |
| Purpose | AIDG service document storage (merchant data, AI inference results) |
| Ownership | owned |
| Migrations path | Schema-less (Mongoose models) |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis (shared) | Redis (ioredis) | Deal data enrichment cache, session state, AI agent state | Configurable per service |
| Redis (Go) | Redis (go-redis) | Deal data provider cache for gorapi/lrapi search results | Configurable (DealDataProvider TTL) |
| node-cache | In-memory | Local ephemeral caching within individual TS services | Short-lived |

## Data Flows

- **Salesforce Sync**: Bidirectional sync between `accounts` PostgreSQL and Salesforce CRM via jsforce client. Account updates trigger Pub/Sub events (`account-updated-in-salesforce`, `account-updated-internal`).
- **Deal Sync to Continuum**: Deal data flows from `deal` PostgreSQL through `deal_sync` service to Continuum DMAPI. Sync state tracked in `deal_sync` database.
- **Checkout Event Pipeline**: Kafka messages from Continuum Janus topic are consumed by the kafka bridge service, published to Encore Pub/Sub (`kafka-janus-tier3`), and persisted to `checkoutDb` PostgreSQL.
- **Deal Data Enrichment (Go)**: The Go `DealDataProvider` reads from Redis cache first; on cache miss, it fetches from Continuum Lazlo API and backfills the cache.
- **BigQuery Analytics**: Read-only queries are proxied through the `big-query` service to Google BigQuery for analytics dashboards and deal alert calculations.
- **Teradata EDW**: Read-only analytics proxy through `terradata_proxy` service for legacy reporting.
- **AIDG AI Pipeline**: AI inference results from Python microservices are stored in MongoDB via the AIDG service, with Salesforce data enrichment flowing through Pub/Sub topics.

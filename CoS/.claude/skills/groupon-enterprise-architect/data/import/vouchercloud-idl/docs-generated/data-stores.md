---
service: "vouchercloud-idl"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumVcMongoDb"
    type: "mongodb"
    purpose: "Primary document store for offers, merchants, categories, and content"
  - id: "continuumVcSqlDb"
    type: "sqlserver"
    purpose: "Relational store for user sessions, affiliate data, sync queues"
  - id: "continuumVcRedisCache"
    type: "redis"
    purpose: "Response caching and session store"
---

# Data Stores

## Overview

Vouchercloud IDL uses three data stores: MongoDB as the primary document store for offer and merchant content, SQL Server for relational data including user sessions and affiliate tracking, and Redis for response caching and session persistence. All three are accessed by both `continuumVcApi` and `continuumRestfulApi`. Credentials are injected at runtime via AWS Secrets Manager — no connection strings are committed to source.

## Stores

### Vouchercloud MongoDB (`continuumVcMongoDb`)

| Property | Value |
|----------|-------|
| Type | mongodb |
| Architecture ref | `continuumVcMongoDb` |
| Purpose | Primary document store for offers, merchants, categories, and content |
| Ownership | owned |
| Migrations path | > No evidence found in codebase of a migrations directory |

#### Key Entities

| Entity / Collection | Purpose | Key Fields |
|---------------------|---------|-----------|
| Offers | Offer documents including title, discount, expiry, merchant ref, affiliate links | offerId, merchantId, countryCode, categoryId, expiryDate, offerType, affiliateUrl |
| Merchants | Merchant profile documents with branch details | merchantId, name, countryCode, categories, branches, logoUrl |
| Categories | Category hierarchy for offers and merchants | categoryId, parentId, name, slug, countryCode |
| Emails | Email template content for newsletter campaigns | emailId, countryCode, templateType, offerRefs |
| Competitions | Competition documents and entry tracking | competitionId, countryCode, expiryDate |

#### Access Patterns

- **Read**: High-frequency reads for offer listings, merchant lookups, category trees; cached in Redis with configurable TTLs. Slow query threshold logged at 300ms (`SlowMongoQueryThresholdInMilliseconds=300`).
- **Write**: Offer and merchant writes via internal admin/ControlCloud API and sync queue mechanism; community code submissions write back to offer documents.
- **Indexes**: Not directly visible in this repo; managed at the MongoDB Atlas/server level.

---

### Vouchercloud SQL (`continuumVcSqlDb`)

| Property | Value |
|----------|-------|
| Type | sqlserver |
| Architecture ref | `continuumVcSqlDb` |
| Purpose | Relational store for user sessions, affiliate click data, sync queues, and user account data |
| Ownership | owned |
| Migrations path | > No evidence found in codebase of a migrations directory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| UserAuth | User authentication records (email/password) | userId, email, passwordHash, createdDate |
| Sessions | ServiceStack session persistence | sessionId, userId, expiresAt |
| AffiliateClicks | Affiliate click and tracking data | clickId, offerId, userId, affiliateNetwork, timestamp |
| AffiliatePurchases | Affiliate purchase attribution | purchaseId, clickId, transactionValue, status |
| MerchantSyncQueue | Merchant sync job queue | jobId, merchantId, status, acquiredAt, lockedUntil |
| UserClosedLoopOffers | Closed-loop offer assignments per user | userId, offerId, assignedDate |

#### Access Patterns

- **Read**: Session lookups on every authenticated request (via `ISqlBackedCacheClient`); user auth queries on login.
- **Write**: Session creation/update on auth; affiliate click inserts on outlink redirect; sync queue state transitions (insert/acquire/resolve/fail).
- **Indexes**: Not directly visible; managed at SQL Server level.

---

### Vouchercloud SQL (Affiliate DB) (`continuumVcSqlDb` — affiliate connection)

| Property | Value |
|----------|-------|
| Type | sqlserver |
| Architecture ref | `continuumVcSqlDb` |
| Purpose | Separate affiliate data store (separate credentials: `VCAPI-SQLAffiliate-{env}`) |
| Ownership | owned |
| Migrations path | > No evidence found in codebase |

> Note: The release environment variables script reveals two separate SQL credential sets: `VCAPI-SQL-{env}` for the main database and `VCAPI-SQLAffiliate-{env}` for a dedicated affiliate database. These are logical separations within the `continuumVcSqlDb` architecture node.

---

### Vouchercloud Redis (`continuumVcRedisCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumVcRedisCache` |
| Purpose | API response caching and user session persistence |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Cache-aside pattern; all major API responses (offers, merchants, categories, emails) are read from Redis before hitting MongoDB.
- **Write**: Cache population after MongoDB reads; session creation/update on auth.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumVcRedisCache` | redis | Offer/merchant/category response cache; user session store | Varies: 30 min for email responses (`CacheDuration.Minutes_30_TimeSpan`), 24 h for Genie feed (`CacheDuration.Hours_24_TimeSpan`) |

## Data Flows

1. Consumer request arrives at `continuumRestfulApi`.
2. Service checks Redis cache (`continuumVcRedisCache`) for cached response.
3. On cache miss, service queries MongoDB (`continuumVcMongoDb`) for content (offers, merchants, categories).
4. Session and affiliate data is read/written from SQL Server (`continuumVcSqlDb`).
5. Populated response is written back to Redis cache.
6. Async: user interaction events are published to AWS SQS for downstream analytics pipeline.

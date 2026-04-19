---
service: "ugc-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumUgcPostgresPrimary"
    type: "postgresql"
    purpose: "Primary transactional store for all UGC data"
  - id: "continuumUgcPostgresReadReplica"
    type: "postgresql"
    purpose: "Read-only replica for high-volume read queries"
  - id: "continuumUgcRedis"
    type: "redis"
    purpose: "Rate limiting and transient cache keys"
  - id: "continuumUgcRedisCache"
    type: "redis"
    purpose: "Read-heavy lookup cache"
  - id: "continuumUgcS3"
    type: "s3"
    purpose: "Object storage for UGC images and videos"
---

# Data Stores

## Overview

The UGC API owns five data stores: a primary PostgreSQL database for all transactional UGC writes, a read replica for high-volume read traffic, two Redis instances (one for rate limiting and transient state, one for read-heavy caching), and Amazon S3 buckets for media (images and videos). Schema migrations are managed by JTier's migration framework (`jtier-migrations`, Flyway-based), with migrations residing at `db/migration/` (excluded from JaCoCo coverage). JDBI with RosettaJdbi is used for all relational data access.

## Stores

### UGC Postgres (Primary) (`continuumUgcPostgresPrimary`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumUgcPostgresPrimary` |
| Purpose | Primary transactional database — all UGC writes and authoritative reads |
| Ownership | owned |
| Migrations path | `db/migration/` (Flyway via `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Answers | Stores customer reviews, ratings, and Q&A content | answer_id (UUID), consumer_id, merchant_id, place_id, deal_id, rating, content, status, created_at |
| Answer Actions | Records helpfulness votes, likes, dislikes, and flags on answers | id, answer_id, user_id, action_type, created_at |
| Answer Replies | Stores merchant or admin replies to answers | id, answer_id, user_id, user_type, content, created_at |
| Images | Tracks user-submitted images linked to merchants, places, deals | id (UUID), user_id, merchant_id, place_id, deal_id, url, status, created_at |
| Videos | Tracks user-submitted and influencer videos | id (UUID), user_id, merchant_id, deal_id, url, status, created_at |
| Surveys | Survey definitions with questions and dispatch configurations | id (UUID), survey_key, groupon_code, voucher_id, status, version, created_at |
| Survey Replies | Submitted responses to survey questions | id, survey_id, consumer_id, content, created_at |
| Content Opt-Out | Records entities opted out of content display | ref_id, entity_type, created_at |

#### Access Patterns

- **Read**: Paginated queries on answers/images/videos by merchant, place, deal, or user ID with optional date-range, aspect, and status filters; ordered by time, value, helpfulness, or sentiment
- **Write**: Single-row inserts for new answers, images, videos, survey replies; status updates for moderation actions; bulk deletes for user GDPR removal and survey purge
- **Indexes**: Not directly visible from source; inferred indexes on `merchant_id`, `place_id`, `deal_id`, `consumer_id`, and `status` columns based on query filter patterns

### UGC Postgres (Read Replica) (`continuumUgcPostgresReadReplica`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumUgcPostgresReadReplica` |
| Purpose | Read-only replica for high-volume consumer-facing read traffic |
| Ownership | owned (replica of primary) |
| Migrations path | Managed by PostgreSQL replication; no independent migrations |

#### Access Patterns

- **Read**: All high-volume read queries for consumer-facing endpoints (merchant reviews, place reviews, image listings, video listings) route to the read replica to reduce primary load
- **Write**: Not applicable — read-only

### UGC Redis (`continuumUgcRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumUgcRedis` |
| Purpose | Rate limiting on submission endpoints; transient cache keys |
| Ownership | owned |
| Migrations path | Not applicable |

### UGC Redis Cache (`continuumUgcRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumUgcRedisCache` |
| Purpose | Read-heavy lookup cache for aggregated review summaries and merchant data |
| Ownership | owned |
| Migrations path | Not applicable |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumUgcRedis` | Redis (Jedis / dropwizard-redis) | Rate limiting counters and transient session keys for submission endpoints | Short-lived (TTL not specified in source) |
| `continuumUgcRedisCache` | Redis (Jedis / dropwizard-redis) | Cached merchant review summaries and aggregated ratings for read-heavy lookups | TTL not specified in source |

## Data Flows

- All write operations (answer submission, image/video actions, survey replies) hit `continuumUgcPostgresPrimary` exclusively.
- Read operations for consumer-facing endpoints are routed to `continuumUgcPostgresReadReplica` to reduce primary load.
- After successful writes, events are published to `continuumUgcMessageBus` (JMS/ActiveMQ) to notify downstream consumers.
- Media upload flows generate pre-signed S3 URLs; client browsers upload directly to `continuumUgcS3`. UGC API stores the resulting object URL in PostgreSQL.
- Review summaries are cached in `continuumUgcRedisCache` and served from cache on read paths; cache is invalidated or expired when new answers are submitted.

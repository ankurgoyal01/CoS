---
service: "ugc-async"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumUgcPostgresDb"
    type: "postgresql"
    purpose: "Primary UGC data store — surveys, answers, dispatch records, aggregated ratings, images, reviews"
  - id: "continuumUgcRedisCache"
    type: "redis"
    purpose: "Coordination cache — job state, deduplication keys, URL caching"
  - id: "ugcTeradataWarehouse_6b9d"
    type: "teradata"
    purpose: "Goods redemption data source for survey creation batch jobs"
  - id: "aws-s3-image-bucket"
    type: "s3"
    purpose: "Staging bucket for customer-uploaded images and videos before ingestion"
---

# Data Stores

## Overview

ugc-async uses four data stores: a primary PostgreSQL database owned by the UGC domain for all survey and content state, a Redis cache for job coordination and deduplication, a Teradata warehouse as a read-only source for Goods survey creation batch jobs, and an AWS S3 bucket as a temporary staging area for customer-uploaded media before it is pushed to the Image Service.

## Stores

### UGC Postgres (`continuumUgcPostgresDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumUgcPostgresDb` |
| Purpose | Stores surveys, answers, dispatch records, aggregated ratings, images, reviews, and Quartz job metadata |
| Ownership | owned |
| Migrations path | Managed by `jtier-migrations` (exact path not exposed in repo root) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `surveys` | Survey records created per user/deal/order | survey_id, user_id, deal_id, merchant_id, place_id, event_type, status, locale |
| `answers` | User-submitted answers to survey questions | answer_id, survey_id, question_id, question_type, masked_name, rating |
| `dispatch_records` | Tracks notification send attempts (email, push, inbox) per survey | survey_id, medium, outcome, sent_at |
| `aggregated_ratings` | Aggregated rating summaries per place/merchant | id, place_id, merchant_id, aspect_information (JSON), treatment_id |
| `images` | Image records linking S3 keys to surveys | id, survey_id, s3_key, image_url, status, merchant_id, deal_id, place_id, user_id |
| `reviews` | Extracted review text records | review_id, survey_id, merchant_id, deal_id |
| `content_opt_outs` | Records of merchants/users who have opted out of surveys | entity_id, entity_type |
| `deal_aggregated_content` | Aggregated content counts per deal | deal_id, content counts |
| Quartz tables | Quartz scheduler state (triggers, jobs, fired triggers) | Managed by `jtier-quartz-bundle` |

#### Access Patterns

- **Read**: Surveys fetched in batches for sending jobs (by status, medium, locale, event type); aggregated ratings read by place/merchant context; images read by S3 key; answers read by survey ID
- **Write**: Survey creation (insert), answer upsert, dispatch record creation on notification send, aggregated rating update (aspect information JSON column replaced), image status updates after S3 migration
- **Indexes**: Not directly visible in source; access via JDBI DAOs in `ugc-common`

### UGC Redis Cache (`continuumUgcRedisCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumUgcRedisCache` |
| Purpose | Job state tracking, Quartz job coordination, and deduplication |
| Ownership | shared (with ugc-common consumers) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `berlinGoodsRedemptionImport` | Stores the last-processed timestamp for Goods survey creation job | key=job name, value=epoch millis |
| Job deduplication keys | Prevents concurrent Quartz executions via `RedisClient` coordination | key=job name |

#### Access Patterns

- **Read**: Job start-time checkpoint reads before each Teradata survey creation run
- **Write**: Checkpoint updates after successful Teradata batch processing; lock acquisition for single-instance job execution

### UGC Teradata Warehouse (`ugcTeradataWarehouse_6b9d`)

| Property | Value |
|----------|-------|
| Type | teradata |
| Architecture ref | `ugcTeradataWarehouse_6b9d` |
| Purpose | Read-only source for Goods redemption data used to identify users eligible for survey creation |
| Ownership | external (read-only) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Goods redemption import table | Redemption records for Goods deals from which surveys are created; table name configurable via `clonedDealTeradataTable` config | order_id, deal_id, user_id, redemption_timestamp |

#### Access Patterns

- **Read**: Batch SELECT queries executed by `GoodsSurveyCreationJob` and `GoodsInstantSurveyCreationJob` using a time-window (start from Redis checkpoint, end = now minus 36 hours)
- **Write**: None (read-only)

### AWS S3 Image/Video Staging Bucket (`aws-s3-image-bucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | Not in federated Structurizr model |
| Purpose | Temporary staging area for customer-uploaded images and influencer/customer videos before ingestion to Image Service |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Image objects | Mobile-uploaded survey images staged before Image Service ingestion | S3 key: `{surveyId}_{questionId}` |
| Customer video objects | Customer-uploaded video files (MP4) | S3 key pattern includes `video/` prefix |
| Influencer video objects | Influencer content video files | Separate S3 bucket path |

#### Access Patterns

- **Read**: `S3ImageMoverHelper` lists all objects in the image bucket, filters by content type (excludes video), downloads bytes for upload to Image Service
- **Write**: Objects deleted from S3 after successful transfer to Image Service; image records saved in Postgres with `image_url` from Image Service response

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumUgcRedisCache` | redis | Job coordination, deduplication, checkpoint storage | No fixed TTL observed in source |

## Data Flows

- Survey creation events arrive via MBus or Teradata batch; surveys are written to `continuumUgcPostgresDb`
- Survey sending jobs read pending surveys from Postgres, check eligibility (including Redis deduplication), dispatch via Rocketman/CRM, and write dispatch records back to Postgres
- Customer images land in S3; `S3ImageMoverJob` (Quartz-scheduled) reads from S3, posts to Image Service, updates Postgres image records, then deletes from S3
- Essence NLP events arrive via MBus; `EssenceListenerService` merges aspect data and writes updated `aspect_information` JSON column to aggregated rating rows in Postgres

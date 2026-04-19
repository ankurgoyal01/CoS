---
service: "user-behavior-collector"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for User Behavior Collector.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Spark Event Ingestion](spark-event-ingestion.md) | batch | Daily cron (`update_deal_views`) | Reads Janus Kafka parquet files from HDFS/GCS, classifies raw events (deal views, purchases, searches, ratings, email opens) via Spark, and persists results to HDFS and PostgreSQL |
| [Deal Info Refresh](deal-info-refresh.md) | batch | Daily cron (`update_deal_views`) | Fetches enriched deal metadata from GAPI and Deal Catalog, checks inventory via VIS, and writes results to Redis and PostgreSQL |
| [Audience Publishing](audience-publishing.md) | scheduled | Daily cron (`publish_audience`) | Reads segmented audience records from PostgreSQL, generates per-country CSV files, uploads to Cerebro HDFS, and notifies Audience Management Service |
| [Wishlist Update](wishlist-update.md) | scheduled | Daily cron (`update_wishlist`) | Reads consumers with recent deal views from PostgreSQL, fetches current wishlists from the Wishlist Service, and persists updated wishlist flags |
| [Back-in-Stock Update](back-in-stock-update.md) | batch | Daily cron (`update_deal_views`) | Queries sold-out deal options from PostgreSQL, checks VIS for re-availability, and writes back-in-stock status updates |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

All five flows span multiple services. The primary cross-service flows are:

- **Spark Event Ingestion** spans: `janusKafkaEventFiles_3b6f` (HDFS/GCS) → `continuumUserBehaviorCollectorJob` → `gdoopHadoopCluster_8d2c` (YARN) → `continuumDealViewNotificationDb`
- **Audience Publishing** spans: `continuumUserBehaviorCollectorJob` → Cerebro HDFS → `audienceService_d1f2` (AMS)
- **Deal Info Refresh** spans: `continuumUserBehaviorCollectorJob` → `gapiService_5c1a` + `continuumDealCatalogService` + `visInventoryService_f4b0` → `continuumDealInfoRedis`

See [Architecture Context](../architecture-context.md) for C4 container relationships.

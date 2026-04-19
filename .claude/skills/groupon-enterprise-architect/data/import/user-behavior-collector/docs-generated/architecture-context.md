---
service: "user-behavior-collector"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUserBehaviorCollectorJob, continuumDealViewNotificationDb, continuumDealInfoRedis]
---

# Architecture Context

## System Context

User Behavior Collector is a batch-processing component of the Continuum Platform (`continuumSystem`). It runs on a schedule, reads Janus analytics event files from the Groupon Hadoop/GCS data platform (gdoop), processes them with Apache Spark on YARN, and writes results into its own PostgreSQL database. It integrates with several other Continuum services to enrich and publish data, and outputs segmented audience files to the Cerebro HDFS cluster for downstream notification pipelines. No external systems call into this job; it is entirely outbound in its integration pattern.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| User Behavior Collector Job | `continuumUserBehaviorCollectorJob` | Batch Job | Java, Spark (YARN) | 1.6.62 | Main batch executable: orchestrates Spark event processing, deal info refresh, wishlist updates, audience publishing, and metrics emission |
| Deal View Notification DB | `continuumDealViewNotificationDb` | Database | PostgreSQL | — | Stores deal views, purchases, searches, ratings, email opens, wishlist flags, audience data, and key-value state (e.g., Kafka file pointer) |
| Deal Info Redis | `continuumDealInfoRedis` | Cache | Redis | — | Cache for deal info objects and adult category IDs written by the Deal Info Refresher component |

## Components by Container

### User Behavior Collector Job (`continuumUserBehaviorCollectorJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Orchestrator | Main entry point; parses CLI arguments; sequences batch steps; controls skip flags (`-skipUpdateHistoryData`, `-skipPublishAudience`, `-skipUpdateWishList`, `-skipViewPurchase`) | Java |
| Spark Pipeline | Reads Janus Kafka parquet files from HDFS/GCS; parses raw events into typed RDDs (`DealViewInfo`, `DealPurchaseInfo`, `UserSearchInfo`, `UserRatingData`, `EmailOpenInfo`); writes intermediate results to HDFS | Apache Spark (YARN) |
| Data Access Layer | JDBC/Hibernate access to `deal_view_notification` PostgreSQL database; persists and queries all behavior records, audience info, and key-value state | JDBC, Hibernate |
| Audience Publisher | Reads audience data from PostgreSQL; generates per-country CSV files; uploads to Cerebro HDFS; calls Audience Management Service REST API | Java |
| Wishlist Updater | Fetches consumer deal-view records from DB; queries Wishlist Service per consumer; persists wishlist flags back to DB | Java |
| Deal Info Refresher | Fetches deal metadata from GAPI and Deal Catalog; checks inventory via VIS; caches enriched deal objects in Redis | Java |
| Back-in-Stock Updater | Queries sold-out deal options from DB; checks VIS for re-availability; writes back-in-stock status | Java |
| Metrics Reporter | Publishes HTTP response counters and job counters to InfluxDB via Telegraf endpoint | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUserBehaviorCollectorJob` | `continuumDealViewNotificationDb` | Reads and writes audience and behavior data | JDBC / Hibernate |
| `continuumUserBehaviorCollectorJob` | `continuumDealInfoRedis` | Writes deal info cache | Redis (Jedis) |
| `continuumUserBehaviorCollectorJob` | `continuumDealCatalogService` | Fetches deal catalog data | REST (Retrofit/OkHttp) |
| `continuumUserBehaviorCollectorJob` | `continuumTaxonomyService` | Fetches taxonomy metadata | REST |
| `continuumUserBehaviorCollectorJob` | `continuumWishlistService` | Fetches wishlist data per consumer | REST (OkHttp) |
| `continuumUserBehaviorCollectorJob` | `janusKafkaEventFiles_3b6f` | Reads Janus event files (stub — not in federated model) | HDFS / GCS (Parquet) |
| `continuumUserBehaviorCollectorJob` | `gdoopHadoopCluster_8d2c` | Reads files via HDFS/GCS (stub — not in federated model) | HDFS |
| `continuumUserBehaviorCollectorJob` | `gapiService_5c1a` | Fetches deal data (stub — not in federated model) | REST |
| `continuumUserBehaviorCollectorJob` | `audienceService_d1f2` | Publishes audiences (stub — not in federated model) | REST |
| `continuumUserBehaviorCollectorJob` | `tokenService_e9a1` | Queries device tokens (stub — not in federated model) | REST |
| `continuumUserBehaviorCollectorJob` | `visInventoryService_f4b0` | Checks voucher inventory (stub — not in federated model) | REST |
| `continuumUserBehaviorCollectorJob` | `telegrafInfluxEndpoint_2a7e` | Publishes metrics (stub — not in federated model) | InfluxDB line protocol |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumUserBehaviorCollectorJob`
- Component: `continuumUserBehaviorCollectorJob-components`

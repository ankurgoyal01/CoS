---
service: "user-behavior-collector"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Emerging Channels / Triggered Notifications"
platform: "Continuum"
team: "Emerging Channels"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# User Behavior Collector Overview

## Purpose

User Behavior Collector is a scheduled batch job that ingests raw Janus Kafka event files from HDFS/GCS, processes them with Apache Spark on YARN, and persists structured user-behavior records (deal views, purchases, searches, ratings, email opens) to a PostgreSQL database. It also refreshes deal metadata in Redis, synchronizes wishlist state, and publishes segmented user audiences (by behavior type and country) to downstream audience management systems that feed triggered email and push notification campaigns.

## Scope

### In scope

- Reading Janus Kafka event parquet files from HDFS/GCS using Spark
- Parsing and classifying raw events: `dealView`, `dealPurchase`, `search` (mobile and web), `userDealRating`, `emailOpenHeader`
- Batch-persisting classified event records to the `deal_view_notification` PostgreSQL database
- Refreshing deal metadata (including availability, inventory, and options) from GAPI and Deal Catalog, caching results in Redis
- Updating wishlist flags per consumer by querying the Wishlist Service
- Identifying back-in-stock deals via VIS (Voucher Inventory Service) and persisting updates
- Publishing segmented audience CSV files per country to Cerebro HDFS and notifying the Audience Management Service
- Cleaning up aged sendlogs, email-open records, and audience files
- Emitting operational metrics to InfluxDB via Telegraf
- Sending job result and failure alert emails to the Emerging Channels team and PagerDuty

### Out of scope

- Real-time event streaming (partially migrated to realtime pipeline; `-skipViewPurchase` flag used post-migration)
- Serving HTTP API requests to external consumers (no web server; job-only process)
- Sending the triggered notifications themselves (handled by downstream notification services)
- Deal creation or merchant operations

## Domain Context

- **Business domain**: Emerging Channels / Triggered Notifications
- **Platform**: Continuum
- **Upstream consumers**: Downstream audience management and notification systems consume the published audience CSV files; no services call this job's API directly
- **Downstream dependencies**: Janus Kafka event files (HDFS/GCS), GAPI (deal data), Deal Catalog Service, Taxonomy Service, Wishlist Service, VIS (Voucher Inventory Service), Audience Management Service (Cerebro/AMS), Token Service, PostgreSQL (`deal_view_notification` DB), Redis (deal info cache), Telegraf/InfluxDB (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Emerging Channels Team | Owns and operates the service; receives job result and failure alert emails |
| PagerDuty On-Call | Receives pager alerts when batch job fails (`targeted-deal-message@groupon.pagerduty.com`) |
| Notification / Audience Consumers | Downstream systems that consume the published audience segments for campaign targeting |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` (`project.build.targetJdk=1.8`), `.java-version` |
| Framework | Apache Spark | 2.4.8 | `pom.xml` (`spark-core_2.12`, `spark-sql_2.12`) |
| Runtime | JVM | 1.8 | `.ci.yml` (`language_versions: 1.8.0_11`) |
| Build tool | Maven | (basepom v8) | `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core_2.12` | 2.4.8 | message-client / batch | Distributed processing of Kafka event parquet files on YARN |
| `spark-sql_2.12` | 2.4.8 | batch | SQL and DataFrame API for Spark jobs |
| `hadoop-common` | 2.7.2 | db-client | HDFS filesystem access for reading Kafka files and writing audience outputs |
| `hadoop-hdfs` | 2.7.2 | db-client | HDFS distributed filesystem client |
| `postgresql` | 42.7.3 | db-client | PostgreSQL JDBC driver for `deal_view_notification` database |
| `hibernate-entitymanager` | 5.1.0.Final | orm | JPA/Hibernate ORM for transactional database writes |
| `jdbi` | 2.71 | db-client | Lightweight JDBC wrapper for read-only and batch SQL queries |
| `jedis` | 2.9.0 | db-client | Redis client for deal info cache writes |
| `retrofit` | 2.3.0 | http-framework | Type-safe HTTP client for GAPI, VIS, and other REST calls |
| `okhttp3` | 3.8.0 | http-framework | HTTP client with logging interceptor; backing retrofit and custom SSL clients |
| `metrics-sma-influxdb` | 5.7.2 | metrics | Groupon internal InfluxDB metrics publisher (via Telegraf) |
| `steno` | 0.2.0 | logging | Groupon structured JSON logging library |
| `failsafe` | 2.3.1 | validation | Retry and circuit-breaker utility for audience API calls |
| `app-config` | 1.8.0 | validation | Groupon internal application configuration loader |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.

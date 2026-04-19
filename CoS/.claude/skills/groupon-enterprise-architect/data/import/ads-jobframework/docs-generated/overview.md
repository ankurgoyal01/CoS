---
service: "ads-jobframework"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Ads / Sponsored Listings"
platform: "Continuum"
team: "ads-eng@groupon.com"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.8"
  framework: "Apache Spark"
  framework_version: "2.4.0"
  runtime: "JVM / YARN"
  runtime_version: "Java 21"
  build_tool: "sbt"
  package_manager: "ivy2 / Groupon Artifactory"
---

# Ads Job Framework Overview

## Purpose

ads-jobframework is a Scala/Spark batch processing framework that powers all Groupon ads reporting, sponsored listing analytics, and third-party attribution integrations. It executes scheduled Spark jobs on YARN that query the Groupon Data Lake (Hive), compute impression/click/order metrics, and deliver data feeds to CitrusAd, ClarusAd/DoubleClick, and internal reporting tables. It also runs uplift-model inference to produce audience blocklists for ad targeting exclusion.

## Scope

### In scope
- Hourly CitrusAd impression and click reporting to `https://us-integration.citrusad.com`
- Daily order and customer data feed generation to GCS buckets for CitrusAd ingestion
- ClarusAd (DoubleClick) impression ping delivery to `https://ad.doubleclick.net`
- Sponsored listing click/impression aggregation into `ai_reporting.sl_imp_clicks`
- Page-view-with-impressions (PV) aggregation into `ai_reporting.pv_with_impressions`
- Search term keyword fetch and export for sponsored listing bid optimization
- ROAS-based max-CPC calculation and export for deal bid management
- Uplift model inference (Random Forest) and blocklist (`blocklist_rokt_desktop`) generation
- PPID audience export from Teradata to GCS for DFP targeting
- CitrusAd reconciliation reporting (over-report and under-report email alerts)

### Out of scope
- Real-time ad serving (handled by CitrusAd platform)
- Deal ranking and recommendation logic (separate ML services)
- Campaign management UI or API (handled by ad-inventory-service)
- Billing and invoicing for advertisers
- User attribute computation (sourced from `cia_realtime` tables owned by other services)
- Transaction processing (sourced from `user_edwprod.fact_gbl_transactions`, owned elsewhere)

## Domain Context

- **Business domain**: Ads / Sponsored Listings
- **Platform**: Continuum
- **Upstream consumers**: CitrusAd platform (receives impression/click callbacks and feed files from GCS), DoubleClick/Clarus (receives impression pixel pings), internal ad analytics dashboards (Wavefront) consuming `ai_reporting` Hive tables
- **Downstream dependencies**: Groupon Data Lake (`grp_gdoop_pde.junoHourly`, `user_edwprod.*`, `cia_realtime.*`, `grp_gdoop_marketing_analytics_db.*`, `prod_groupondw.*`), MySQL (`ads-job-framework-rw-na-production-db`), Teradata (`sandbox.ppid_export`), GCS (`grpn-dnd-prod-analytics-grp-ai-reporting`)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering Owner | dgundu — ads-eng@groupon.com |
| SRE / On-call | ai-engineering Slack channel (CF8G3HBBP); PagerDuty service PS4HL4Y; ad-inventory@groupon.pagerduty.com |
| Mailing List | ads-eng@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.8 | `build.sbt` |
| Framework | Apache Spark | 2.4.0 | `build.sbt` |
| Runtime | JVM / YARN | Java (cluster-provided) | `README.md` |
| Build tool | sbt | 1.x with sbt-assembly | `project/build.properties`, `assembly.sbt` |
| Package manager | ivy2 / Groupon Artifactory | — | `build.sbt` resolvers |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.groupon.cde:cde-jobframework` | 0.17.13 | scheduling | Groupon CDE job runner: YARN submit, config loading, Hive/Teradata connections, metrics hooks |
| `org.apache.spark:spark-core` | 2.4.0 | scheduling | Distributed computation engine |
| `org.apache.spark:spark-sql` | 2.4.0 | orm | Spark SQL / DataFrame API for Hive queries |
| `org.apache.spark:spark-mllib` | 2.4.0 | scheduling | Spark ML pipeline for uplift model inference (PipelineModel, RandomForest) |
| `org.apache.spark:spark-hive` | 2.4.0 | db-client | Hive metastore integration for reading/writing Hive tables |
| `org.scalaj:scalaj-http` | 2.4.0 | http-framework | HTTP client for CitrusAd and ClarusAd outbound API callbacks |
| `mysql:mysql-connector-java` | 5.1.47 | db-client | JDBC driver for MySQL ad inventory database |
| `com.teradata.jdbc:terajdbc4` | 16.10.00.07 | db-client | Teradata JDBC driver for PPID audience export |
| `com.groupon.jtier.metrics:metrics-sma-influxdb` | 0.9.1 | metrics | Spark job metrics publication to Telegraf/InfluxDB |
| `com.google.guava:guava` | 24.1.1-jre | validation | Utility library for hashing and collections |
| `org.scalatest:scalatest` | 3.0.5 | testing | Unit test framework |
| `com.fasterxml.jackson.core:jackson-databind` | 2.6.7.1 | serialization | JSON serialization (pinned override for Spark compatibility) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.

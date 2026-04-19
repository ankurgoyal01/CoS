---
service: "ads-jobframework"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - continuumAdsJobframeworkSpark
    - continuumAdsJobframeworkHiveWarehouse
    - continuumAdsJobframeworkMySql
    - continuumAdsJobframeworkTeradata
    - continuumAdsJobframeworkGcsBucket
    - continuumAdsJobframeworkMetricsEndpoint
    - continuumAdsJobframeworkSmtpRelay
    - continuumClarusAdEndpoint
---

# Architecture Context

## System Context

ads-jobframework sits within the Continuum platform as a batch analytics engine for the Ads domain. It has no inbound HTTP API surface of its own. Instead, it consumes data from the Groupon Data Lake (Hive), MySQL, and Teradata, performs Spark SQL transformations, and delivers results via three channels: GCS file feeds consumed by CitrusAd, HTTP callbacks to CitrusAd and DoubleClick impression-tracking endpoints, and writes back to Hive reporting tables consumed by internal dashboards. Jobs are submitted to YARN and orchestrated by an external scheduler.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Ads Spark Job Framework | `continuumAdsJobframeworkSpark` | Backend (Batch) | Scala 2.12, Spark 2.4 | Core YARN-submitted Spark application containing all batch job implementations |
| Groupon Data Lake / Hive | `continuumAdsJobframeworkHiveWarehouse` | Database | Hive, Spark SQL | Primary source of ad impressions, clicks, audience attributes, and reporting tables |
| Ads Jobframework MySQL | `continuumAdsJobframeworkMySql` | Database | MySQL 5.x | JDBC-accessible ad inventory and campaign metadata store |
| Teradata Sandbox | `continuumAdsJobframeworkTeradata` | Database | Teradata 16.10 | Source for PPID audience export datasets |
| GCS Analytics Bucket | `continuumAdsJobframeworkGcsBucket` | Storage | Google Cloud Storage | Output bucket for customer/order/click feeds and PPID audience files |
| Metrics / Telegraf Endpoint | `continuumAdsJobframeworkMetricsEndpoint` | Backend | HTTP, InfluxDB | Collects custom Spark job metrics via metrics-sma and Telegraf |
| SMTP Relay | `continuumAdsJobframeworkSmtpRelay` | Backend | SMTP | Email relay for exception, over-report, and under-report notifications |
| Clarus / DoubleClick Endpoint | `continuumClarusAdEndpoint` | External | HTTPS | External Clarus/DoubleClick impression tracking endpoint |

## Components by Container

### Ads Spark Job Framework (`continuumAdsJobframeworkSpark`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `CitrusAdClicksJob` | Processes sponsored listing click data from `grp_gdoop_pde.junoHourly` | Scala, Spark SQL |
| `CitrusAdClicksReportJob` | Hourly: aggregates CitrusAd click events and posts callbacks to CitrusAd API | Scala, Spark SQL |
| `CitrusAdClicksReportBackfillJob` | Backfills historical CitrusAd click callbacks for a specified time window | Scala, Spark SQL |
| `CitrusAdImpressionsReportJob` | Hourly: aggregates CitrusAd impression events (web, mobile, email) and posts callbacks | Scala, Spark SQL |
| `CitrusAdImpressionsReportBackfillJob` | Backfills historical CitrusAd impression callbacks for a specified date/time range | Scala, Spark SQL |
| `CustomerFeedJob` | Builds hashed customer demographic feed from `cia_realtime.user_attrs_gbl` and writes TSV to GCS | Scala, Spark SQL |
| `OrderFeedJob` | Exports deal order data from `user_edwprod.fact_gbl_transactions` as hashed TSV feed to GCS | Scala, Spark SQL |
| `CouponsOrderFeedJob` | Generates coupon redemption order feed from `junoHourly` for CitrusAd ingestion | Scala, Spark SQL |
| `ClarusAdImpressionsReportJob` | Counts Clarus ad impressions and triggers DoubleClick tracking endpoint | Scala, Spark SQL |
| `ClarusAdImpressionsBackfillJob` | Backfills Clarus impression counts and tracking callbacks | Scala, Spark SQL |
| `PPIDAudienceJob` | Reads PPID export from Teradata, SHA-256 hashes identifiers, writes CSV to GCS | Scala, Teradata JDBC |
| `PVWithImpressions` | Aggregates US web page-views with ad impressions, clicks, and bot filtering into `ai_reporting.pv_with_impressions` | Scala, Spark SQL |
| `PVWithImpressionsIntl` | International variant of PVWithImpressions for non-US traffic | Scala, Spark SQL |
| `SLClickImpressionWebJob` | Joins web impressions, clicks, and order data from `junoHourly` into `ai_reporting.sl_imp_clicks` | Scala, Spark SQL |
| `SLClickImpressionAppJob` | Builds mobile app click/impression aggregates for sponsored listings | Scala, Spark SQL |
| `SearchTermFetchJob` | Computes deal and category keyword engagement metrics and exports to GCS | Scala, Spark SQL |
| `ROASBasedDealMaxCPCJob` | Reads ROAS-based max-CPC from `grp_gdoop_local_ds_db.est_maxcpc_by_dealid` and exports TSV.gz to GCS | Scala, Spark SQL |
| `UpliftModelPrediction` | Runs Spark ML Random Forest inference to score users; writes bottom-decile blocklist to Hive | Scala, Spark ML |
| `UpliftPreprocessor` | Feature preprocessing utilities for uplift model pipeline | Scala, Spark ML |
| `UpliftModelUtil` | Model path helpers and first-day-of-month utilities for uplift pipeline | Scala |
| `SLCitrusAdExceptionReportEmailJob` | Consolidates over/under-report CSVs and emails ads-eng with file attachments | Scala, JavaMail |
| `SLCitrusAdOverReportJob` | Flags CitrusAd over-reporting scenarios in Hive and emails stakeholders | Scala, Spark SQL |
| `SLCitrusAdUnderReportJob` | Flags CitrusAd under-reporting scenarios in Hive and emails stakeholders | Scala, Spark SQL |
| `CitrusAd HTTP Client` | Reports CitrusAd impressions (`GET /v1/resource/first-i/{adId}`) and clicks (`GET /v1/resource/second-c/{adId}`) with per-call metrics | Scala, scalaj-http |
| `ClarusAd HTTP Client` | Issues DoubleClick impression tracking pings and records per-call metrics | Scala, scalaj-http |
| `MetricsPublisher` | Facade over metrics-sma counters and gauges shared by all jobs | Scala, metrics-sma |
| `UpstreamTables` | Centralized Hive table definitions registry shared across all jobs | Scala |
| `HashFunction` | HMAC-SHA256 hashing of customer/session identifiers using configured `feeds.secretKey` | Scala, JCE |
| `EmailSender` | SMTP email utility supporting attachments for reconciliation reports | Scala, JavaMail |
| `SampleSparkJob` | Example job demonstrating JDBC reads, decryption, and logging patterns | Scala, Spark SQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkHiveWarehouse` | Reads/writes Spark SQL datasets (`junoHourly`, `ai_reporting.*`, taxonomy joins) | Spark SQL |
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkMySql` | JDBC access for ad inventory and campaign metadata | JDBC |
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkTeradata` | Reads PPID audience export tables via Teradata connector | Teradata JDBC |
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkGcsBucket` | Writes customer feeds, order feeds, PPID exports, max-CPC files | GCS connector |
| `continuumAdsJobframeworkSpark` | `continuumClarusAdEndpoint` | Sends Clarus/DoubleClick impression pings | HTTPS |
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkMetricsEndpoint` | Publishes Spark job counters and gauges | HTTP/Influx |
| `continuumAdsJobframeworkSpark` | `continuumAdsJobframeworkSmtpRelay` | Sends exception and reconciliation report emails | SMTP |
| `continuumAdsJobframeworkSpark` | `messagingSaaS` | Operational email notifications | SMTP |
| `continuumAdsJobframeworkSpark` | `metricsStack` | Batch job metrics and telemetry | HTTP/Influx |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-ads-jobframework`
- Component: `components-continuum-ads-jobframework-spark-components`

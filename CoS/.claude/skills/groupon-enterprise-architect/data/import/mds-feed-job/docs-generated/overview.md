---
service: "mds-feed-job"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Marketing Information Systems"
platform: "Continuum"
team: "MIS (Marketing Information Systems)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Apache Spark"
  framework_version: "3.5.1"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# MDS Feed Job Overview

## Purpose

MDS Feed Job is a Spark batch job owned by the MIS (Marketing Information Systems) team. It reads MDS (Marketing Data Service) deal snapshots from distributed storage, applies configurable transformer and UDF pipelines, validates output quality, and publishes resulting feeds to partner channels, advertising platforms, and search indexes. The job underpins Groupon's outbound marketing data distribution — including Google Shopping, SEM, Google Merchant Center, and partner catalog feeds.

## Scope

### In scope

- Reading MDS deal snapshot data from GCS/HDFS distributed storage
- Executing ordered transformer and UDF pipeline chains against Spark datasets
- Enriching feed data via external API calls (pricing, taxonomy, merchant, inventory, catalog, VAT)
- Performing multi-language translation via Google Translate API
- Generating SEM (Search Engine Marketing) feed datasets from EDW source data
- Validating feed output quality and recording metrics
- Publishing finalized feeds to GCS staging and downstream consumers (Google Merchant Center, Google Ads)
- Updating batch lifecycle status in the Feed API Service (Marketing Deal Service)
- Reporting operational metrics to InfluxDB

### Out of scope

- Serving feed data in real time (no REST API exposed)
- Producing or consuming Kafka/message-bus events
- Managing deal or merchant data (handled by upstream services)
- Managing taxonomy structure (owned by `continuumTaxonomyService`)
- Pricing calculation logic (owned by `continuumPricingService`)

## Domain Context

- **Business domain**: Marketing Information Systems — outbound feed distribution for marketing channels
- **Platform**: Continuum
- **Upstream consumers**: Schedulers and Livy job submission (no direct caller API); downstream — Google Merchant Center, Google Ads, partner feed consumers
- **Downstream dependencies**: `continuumMarketingDealService`, `continuumTaxonomyService`, `continuumDealCatalogService`, `continuumM3MerchantService`, `continuumPricingService`, `continuumTravelInventoryService`, `continuumVoucherInventoryService`, `continuumThirdPartyInventoryService`, BigQuery, EDW (Teradata), Salesforce

## Stakeholders

| Role | Description |
|------|-------------|
| MIS Engineering | Owns, develops, and operates the feed job |
| Marketing Operations | Consumes published feeds via partner and ad platforms |
| Partner Integrations | Receives outbound feed files for catalog synchronization |
| Data Engineering | Maintains MDS snapshot sources consumed by this job |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | pom.xml |
| Framework | Apache Spark | 3.5.1 | pom.xml (spark-core, spark-sql, spark-hive) |
| Distributed Storage | Hadoop Client | 3.3.6 | pom.xml |
| Build tool | Maven | — | pom.xml |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spark-core | 3.5.1 | batch-framework | Spark distributed computation engine |
| spark-sql | 3.5.1 | batch-framework | Spark SQL and Dataset/DataFrame API |
| spark-hive | 3.5.1 | db-client | Hive metastore integration for MDS snapshot reads |
| hadoop-client | 3.3.6 | storage-client | HDFS/GCS distributed storage access |
| google-cloud-storage BOM | 26.70.0 | storage-client | GCS client for reading snapshots and writing feed outputs |
| bigquery | — | db-client | BigQuery client for gift-booster enrichment reads |
| retrofit2 | 2.5.0 | http-framework | HTTP client for all external service API calls |
| failsafe | 3.3.2 | resilience | Retry and circuit-breaker for external API calls |
| teradata-jdbc | 17.20 | db-client | JDBC driver for EDW (Teradata) SEM dataset reads |
| postgresql | 42.7.5 | db-client | PostgreSQL JDBC driver for feed/batch metadata |
| influxdb-client | 2.9 | metrics | Operational metrics reporting |
| opencsv | 5.7.1 | serialization | CSV feed file parsing and generation |
| spark-xml | 0.17.0 | serialization | XML feed format support via Spark |
| google-translate | — | translation | Multi-language feed content translation |
| google-merchant-center-api | — | ads-client | Publishing feeds to Google Merchant Center |

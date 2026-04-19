---
service: "mds-feed-job"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, spark-submit-args]
---

# Configuration

## Overview

MDS Feed Job is configured via a combination of Spark submit arguments, environment variables, and configuration files passed at job submission time (via Livy or scheduler). Job parameters such as feed type, batch ID, division, and run date are supplied as Spark application arguments. Service endpoints, credentials, and infrastructure settings are provided as environment variables or mounted configuration files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GCS_PROJECT_ID` | Google Cloud project for GCS and BigQuery access | yes | none | env |
| `GCS_SNAPSHOT_BUCKET` | GCS bucket containing MDS deal snapshots | yes | none | env |
| `GCS_FEED_OUTPUT_BUCKET` | GCS bucket for feed staging output files | yes | none | env |
| `FEED_API_BASE_URL` | Base URL for Marketing Deal Service (Feed API) | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy Service | yes | none | env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for Deal Catalog Service | yes | none | env |
| `M3_MERCHANT_SERVICE_URL` | Base URL for M3 Merchant Service | yes | none | env |
| `PRICING_SERVICE_URL` | Base URL for Pricing Service | yes | none | env |
| `TRAVEL_INVENTORY_SERVICE_URL` | Base URL for Travel Inventory Service | yes | none | env |
| `VOUCHER_INVENTORY_SERVICE_URL` | Base URL for Voucher Inventory Service | yes | none | env |
| `TPIS_SERVICE_URL` | Base URL for Third-Party Inventory Service | yes | none | env |
| `SALESFORCE_API_URL` | Base URL for Salesforce REST API (VAT metadata) | yes | none | env |
| `TERADATA_JDBC_URL` | JDBC connection URL for EDW (Teradata) | yes | none | env |
| `POSTGRES_JDBC_URL` | JDBC connection URL for feed/batch metadata PostgreSQL | yes | none | env |
| `INFLUXDB_URL` | InfluxDB endpoint for operational metrics | yes | none | env |
| `INFLUXDB_BUCKET` | InfluxDB bucket for metrics writes | yes | none | env |
| `GOOGLE_TRANSLATE_API_KEY` | API key for Google Translate service | yes | none | env / vault |
| `GOOGLE_MERCHANT_CENTER_CREDENTIALS` | Path to service account JSON for Merchant Center | yes | none | env / vault |
| `GOOGLE_ADS_CREDENTIALS` | Path to service account JSON for Google Ads | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found for named feature flags. Feed type selection and transformer pipeline activation are controlled by feed configuration loaded from the Feed API (Marketing Deal Service) at job startup, not by static flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `spark-defaults.conf` | properties | Spark runtime tuning (executor memory, parallelism, serialization) |
| `log4j2.properties` | properties | Logging configuration for Spark driver and executor nodes |
| Feed configuration (runtime) | JSON (via API) | Feed definitions, transformer chain configuration, and batch parameters loaded from `continuumMarketingDealService` at job start |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `teradata-jdbc-credentials` | Username and password for EDW Teradata connection | vault / k8s-secret |
| `postgres-jdbc-credentials` | Username and password for feed metadata PostgreSQL | vault / k8s-secret |
| `salesforce-api-credentials` | OAuth client ID and secret for Salesforce REST API | vault / k8s-secret |
| `google-service-account-key` | Service account JSON for GCS, BigQuery, Merchant Center, and Ads | vault / k8s-secret |
| `google-translate-api-key` | API key for Google Translate | vault / k8s-secret |
| `influxdb-auth-token` | Authentication token for InfluxDB metrics writes | vault / k8s-secret |

> Secret values are NEVER documented. Only names and purposes.

## Per-Environment Overrides

- **Development / local**: Spark runs in local mode (`--master local[*]`); GCS credentials use developer service accounts; Teradata and PostgreSQL connection URLs point to dev instances.
- **Staging**: Full cluster deployment via Livy; all service URLs point to staging endpoints; uses staging GCS buckets and staging Merchant Center accounts.
- **Production**: Full cluster deployment; production GCS buckets; production service endpoints; live Merchant Center and Google Ads accounts; stricter Spark resource limits enforced at submission.

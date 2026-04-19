---
service: "janus-user-activity-store"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["cli-args", "hocon-config-files", "airflow-variables", "airflow-environment-vars"]
---

# Configuration

## Overview

The Spark job (`JanusUserActivityRunner`) is configured entirely through 7 positional CLI arguments passed by the Airflow `DataprocSubmitJobOperator`. The first argument identifies a HOCON config file bundled in the JAR (one per environment: `dev/dev.conf`, `stable/stable.conf`, `prod/prod.conf`). The remaining 6 arguments supply runtime-specific values that override or supplement the config file. The Airflow orchestrator layer is configured via Cloud Composer environment-level Airflow Variables and environment-specific Python config modules.

## Environment Variables

### Spark Job CLI Arguments (passed by Airflow)

| Argument Position | Variable/Config Key | Purpose | Required | Example Value |
|------------------|---------------------|---------|----------|--------------|
| `args(0)` | `config_file_name` | Path to bundled HOCON config file (relative to classpath) | yes | `prod/prod.conf` |
| `args(1)` | `parquetFilesPath` | GCS path to hourly Janus Parquet partition | yes | `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds=2024-01-15/hour=3` |
| `args(2)` | `tableMonthSuffix` | Month suffix appended to Bigtable table names | yes | `_01_2024` |
| `args(3)` | `metricsEndpoint` | HTTP endpoint for Telegraf metrics receiver | yes | `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| `args(4)` | `metricsEnvTagValue` | Environment tag value for metrics | yes | `production` |
| `args(5)` | `metricsAtomTagValue` | Atom (version) tag value for metrics | yes | Pipeline artifact version |
| `args(6)` | `metricsHostHeader` | `Host` header value for metrics HTTP calls | yes | `telegraf.production.service` |

### Airflow / Cloud Composer Variables

| Variable | Purpose | Required | Source |
|----------|---------|----------|--------|
| `env` | Selects the environment-specific config module (`dev`, `staging`, `production`) | yes | Airflow Variable |
| `PIPELINE_ARTIFACT_VERSION` | Version of the Spark JAR artifact; used to construct the GCS/Artifactory JAR path | yes | Airflow Variable / CI injection |
| `BIGTABLE_EMULATOR_HOST` | Local Bigtable emulator endpoint — used in development/testing only | no (test only) | env var |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GCP service account JSON — used in local development/testing only | no (test only) | env var |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag framework is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/prod/prod.conf` | HOCON | Production environment configuration: Bigtable project/instance IDs, platform-to-table mappings, column families, Janus metadata URL and hybrid boundary endpoints |
| `src/main/resources/stable/stable.conf` | HOCON | Stable (staging) environment configuration — same structure as prod with staging-specific GCP project and instance IDs |
| `src/main/resources/dev/dev.conf` | HOCON | Development environment configuration — same structure, dev GCP project and instance IDs |
| `src/main/resources/metrics.yml` | YAML | Local metrics configuration: `destinationUrl: http://localhost:8186/`, flush frequency 10s |
| `src/test/resources/metrics.yml` | YAML | Test metrics configuration |

### HOCON Config Structure

All environment config files share the following schema (mapped to `UserActivityConfig` via PureConfig):

| Key | Purpose | Example (prod) |
|-----|---------|---------------|
| `parquetFilesPath` | GCS Parquet input path (overridden by CLI arg 1) | `""` (overridden at runtime) |
| `platformsAndTables.mobile` | Bigtable table base name for mobile platform | `data_eng_mobile_user_activity` |
| `platformsAndTables.web` | Bigtable table base name for web platform | `data_eng_web_user_activity` |
| `platformsAndTables.email` | Bigtable table base name for email platform | `data_eng_email_user_activity` |
| `coreFamily` | Column family name for core event writes | `a` |
| `extendedFamily` | Column family name for extended event writes | `extended` |
| `projectId` | GCP project ID for Bigtable | `prj-grp-datalake-prod-8a19` |
| `bigTableInstanceId` | Bigtable instance ID | `grp-bigtable-prod-analytics` |
| `tableMonthSuffix` | Month suffix for table name (overridden by CLI arg 2) | `""` (overridden at runtime) |
| `metricsEndpoint` | Telegraf endpoint URL (overridden by CLI arg 3) | `""` (overridden at runtime) |
| `metricsEnvTagValue` | Metrics env tag (overridden by CLI arg 4) | `""` (overridden at runtime) |
| `metricsAtomTagValue` | Metrics atom tag (overridden by CLI arg 5) | `""` (overridden at runtime) |
| `metricsHostHeader` | Metrics HTTP Host header (overridden by CLI arg 6) | `""` (overridden at runtime) |
| `janusMetadata.url` | Internal service hostname for Janus metadata API | `janus-web-cloud.production.service` |
| `janusMetadata.hybridBoundary.endpoint` | Edge proxy base URL for Janus API routing | `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| `janusMetadata.hybridBoundary.keyStoreLocation` | Path to mTLS keystore file | `/var/groupon/janus-yati-keystore.jks` |
| `janusMetadata.hybridBoundary.trustStoreLocation` | Path to mTLS truststore file | `/var/groupon/truststore.jks` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `janus-yati-keystore.jks` | mTLS client keystore for hybrid boundary authentication to Janus API | Mounted file at `/var/groupon/janus-yati-keystore.jks` on Dataproc nodes |
| `truststore.jks` | TLS truststore for hybrid boundary HTTPS connections | Mounted file at `/var/groupon/truststore.jks` on Dataproc nodes |
| GCP Service Account key | Dataproc node authentication to GCP APIs (Bigtable, GCS) | Dataproc Workload Identity / node service account (`sa-dataproc-nodes@...`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Key | Dev | Stable | Production |
|-----------|-----|--------|-----------|
| GCP project (Dataproc) | `prj-grp-janus-dev-aac6` | `prj-grp-janus-stable-e0d9` | `prj-grp-janus-prod-0808` |
| Bigtable project | `prj-grp-datalake-dev-8876` | `prj-grp-datalake-stable-dcf6` | `prj-grp-datalake-prod-8a19` |
| Bigtable instance | `grp-bigtable-dev-analytics` | `grp-bigtable-stable-analytics` | `grp-bigtable-prod-analytics` |
| Janus metadata URL | `janus-web-cloud.staging.service` | `janus-web-cloud.staging.service` | `janus-web-cloud.production.service` |
| Hybrid boundary endpoint | `https://edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `https://edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| Parquet input bucket | `gs://grpn-dnd-dev-pipelines-pde/kafka/region=na/source=janus-all` | `gs://grpn-dnd-stable-pipelines-pde/kafka/region=na/source=janus-all` | `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all` |
| Metrics env tag | `dev` | `staging` | `production` |
| Metrics host header | (not set in dev) | `telegraf.staging.service` | `telegraf.production.service` |
| Dataproc namespace | `grpn-data-pipelines-dev` | `grpn-data-pipelines-staging` | `grpn-data-pipelines-production` |
| Composer DAGs bucket | `us-central1-grp-pre-compose-843218f2-bucket` | `us-central1-grp-pre-compose-9cdc6404-bucket` | `us-central1-grp-pre-compose-52d3a0bc-bucket` |

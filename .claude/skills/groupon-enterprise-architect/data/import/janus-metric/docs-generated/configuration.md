---
service: "janus-metric"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["properties-files", "airflow-variables", "env-vars"]
---

# Configuration

## Overview

janus-metric is configured via `.properties` files bundled in the JAR, one per environment (`janus_metrics_dev.properties`, `janus_metrics_stable.properties`, `janus_metrics_prod.properties`, `janus_metrics_sandbox.properties`). The Airflow DAG selects the appropriate file at runtime and passes it as the first CLI argument to the Spark job. Dataproc cluster parameters (machine types, GCS bucket names, service accounts) are provided through Python config modules in the `orchestrator/janus_config/` directory. Airflow Variables supply the target environment name.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PIPELINE_ARTIFACT_VERSION` | Version of the `janus-metrics-aggregator` JAR to download from Artifactory | yes | none | Airflow / Jenkins |
| `env` | Target environment name (`dev`, `stable`, `prod`) — used to select config module | yes | none | Airflow Variable |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where Airflow DAG files are stored | yes | none | Deploy-bot environment var |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for the pipeline workload | yes | none | Deploy-bot environment var |

> IMPORTANT: Secret values (keystore passwords, API tokens) are never documented. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/janus_metrics_prod.properties` | Java Properties | Production runtime configuration for all Spark jobs |
| `src/main/resources/janus_metrics_stable.properties` | Java Properties | Staging (stable) runtime configuration |
| `src/main/resources/janus_metrics_dev.properties` | Java Properties | Development runtime configuration |
| `src/main/resources/janus_metrics_sandbox.properties` | Java Properties | Sandbox runtime configuration |
| `src/main/resources/janus_metrics_query_config.json` | JSON | ES query templates for supplementary metric queries (data volume cube, top-ten searches, deal-search effectiveness, pageapp analytics) |
| `src/main/resources/com/groupon/janus/janus_volume.sql` | SQL | Spark SQL query for Janus volume cube aggregation |
| `src/main/resources/com/groupon/janus/janus_volume_es.sql` | SQL | Spark SQL query for Janus ES volume aggregation |
| `src/main/resources/com/groupon/janus/juno_volume.sql` | SQL | Spark SQL query for Juno hourly volume cube aggregation |
| `orchestrator/janus_config/config.py` | Python | Shared Airflow DAG config — Dataproc defaults, lifecycle, jar path |
| `orchestrator/janus_config/config_prod.py` | Python | Production-specific Dataproc cluster config |
| `orchestrator/janus_config/config_dev.py` | Python | Development-specific Dataproc cluster config |
| `orchestrator/janus_config/config_stable.py` | Python | Staging-specific Dataproc cluster config |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `/var/groupon/janus-yati-keystore.jks` | Mutual TLS keystore for Janus Metadata Service HTTPS calls | Mounted volume on Dataproc nodes |
| `/var/groupon/truststore.jks` | TLS truststore for validating Janus Metadata Service certificate | Mounted volume on Dataproc nodes |

> Secret values are NEVER documented. Only names and mount paths are listed.

## Key Configuration Properties (all environments)

| Property Key | Purpose | Example Value (prod) |
|-------------|---------|---------------------|
| `janusMetadataServiceUri` | Janus Metadata Service hostname for country list lookup | `janus-web-cloud.production.service` |
| `ultronUrl` | Ultron API hostname for watermark state | `ultron-api.production.service` |
| `ultronGroupName` | Ultron group name for job ownership | `platform-data-eng` |
| `endpoint` | Edge proxy URL for Janus API HTTPS calls | `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| `keyStoreLocation` | Path to JKS keystore on Dataproc node | `/var/groupon/janus-yati-keystore.jks` |
| `trustStoreLocation` | Path to JKS truststore on Dataproc node | `/var/groupon/truststore.jks` |
| `metricsEnvTagValue` | InfluxDB `env` tag value for SMA metrics | `prod` |
| `metricsGateway` | SMA metrics gateway URL | `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| `metricsSource` | InfluxDB `source` tag value | `janus-metric` |
| `metricsHostHeader` | Host header for metrics gateway | `telegraf.production.service` |
| `ultronJanusVolumeAndQualityListPath` | GCS path pattern for Janus Parquet inputs | `gs://grpn-dnd-prod-pipelines-pde/.../janus/ds=$dates/hour=$hours/*` |
| `ultronJanusVolumeAndQualityJobName` | Ultron job name for Janus volume/quality | `janus_volume_and_quality_metrics-gcp` |
| `ultronThrottleValue` | Ultron concurrency throttle for Janus jobs | `3` |
| `janusVolumeAndQualityUltronLabel` | Ultron label prefix for Janus jobs | `janus-volume-quality-metrics-gcp` |
| `janusCubeVolumesQueryResource` | Classpath resource path for volume SQL query | `/com/groupon/janus/janus_volume.sql` |
| `ultronJunoListPath` | GCS path pattern for Juno Parquet inputs | `gs://grpn-dnd-prod-pipelines-pde/.../juno/junoHourly/...` |
| `ultronJunoMetricsUltronJobName` | Ultron job name for Juno metrics | `juno_metrics-gcp` |
| `junoUltronThrottleValue` | Ultron concurrency throttle for Juno jobs | `500` |
| `junoCubeVolumesQueryResource` | Classpath resource path for Juno volume SQL query | `/com/groupon/janus/juno_volume.sql` |
| `junoBatchSize` | Number of Juno Parquet files processed per Spark query batch | `25` |
| `janusRawUltronLabel` | Ultron label prefix for raw metric jobs | `janus-raw-metrics-gcp` |
| `mobileTrackingAuditPath` | GCS base path for mobile_tracking raw files | `gs://grpn-dnd-prod-pipelines-yati-raw/...` |
| `jupiterBasePath` | GCS base path for Jupiter attribute data | `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/jupiter` |
| `attributeCardinalityTopN` | Number of top-N values to compute per attribute | `5` |
| `jupiterExtraColumns` | Columns to exclude from cardinality analysis | `yatiTimeMs,yatiUUID,eventDestination` |

## Per-Environment Overrides

| Setting | dev | stable | prod |
|---------|-----|--------|------|
| `janusMetadataServiceUri` | `janus-web-cloud.staging.service` | `janus-web-cloud.staging.service` | `janus-web-cloud.production.service` |
| `ultronUrl` | `ultron-api.staging.service` | `ultron-api.staging.service` | `ultron-api.production.service` |
| `ultronGroupName` | `janus` | `platform-data-eng` | `platform-data-eng` |
| `metricsEnvTagValue` | `dev` | `stable` | `prod` |
| `metricsGateway` | `http://telegraf.general.sandbox.gcp.groupondev.com` | `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` | `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| Dataproc project | dev project | `prj-grp-janus-prod-0808` (via stable config) | `prj-grp-janus-prod-0808` |
| GCS input bucket | `gs://grpn-dnd-dev-pipelines-pde/...` | `gs://grpn-dnd-stable-pipelines-janus-yati-muncher/...` | `gs://grpn-dnd-prod-pipelines-pde/...` |
| Spark deploy mode | cluster | cluster | cluster |
| Dynamic allocation | enabled | enabled | enabled |

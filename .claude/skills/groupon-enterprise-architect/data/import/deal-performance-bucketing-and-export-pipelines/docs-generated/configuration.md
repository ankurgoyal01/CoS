---
service: "deal-performance-bucketing-and-export-pipelines"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "pipeline-args"]
---

# Configuration

## Overview

The service is configured via YAML config files bundled in `src/main/resources/configs/` (one per environment-region combination). The active config is selected at pipeline launch time via `--env` or `--config` command-line arguments. Database credentials are stored in the YAML config and may be overridden at runtime via the `--dbPassword` pipeline argument (used by Airflow tasks that inject secrets). There are no environment variable overrides or external config stores (Consul/Vault) in evidence.

## Environment Variables

> No evidence found in codebase. Runtime configuration is injected via pipeline arguments and YAML config files, not environment variables.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `eventDecorationPipelineConfig.enabled` | Enables or disables A/B experiment decoration join during bucketing | `true` (production) | per-environment (set in YAML config) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/configs/na_prod.yml` | YAML | NA production configuration (GCS URLs, DB host, Wavefront endpoint) |
| `src/main/resources/configs/na_staging.yml` | YAML | NA staging configuration |
| `src/main/resources/configs/emea_prod.yml` | YAML | EMEA production configuration |
| `src/main/resources/configs/emea_staging.yml` | YAML | EMEA staging configuration |
| `src/main/resources/configs/na_dps_development.yml` | YAML | NA local development configuration |
| `src/main/resources/configs/emea_dps_development.yml` | YAML | EMEA local development configuration |
| `src/main/resources/configs/na_dps_development_local.yml` | YAML | NA local-only development configuration |
| `src/main/resources/configs/emea_dps_development_local.yml` | YAML | EMEA local-only development configuration |
| `src/main/resources/logger/elk.log4j.properties` | Properties | Log4j configuration for ELK (production) |
| `src/main/resources/logger/stdout.log4j.properties` | Properties | Log4j configuration for stdout (local) |
| `src/main/resources/metrics.properties` | Properties | Spark metrics configuration for Telegraf |

### Key Config Fields (from `na_prod.yml`)

| Config Key | Purpose | Example Value |
|-----------|---------|---------------|
| `userDealBucketingPipelineConfig.gcsUrl` | GCS bucket URL for input/output | `gs://grpn-dnd-prod-analytics-grp-mars-mds` |
| `userDealBucketingPipelineConfig.outputConfig.path` | Base GCS output path | `gs://grpn-dnd-prod-analytics-grp-mars-mds` |
| `userDealBucketingPipelineConfig.outputConfig.partitionFormat` | HDFS/GCS partition path format string | `/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source=%s/date=%s/hour=%s/event_type=%s` |
| `userDealBucketingPipelineConfig.eventConfigs[].inputEventsPath` | GCS input path for deal events | `/user/grp_gdoop_mars_mds/dps/events` |
| `userDealBucketingPipelineConfig.eventConfigs[].inputEventObject` | Java class name for input event deserialization | `com.groupon.relevance.dealperformance.data.models.InstanceStoreAttributedDealImpression` |
| `userDealBucketingPipelineConfig.eventConfigs[].dirsToScanPerRunInHours` | Number of hours of data to scan per run | `7` |
| `userDealBucketingPipelineConfig.eventConfigs[].windowingDurationInHours` | Beam windowing duration in hours | `1` |
| `userDealBucketingPipelineConfig.bucketConfigs` | List of bucket dimensions (name + class) | gender, distance, age, experimentId, purchaserDivision, activation, country |
| `eventDecorationPipelineConfig.enabled` | Enable/disable experiment decoration | `true` |
| `eventDecorationPipelineConfig.hdfsUrl` | HDFS namenode URL for Janus data | `hdfs://gdoop-namenode` |
| `eventDecorationPipelineConfig.inputPath` | HDFS path to Janus experiment data | `/user/grp_gdoop_platform-data-eng/janus` |
| `eventDecorationPipelineConfig.experimentNamePrefix` | Filter prefix for experiment names | `relevance-explore-exploit-` |
| `dealPerformanceExportPipelineConfig.gcsUrl` | GCS bucket URL for export input | `gs://grpn-dnd-prod-analytics-grp-mars-mds` |
| `dealPerformanceExportPipelineConfig.region` | Region identifier written to DB rows | `NA` |
| `dealPerformanceExportPipelineConfig.inputPathFormat` | GCS input path format for bucketed data | `/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source=%s` |
| `dealPerformanceExportPipelineConfig.dbConfig.host` | PostgreSQL host | `deal-performance-service-v2-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `dealPerformanceExportPipelineConfig.dbConfig.database` | PostgreSQL database name | `deal_perf_v2_prod` |
| `dealPerformanceExportPipelineConfig.dbConfig.transactionPort` | PostgreSQL port | `5432` |
| `dealPerformanceExportPipelineConfig.dbConfig.transactionPoolSize` | JDBC connection pool size | `2` |
| `commonConfig.serviceName` | Service name used in metric tags | `deal-performance-service-v2` |
| `commonConfig.loggingEnv` | Logging environment label | `prod` |
| `commonConfig.wavefront.endpoint` | Telegraf HTTP endpoint for metrics | `http://telegraf.default.prod.us-central1.gcp.groupondev.com` |
| `commonConfig.wavefront.tags.serviceRegion` | Wavefront metric tag: region | `NA` |
| `commonConfig.wavefront.tags.env` | Wavefront metric tag: environment | `prod` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `dealPerformanceExportPipelineConfig.dbConfig.password` | PostgreSQL application user password | YAML config file (may be overridden at runtime via `--dbPassword` argument injected by Airflow) |
| `dealPerformanceExportPipelineConfig.dbConfig.username` | PostgreSQL application user | YAML config file |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | GCS Bucket | DB Host | Wavefront Endpoint |
|-------------|-----------|---------|-------------------|
| NA Production | `gs://grpn-dnd-prod-analytics-grp-mars-mds` | `deal-performance-service-v2-rw-na-production-db.gds.prod.gcp.groupondev.com` | `http://telegraf.default.prod.us-central1.gcp.groupondev.com` |
| NA Staging | `gs://grpn-dnd-stable-analytics-grp-mars-mds` | `deal-performance-service-v2-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `http://telegraf.us-central1.conveyor.stable.gcp.groupondev.com` |
| EMEA Production | EMEA-specific bucket | EMEA-specific DB host | EMEA-specific endpoint |
| Development (local) | Local/dev bucket | `localhost:5432` | Local Telegraf |

Pipeline execution is selected via `--runner=SparkRunner --env=<env_name>` at spark-submit time, where `<env_name>` maps to a YAML config file in `src/main/resources/configs/`.

---
service: "janus-muncher"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, gcp-secret-manager, airflow-variables]
---

# Configuration

## Overview

Janus Muncher is configured through HOCON configuration files (`.conf`) loaded at Spark job startup via the `pureconfig` library. The active config file is selected by the `env` argument passed to `MuncherMain` (e.g., `muncher-prod`, `muncher-dev`, `muncher-prod-sox`). Each config file is bundled into the JAR at build time from `src/main/resources/`. The Airflow orchestrator reads environment-specific Python config modules (`janus_config/config_prod.py`, etc.) and resolves secrets from GCP Secret Manager at DAG runtime.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PIPELINE_ARTIFACT_VERSION` | Version token injected into Airflow DAG to resolve JAR artifact URL | yes | None | Jenkins CI / Airflow variable |
| `env` | Airflow Variable used by `config.py` to select the env-specific config module | yes | None | Airflow Variable store |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where DAG files are deployed by deploy-bot | yes | None | deploy-bot environment_vars |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace for deploy-bot DAG deployment | yes | None | deploy-bot environment_vars |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `wideRun` | Enables wide (all-partition) run mode vs. narrow/incremental | `true` | per-config-file |
| `corruptRecordCheck` | Enables corrupt Parquet record detection and metric emission | `false` | per-config-file |
| `isReplayMerge` | Switches the job into replay-merge mode (different I/O paths and logic) | `false` | per-config-file |
| `alertExcludedEvents` | Enables email alert when deduplication excludes events | `true` | per-config-file |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/muncher-prod.conf` | HOCON | Production non-SOX Spark job configuration |
| `src/main/resources/muncher-prod-sox.conf` | HOCON | Production SOX-compliant pipeline configuration (isolated buckets, SOX Hive DB) |
| `src/main/resources/muncher-dev.conf` | HOCON | Development/staging Spark job configuration |
| `src/main/resources/muncher-stable.conf` | HOCON | Stable environment configuration |
| `src/main/resources/muncher-prod-replay-append.conf` | HOCON | Production replay append job configuration |
| `src/main/resources/muncher-prod-replay-merge-prep.conf` | HOCON | Production replay merge-prep job configuration |
| `src/main/resources/muncher-prod-replay-merge.conf` | HOCON | Production replay merge job configuration |
| `src/main/resources/muncher-dev-replay-*.conf` | HOCON | Dev replay job variants |
| `src/main/resources/muncher-stable-replay-*.conf` | HOCON | Stable replay job variants |
| `src/main/resources/small-file-compactor-sandbox.conf` | HOCON | Sandbox small-file compactor configuration |
| `src/main/resources/metrics.yml` | YAML | SMA/Telegraf metrics client configuration (strategy, HTTP pool settings) |
| `orchestrator/janus_config/config.py` | Python | Shared orchestrator config (loaded dynamically by all DAGs) |
| `orchestrator/janus_config/config_prod.py` | Python | Production orchestrator config (GCP project IDs, cluster configs, JAR paths) |
| `orchestrator/janus_config/config_prod_sox.py` | Python | Production SOX orchestrator config |
| `orchestrator/janus_config/config_dev.py` | Python | Dev orchestrator config |
| `orchestrator/janus_config/config_stable.py` | Python | Stable orchestrator config |

## Key Config Parameters (from `muncher-prod.conf`)

| Parameter | Value / Pattern | Purpose |
|-----------|----------------|---------|
| `config.basePath` | `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/prod` | Base GCS path for pipeline output |
| `config.canonicalBasePath` | `gs://grpn-dnd-prod-pipelines-yati-canonicals` | GCS bucket for Yati canonical input |
| `config.input.basePathTemplate` | `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds=$dates/hour=$hours/*` | Input file glob pattern |
| `config.input.topic` | `janus-all` | Logical input topic name |
| `config.input.skipNewFilesMinutes` | `5` | Skip files written within the last N minutes |
| `config.input.lockLookbackDays` | `2` | Lookback window for file lock detection |
| `config.dedup.eventKeySkewThreshold` | `25000` | Max event key skew before alert is triggered |
| `config.dedup.excludedColumns` | `["logstashtime", "logstashtimems", "rawHash"]` | Columns excluded from dedup key computation |
| `config.output.junoOutput.outputFileRowCount` | `1280000` | Target rows per output Parquet file |
| `config.output.junoOutput.compression` | `GZIP` | Parquet output compression codec |
| `config.output.junoOutput.partitionColumns` | `["eventDate", "platform", "eventDestination"]` | Juno Hourly partition columns |
| `config.output.junoOutput.excludedEventsConditionExpr` | `"event != 'abExperiment'"` | SQL filter to exclude events from Juno output |
| `config.output.junoOutput.junoHourlyAnalyticsRetentionYears` | `2` | Retention period for Juno Hourly analytics data |
| `config.hive.serverUrls` | `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/...` | HiveServer2 JDBC connection URLs |
| `config.hive.databaseName` | `grp_gdoop_pde` | Hive database for non-SOX tables |
| `config.ultron.url` | `ultron-api.production.service` | Ultron API hostname (resolved via edge-proxy) |
| `config.ultron.jobName` | `JunoHourlyGcp` | Job name registered in Ultron for watermark tracking |
| `config.janusMetadata.url` | `janus-web-cloud.production.service` | Janus Metadata API hostname |
| `config.janusMetadata.basePath` | `/janus/api/v1` | Janus Metadata API base path |
| `config.metrics.metricsSource` | `janus-muncher` | Metrics source tag |
| `config.metrics.metricsGateway` | `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` | Telegraf gateway URL |
| `config.emailTo` | `["platform-data-eng@groupon.com", "edw-dev-ops@groupon.com"]` | Alert email recipients |
| `config.smtpServer` | `smtp-uswest2.groupondev.com` | SMTP relay hostname |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `janus-hive-credentials` (key: `janus_non_sox_hive_password`) | Hive JDBC password for `svc_gcp_janus` | GCP Secret Manager (`prj-grp-pipelines-prod-bb85`) |
| `ulton_db_password_config_name` (`ulton_db_password`) | Ultron MySQL password for `UltronDbCleaner` JDBC connection | Airflow Variable store |
| `/var/groupon/janus-yati-keystore.jks` | mTLS keystore for edge-proxy authentication (mounted on Dataproc nodes) | Dataproc node local filesystem (provisioned by init script) |
| `/var/groupon/truststore.jks` | mTLS truststore for edge-proxy TLS verification | Dataproc node local filesystem (provisioned by init script) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Parameter | dev | stable | production | production-SOX |
|-----------|-----|--------|------------|----------------|
| `basePath` | `gs://grpn-dnd-dev-pipelines-pde/...` | `gs://grpn-dnd-stable-...` | `gs://grpn-dnd-prod-pipelines-pde/...` | `gs://grpn-dnd-prod-etl-grp-gdoop-sox-db/...` |
| `canonicalBasePath` | `gs://grpn-dnd-dev-pipelines-pde/kafka/...` | Stable GCS | `gs://grpn-dnd-prod-pipelines-yati-canonicals` | SOX GCS bucket |
| `input.topic` | `janus-test-all` | `janus-all` | `janus-all` | `janus-all` |
| `input.inputType` | `devtest` | `regular` | `regular` | `regular` |
| `input.skipNewFilesMinutes` | `1` | `5` | `5` | `5` |
| `ultron.url` | `ultron-api.staging.service` | `ultron-api.staging.service` | `ultron-api.production.service` | `ultron-api.production.service` |
| `ultron.groupName` | `janus` | `janus` | `platform-data-eng` | `platform-data-eng-sox` |
| `janusMetadata.url` | `janus-web-cloud.staging.service` | `janus-web-cloud.staging.service` | `janus-web-cloud.production.service` | `janus-web-cloud.production.service` |
| `hive.databaseName` | `grp_gdoop_pde` | `grp_gdoop_pde` | `grp_gdoop_pde` | `grp_gdoop_sox_db` |
| `metrics.metricsEnvTagValue` | `dev` | `stable` | `production` | `production` |
| `dedup.subject` prefix | `SNC1-Staging::` | `SNC1-Staging::` | `SNC1-Production::` | `Production-SOX::` |

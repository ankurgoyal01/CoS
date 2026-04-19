---
service: "clam"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

CLAM is configured entirely via a YAML config file passed as a command-line argument at job submission time (`submit-clam.sh`). There are no runtime environment variable lookups within the application code itself; environment-specific shell variables (`EXECUTORS_COUNT`, `EXECUTORS_CORES`, `EXECUTORS_MEMORY`) are sourced from a companion `env.sh.conf` file and used only by the shell submission script. No external config stores (Consul, Vault) are used.

## Environment Variables

The following shell variables are sourced from `src/conf/env/<env>-<colo>/env.sh.conf` by the `submit-clam.sh` script at job submission time. They are not read by the Java application.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `EXECUTORS_COUNT` | Number of Spark executor instances to allocate on YARN | yes | None (must be set per environment) | `env.sh.conf` |
| `EXECUTORS_CORES` | Number of CPU cores per Spark executor | yes | None | `env.sh.conf` |
| `EXECUTORS_MEMORY` | Memory per Spark executor (e.g., `22G`) | yes | None | `env.sh.conf` |

Known production values (prod-snc): `EXECUTORS_COUNT=50`, `EXECUTORS_CORES=4`, `EXECUTORS_MEMORY=22G`.

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. CLAM has no feature flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/conf/env/prod-snc/config.yaml` | YAML | Production (snc1 colo) — Kafka broker, input/output topics, checkpoint path, repartition count, metrics endpoint and tags |
| `src/conf/env/prod-sac/config.yaml` | YAML | Production (sac1 colo) — same structure, sac1-specific Kafka broker |
| `src/conf/env/prod-dub/config.yaml` | YAML | Production (dub1 colo) — same structure, dub1-specific Kafka broker |
| `src/conf/env/staging-snc/config.yaml` | YAML | Staging (snc1) — staging Kafka broker and staging topic names (`histograms_v2`, `aggregates`) |
| `src/conf/env/local/config.yaml` | YAML | Local development — staging Kafka, local Spark master (`local[*]`), local checkpoint path |
| `src/conf/env/prod-snc/env.sh.conf` | Shell | Production executor resource settings (executor count, cores, memory) |
| `src/conf/log4j2.properties` | Properties | Log4j2 logging configuration — rolling file appenders for `Clam.log` and `Clam-gdoop.log`, JSON structured output |
| `src/assembly/assembly.xml` | XML | Maven Assembly descriptor — packages the distribution tarball |

### YAML Config Schema

All environment config files share the same schema, parsed by `ClamConfig`:

| Field | Type | Purpose |
|-------|------|---------|
| `kafkaBroker` | string | Kafka bootstrap server address (host:port) |
| `inputTopic` | string | Kafka topic to consume histogram events from |
| `outputTopic` | string | Kafka topic to publish aggregate measurements to |
| `checkpointPath` | string | HDFS (or local) path for Spark Structured Streaming checkpoint storage |
| `repartitionCount` | int | Number of partitions to repartition the Kafka stream into (0 = disabled); set to 200 in production |
| `sparkConfig` | map | Optional additional Spark configuration key-value pairs (used in local mode to set `spark.master`) |
| `metrics.endpoint` | string | URL of the Metrics Gateway for self-metric publishing |
| `metrics.namespace` | string | Metric namespace prefix (always `custom.clam`) |
| `metrics.tags.source` | string | Tag applied to all self-metrics (always `clam`) |
| `metrics.tags.env` | string | Tag applied to all self-metrics (e.g., `prod`, `staging`, `local`) |
| `metrics.tags.service` | string | Tag applied to all self-metrics (always `clam`) |

## Secrets

> No evidence found in codebase. CLAM does not access Vault, AWS Secrets Manager, or any secrets management system. Kafka and HDFS access are credential-free (internal cluster, YARN user `svc_clam`).

## Per-Environment Overrides

| Setting | prod-snc | prod-sac | prod-dub | staging-snc | local |
|---------|----------|----------|----------|-------------|-------|
| `kafkaBroker` | `kafka.snc1:9092` | `kafka-broker-lb.sac1:9092` | `kafka.dub1:9092` | `kafka-08-broker-staging-vip.snc1:9092` | `kafka-08-broker-staging-vip.snc1:9092` |
| `inputTopic` | `metrics_histograms_v2` | `metrics_histograms_v2` | `metrics_histograms_v2` | `histograms_v2` | `histograms_v2` |
| `outputTopic` | `metrics_aggregates` | `metrics_aggregates` | `metrics_aggregates` | `aggregates` | `aggregates` |
| `checkpointPath` | `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` | `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` | `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` | `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` | `spark-checkpoint/` |
| `repartitionCount` | 200 | 200 | 200 | 200 | 24 |
| `metrics.endpoint` | `http://localhost:8186` | `http://localhost:8186` | `http://localhost:8186` | `http://localhost:8186` | `http://metrics-gateway-staging-vip.snc1:80/` |
| `spark.master` | (YARN cluster default) | (YARN cluster default) | (YARN cluster default) | (YARN cluster default) | `local[*]` |

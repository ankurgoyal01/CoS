---
service: "cls-data-pipeline"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["spark-submit-args", "cli-flags"]
---

# Configuration

## Overview

All configuration is provided as CLI arguments to `spark-submit` at job launch time. There are no configuration files, environment variable injection, Consul, or Vault integrations. The `StreamingAppConf` class (using the Scallop library, version 2.0.6) parses named CLI flags from the spark-submit command line. Defaults are compiled into the application and overridden at deployment time. Staging environments use different Kafka group IDs, database names, and Kafka broker addresses.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SPARK_HOME` | Path to Spark installation on Cerebro job submitter | yes | `/var/groupon/spark-2.4.0` | set manually before spark-submit |
| `HADOOP_CONF_DIR` | Path to Hadoop configuration directory | yes | `/etc/hadoop/conf` | set manually before spark-submit |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `--enableKafkaOutput` | Enables writing transformed records to the downstream Kafka output topic | false | per-job invocation |
| `--debug` | Enables debug mode in `StreamingAppConf` | false | per-job invocation |
| `--skipAlert` | Disables email/pager alerting from the notification adapter | true | per-job invocation |
| `--info_mail` | Enables informational emails (non-alert) | false | per-job invocation |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/spark-2.4.0/conf/hive-site.xml` | XML | Hive metastore connection configuration; passed to executors via `--files` in spark-submit |

## CLI Parameters (spark-submit arguments)

All parameters are passed as `--param_name value` arguments to the main class entry point and parsed by `StreamingAppConf`.

| Parameter | Purpose | Required | Default | Notes |
|-----------|---------|----------|---------|-------|
| `--kafka_broker` | Input Kafka broker address | yes | `kafka-08-broker-vip.snc1:9092` | NA: `kafka-aggregate.snc1:9092` or `kafka.snc1:9092`; EMEA: `kafka.dub1:9092` |
| `--output_kafka_broker` | Output Kafka broker address | no | `kafka-08-broker-vip.snc1:9092` | Production: `kafka.snc1:9092` |
| `--topics_input` | Kafka input topic name | yes | — | `mobile_notifications`, `mobile_proximity_locations`, or `global_subscription_service` |
| `--topics_output` | Kafka output topic name | no | — | `cls_coalesce_pts_na` |
| `--groupId` | Kafka consumer group ID | yes | — | e.g., `kafka_cls_mpts_na`, `kafka_cls_prxmty_emea`, `kafka_cls_gss_na` |
| `--offsetReset` | Kafka offset reset policy | no | `latest` | `latest` in production; `earliest` for backfill |
| `--batch_interval` | Spark Streaming micro-batch duration in seconds | no | `120` | Production uses `60` |
| `--numOfpartitions` | Number of Spark output partitions | no | `25` | Production uses `80` |
| `--db` | Hive database name | no | `grp_gdoop_cls_db` | Staging: `cls_staging` |
| `--table` | Hive table name (used in some batch jobs) | no | `cls_pts_test` | — |
| `--deploy_for_dc` | Data center designation; controls which Hive table target is used | yes | `na` | `na` or `emea` |
| `--actionDate` | Date parameter for batch job date filtering | no | yesterday (yyyy-MM-dd) | — |
| `--redis_host` | Redis host URL for the lookup store cache | no | `redis://redis-11798.snc1.raas-shared2-staging.grpn:11798` | Not used in documented production spark-submit commands |
| `--cacheTtlInSeconds` | TTL for positive cache entries in lookup store | no | `259200` (3 days) | — |
| `--cache404ResponseTtlInSeconds` | TTL for negative (404) cache entries in lookup store | no | `300` | — |
| `--compressionType` | Kafka output message compression codec | no | `lz4` | — |
| `--email` | Email recipient for alert notifications | no | (from compiled `Properties.emailId`) | — |
| `--pager` | Pager email address for alert notifications | no | (from compiled `Properties.pagerId`) | — |
| `--avro_schema_url` | Janus Avro schema registry base URL | no | `JanusBaseURL.PROD.getUrl` | — |
| `--sparkMaster` | Spark master URL override | no | — | Overrides `--master` when set |

## Secrets

> No evidence found in codebase. No Vault, AWS Secrets Manager, or Kubernetes secrets are referenced. The service account `svc_cls` is used for SSH/SCP access to Cerebro job submitters; credentials are managed externally via SSH keys.

## Per-Environment Overrides

- **Production (NA)**: `--kafka_broker kafka-aggregate.snc1:9092`, `--groupId kafka_cls_mpts_na`, `--db grp_gdoop_cls_db`, `--deploy_for_dc na`, `--enableKafkaOutput`
- **Production (EMEA)**: `--kafka_broker kafka.dub1:9092`, `--groupId kafka_cls_mpts_emea`, `--deploy_for_dc emea`, `--enableKafkaOutput`
- **Staging**: `--db cls_staging`, different `--groupId` (e.g., `kafka_cls_mpts_na_test`), `--deploy-mode client` instead of `cluster`, no `--enableKafkaOutput`

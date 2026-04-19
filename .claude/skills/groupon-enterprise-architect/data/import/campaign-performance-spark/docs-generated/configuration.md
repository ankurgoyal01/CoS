---
service: "campaign-performance-spark"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "jvm-system-properties", "secrets-files"]
---

# Configuration

## Overview

The service uses Typesafe Config (HOCON) loaded at JVM startup via the `-Dconfig.resource=conf/<env>.conf` system property. Configuration is layered: `common.conf` defines defaults, and per-environment files (`development.conf`, `staging.conf`, `production.conf`, `gcp_prod.conf`, `gcp_stable.conf`) override as needed. Secrets (database passwords, SSL keystore passwords) are injected via a separate `secrets-<env>.conf` file deployed alongside the JAR (never committed to source control). There are no environment variables or external config stores (Consul/Vault) used by this service.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `-Dconfig.resource` | Selects the HOCON config file to load (e.g., `conf/production.conf`) | yes | `conf/development.conf` | JVM system property |
| `-Dcampaign.performance.logging.dir` | Sets the log directory prefix for GdoopLogger output | no | None | JVM system property |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `campaign.performance.spark.runtimeConfigs.spark.speculation` | Enables Spark speculative task execution to prevent slow executor stalls | `"true"` | global |
| `campaign.performance.db.clean.enabled` | Enables/disables the scheduled `DBCleaner` retention task | `true` | global |
| `is_cloud` | Switches filesystem provider from HDFS to GCS | `false` (development) / `true` (GCP configs) | global |
| `use-offset=true` (CLI arg) | At startup, resumes Kafka consumption from offsets stored in DB instead of Spark checkpoint | disabled by default | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/conf/common.conf` | HOCON | Default values for all environments: service name, Spark runtime configs, Kafka client ID, InfluxDB URL |
| `src/main/resources/conf/development.conf` | HOCON | Local development overrides: `local[2]` master, local paths, staging Kafka broker, dev InfluxDB |
| `src/main/resources/conf/staging.conf` | HOCON | On-prem staging: YARN master, HDFS paths, staging Kafka broker (`kafka-aggregate-staging.snc1:9092`), staging DB |
| `src/main/resources/conf/production.conf` | HOCON | On-prem production: YARN master, HDFS paths, production Kafka broker (`kafka-aggregate.snc1:9092`), production DB |
| `src/main/resources/conf/gcp_stable.conf` | HOCON | GCP staging: YARN master, GCS paths (`gs://grpn-dnd-stable-analytics-grp-pmp/...`), GCP Kafka with SSL, GCP DB, Janus schema URL |
| `src/main/resources/conf/gcp_prod.conf` | HOCON | GCP production: YARN master, GCS paths (`gs://grpn-dnd-prod-analytics-grp-pmp/...`), GCP Kafka with SSL, GCP DB, Janus schema URL |
| `secrets-<env>.conf` | HOCON | Database passwords and SSL keystore passwords (deployed separately, not in source control) |
| `src/main/resources/logging/elk/log4j.properties` | Properties | Log4j2 configuration for ELK/Splunk structured log output |
| `src/main/resources/logging/stdout/log4j.properties` | Properties | Log4j2 configuration for console output (local dev) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `campaign.performance.db.postgres.app.pass` | PostgreSQL application user password | `secrets-<env>.conf` (deployed alongside JAR) |
| `ssl.keystore.password` | Password for the Kafka/Janus SSL keystore (`/var/groupon/cm-performance-keystore.jks`) | `secrets-<env>.conf` / keystore file on host |
| `ssl.truststore.password` | Password for the Kafka/Janus SSL truststore (`/var/groupon/truststore.jks`) | `secrets-<env>.conf` / keystore file on host |

> Secret values are never documented. Only names and rotation policies are listed. Passwords originate from GDS-managed credential stores and are rotated by the GDS team.

## Per-Environment Overrides

| Config Key | Development | Staging (on-prem) | Production (on-prem) | GCP Staging | GCP Production |
|---|---|---|---|---|---|
| `spark.master` | `local[2]` | `yarn` | `yarn` | `yarn` | `yarn` |
| `spark.appName` | `CampaignPerfSparkLocal` | `CampaignPerfSparkStaging` | `CampaignPerfSparkProduction` | `CampaignPerfSparkStaging` | `CampaignPerfSparkProduction` |
| `kafka.url` | `kafka-aggregate-staging.snc1:9092` | `kafka-aggregate-staging.snc1:9092` | `kafka-aggregate.snc1:9092` | `kafka-grpn.us-central1.kafka.stable.gcp.groupondev.com:9094` | `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094` |
| `kafka.subscribe` | `janus-tier2` | `janus-all` | `janus-all` | `janus-all` | `janus-all` |
| `kafka.failOnDataLoss` | `false` | `false` | `true` | `false` | `true` |
| `kafka.maxOffsetsPerTrigger` | `10000000` | `100000000` | `100000000` | `100000000` | `100000000` |
| `kafka.minPartitions` | `200` | `200` | `200` | `200` | `200` |
| `db.postgres.host` | `localhost` | `emailsearch-campaign-perform-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `emailsearch-campaign-rw-na-production-db.gds.prod.gcp.groupondev.com` | `emailsearch-campaign-perform-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `emailsearch-campaign-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `db.postgres.database` | `campaignmanagement` | `campaign_perform_stg` | `campaign_perform_prod` | `campaign_perform_stg` | `campaign_perform_prod` |
| `db.clean.frequency` | `1 minute` | `1 hour` | `1 hour` | `1 hour` | `1 hour` |
| `db.clean.retention` | `7 days` | `7 days` | `7 days` | `7 days` | `7 days` |
| `spark.cache.longRetention` | `24 hours` | `24 hours` | `24 hours` | `24 hours` | `24 hours` |
| `spark.cache.shortRetention` | `10 minutes` | `10 minutes` | `10 minutes` | `10 minutes` | `10 minutes` |
| `metrics.influxDB.url` | `http://localhost:8086` | (default `localhost:8186`) | (default `localhost:8186`) | `http://telegraf.us-central1.conveyor.stable.gcp.groupondev.com` | `http://telegraf.production.service` |
| `is_cloud` | `false` | `false` | `false` | `true` | `true` |
| Kafka SSL | None | None | None | SSL (PKCS12 keystore) | SSL (PKCS12 keystore) |

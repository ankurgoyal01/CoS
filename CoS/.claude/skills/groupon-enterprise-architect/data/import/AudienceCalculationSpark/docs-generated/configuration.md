---
service: "AudienceCalculationSpark"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "command-line-args", "env-vars"]
---

# Configuration

## Overview

AudienceCalculationSpark is configured through three mechanisms: HOCON config files (Typesafe Config) loaded by config name at runtime, command-line arguments passed as a JSON string to `spark-submit`, and a single environment variable (`HADOOP_USER_NAME`) required for HDFS access. There are no external config stores (Consul, Vault) observed. Environment-specific config files are packaged in the JAR and selected by passing the config name as a Spark argument.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HADOOP_USER_NAME` | Sets the HDFS user identity for Hadoop API calls | Yes | None | Host environment (`audiencedeploy`) |
| `SPARK_HOME` | Path to Spark installation on the submitter host | Yes (runtime) | `/var/groupon/spark-2.0.1` | Host environment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `disableSADPayload` (int arg) | When > 0, skips writing PA membership to Cassandra for SAD-backed PAs | 0 (enabled) | Per job invocation |
| `disablePAPayload` (int arg) | When > 0, skips writing PA membership to Cassandra for one-time PAs (sadId == -1) | 0 (enabled) | Per job invocation |
| `realtime` (boolean arg) | When true, writes PA membership to GCP Bigtable instead of Cassandra | false | Per job invocation |
| `config.enablePayload` | When false, skips all Cassandra PA payload writes | true | Per environment config |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/production-na.conf` | HOCON | HBase namespace and table config for NA production |
| `src/main/resources/staging-na.conf` | HOCON | HBase namespace and table config for NA staging |
| `src/main/resources/uat-na.conf` | HOCON | HBase namespace and table config for NA UAT |
| `src/main/resources/gcp-bigtable-production-na.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for NA production |
| `src/main/resources/gcp-bigtable-productionCloud-na.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for NA production (cloud) |
| `src/main/resources/gcp-bigtable-productionCloud-emea.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for EMEA production (cloud) |
| `src/main/resources/gcp-bigtable-staging-na.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for NA staging |
| `src/main/resources/gcp-bigtable-stagingCloud-na.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for NA staging (cloud) |
| `src/main/resources/gcp-bigtable-stagingCloud-emea.conf` | HOCON | GCP project, Bigtable instance, and service account credentials for EMEA staging (cloud) |
| `src/main/resources/log4j.properties` | Properties | Log4j logging configuration |

### Key HBase/Bigtable Config Values

**HBase namespaces by environment** (from `*.conf` files):

| Environment | HBase namespace |
|-------------|----------------|
| Production NA | `realtime_audience` |
| Staging NA | `realtime_audience_staging` |
| UAT NA | `realtime_audience_uat` |

**HBase tables** (all environments):

| Table | Key | Column Families |
|-------|-----|----------------|
| `realtime_table` | `consumer_id` | `attributes`, `kafka_offset`, `timestamp`, `history`, `bootstrap` |
| `delta_table` | `consumer_id` | `attributes`, `timestamp` |
| `realtime_table_snapshot_history` | `table_name` | `info` |

**GCP Bigtable config** (Production NA):

| Key | Value |
|-----|-------|
| `bigtable.project` | `prj-grp-mktg-eng-prod-e034` |
| `bigtable.instance` | `grp-prod-bigtable-rtams-ins` |
| `bigtable.service-account-credentials.project` | `prj-grp-datalake-prod-8a19` |
| `bigtable.service-account-credentials.bucket` | `grpn-dnd-prod-analytics-grp-audience` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `bigtable.service-account-credentials.blobPath` | Path within GCS bucket to service account JSON key for Bigtable auth | GCS bucket (`grpn-dnd-prod-analytics-grp-audience`) |
| AMS Cloud Conveyer TLS | Mutual TLS for outbound AMS HTTPS calls | Host-managed (`CloudConveyerApplication`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production NA**: `production-na.conf` + `gcp-bigtable-production-na.conf`; AMS host `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- **Production EMEA**: `gcp-bigtable-productionCloud-emea.conf`; AMS host `https://edge-proxy--production--default.prod.eu-west-1.aws.groupondev.com`; realtime Bigtable writes skipped for EMEA
- **Staging NA**: `staging-na.conf` + `gcp-bigtable-stagingCloud-na.conf`; AMS host `https://edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com`
- **UAT NA**: `uat-na.conf`; AMS host `http://audience-app1-uat.snc1:9000`
- Config file selection is passed via `BigtableHandler.get(env, ...)` where `env` maps to config file name prefix (e.g. `productionCloud-na`, `stagingCloud-na`)

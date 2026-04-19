---
service: "AudiencePayloadSpark"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "cli-args"]
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Configuration

## Overview

AudiencePayloadSpark uses JSON configuration files bundled inside the fat JAR (under `src/main/resources/`) that are loaded at runtime by `ConfigFactory` based on the `--env` CLI argument. There are separate config files per environment and per region (`staging-na`, `staging-emea`, `uat-na`, `uat-emea`, `production-na`, `production-emea`, `productionCloud-na`, `productionCloud-emea`, `stagingCloud-na`, `stagingCloud-emea`). AWS Keyspaces connection is additionally configured via DataStax driver `.conf` files also bundled in the JAR. GCP Bigtable connection is configured via `.conf` files per environment. CA attributes use a separate config directory `caAttributesConfigs/`.

## Environment Variables

> No evidence found in codebase of runtime environment variable configuration beyond what is available from the Spark YARN cluster environment.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HADOOP_USER_NAME` | Hadoop/HDFS user identity for Spark job execution | yes | `audiencedeploy` | `.ci.yml` / Fabric scripts |
| `SPARK_LOCAL_IP` | Local IP binding for Spark driver in CI | no | `127.0.0.1` | `.ci.yml` |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `enablePayload` | Enables or disables payload writing; present in all env JSON configs | `true` | per-environment |
| `enableDCAware` | Enables Cassandra DC-aware load balancing policy | `true` | per-environment |
| `calibration` | CA Redis writer: full reconciliation mode instead of delta mode | `false` | per-job invocation (CLI `-c` flag) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/production-na.json` | JSON | Production NA payload config (Cassandra hosts, Keyspaces, Hive DB, AMS host, attribute columns) |
| `src/main/resources/production-emea.json` | JSON | Production EMEA payload config |
| `src/main/resources/productionCloud-na.json` | JSON | Production Cloud NA payload config |
| `src/main/resources/productionCloud-emea.json` | JSON | Production Cloud EMEA payload config |
| `src/main/resources/staging-na.json` | JSON | Staging NA payload config |
| `src/main/resources/staging-emea.json` | JSON | Staging EMEA payload config |
| `src/main/resources/stagingCloud-na.json` | JSON | Staging Cloud NA payload config |
| `src/main/resources/stagingCloud-emea.json` | JSON | Staging Cloud EMEA payload config |
| `src/main/resources/uat-na.json` | JSON | UAT NA payload config |
| `src/main/resources/uat-emea.json` | JSON | UAT EMEA payload config |
| `src/main/resources/aws-keyspaces-production-na.conf` | HOCON | DataStax driver config for production NA Keyspaces (endpoint, SSL, timeouts) |
| `src/main/resources/aws-keyspaces-production-emea.conf` | HOCON | DataStax driver config for production EMEA Keyspaces |
| `src/main/resources/aws-keyspaces-productionCloud-na.conf` | HOCON | DataStax driver config for production cloud NA |
| `src/main/resources/gcp-bigtable-production-na.conf` | HOCON | GCP Bigtable project/instance for production NA |
| `src/main/resources/gcp-bigtable-productionCloud-na.conf` | HOCON | GCP Bigtable project/instance for production cloud NA |
| `src/main/resources/gcp-bigtable-staging-na.conf` | HOCON | GCP Bigtable project/instance for staging NA |
| `src/main/resources/caAttributesConfigs/ca-user-attribute-names-na.json` | JSON | CA attribute column names for NA user attributes |
| `src/main/resources/caAttributesConfigs/ca-user-attribute-names-emea.json` | JSON | CA attribute column names for EMEA user attributes |
| `src/main/resources/caAttributesConfigs/ca-bcookie-attribute-names.json` | JSON | CA attribute column names for bcookie attributes |
| `src/main/resources/caAttributesConfigs/productionCloud-na.json` | JSON | CA attributes config (Hive tables, Redis host, sample rate) for production cloud NA |
| `src/main/resources/caAttributesConfigs/staging-na.json` | JSON | CA attributes config for staging NA |
| `src/main/resources/log4j.properties` | Properties | Log4j logging configuration |
| `src/main/resources/cassandra_truststore.jks` | JKS | TrustStore for SSL connections to AWS Keyspaces |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `accessKeyId` / `secretAccessKey` (in JSON config) | AWS IAM credentials for Keyspaces authentication | Bundled in versioned JSON config files |
| `truststore-password` (in `.conf`) | TrustStore password for Keyspaces SSL | HOCON config (value: `cassandra`) |
| GCP service account JSON | GCP Bigtable authentication | GCS bucket path in `.conf` files (`grpn-dnd-prod-analytics-grp-audience/user/databreakers/`) |

> Secret values (AWS keys) are stored directly in bundled JSON config files. This is a known security concern — values should not be republished.

## Per-Environment Overrides

| Config Key | Staging NA | Production NA | Production Cloud NA |
|------------|-----------|---------------|---------------------|
| `amsHost` | `edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` | Same as production NA |
| `cassKeyspace` | `ams_staging` | `ams` | `ams` |
| `cassSADKeyspace` | `ams_staging_sad` | `ams_sad` | `ams_sad` |
| `hiveDb` | `ams_staging` | `ams` | `ams` |
| `localDC` | `SNC2` | `SNC1` | `SNC1` |
| `awsRegion` | `us-west-1` | `us-west-1` | `us-west-1` |
| Bigtable instance | `grp-stable-bigtable-rtams-ins` | `grp-prod-bigtable-rtams-ins` | `grp-prod-bigtable-rtams-ins` |
| Redis host | `consumer-authority-user--redis.staging.stable.us-west-1.aws.groupondev.com` | `consumer-authority-user--redis.prod.prod.us-west-1.aws.groupondev.com` | Same |
| CA `sampleRate` | `0.01` | `1` (full) | `1` (full) |

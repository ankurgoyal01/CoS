---
service: "consumer-authority"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [cli-args, config-files, env-vars]
---

# Configuration

## Overview

Consumer Authority is a Spark batch application launched from the command line. Job configuration is supplied primarily through command-line arguments at startup, controlling job mode (daily vs. backfill), region (NA/INTL/GBL), run date, and attribute definitions. Additional settings for Spark session tuning, Hive Metastore connectivity, and external endpoint addresses are supplied via Spark configuration and standard Hadoop configuration files deployed to the cluster.

## Environment Variables

> No evidence found. Specific environment variable names are not visible in the architecture model. The variables below represent the categories expected for a service of this type; exact names should be confirmed with the service owner.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JAVA_HOME` | Java runtime location on the cluster node | yes | Set by cluster provisioning | env |
| `HADOOP_CONF_DIR` | Path to Hadoop/YARN cluster configuration | yes | Set by cluster provisioning | env |
| `HIVE_METASTORE_URI` | Hive Metastore Thrift URI for table metadata | yes | None | env |
| `HOLMES_PUBLISHER_ENDPOINT` | Message Bus endpoint for consumer-attribute event publishing | yes | None | env |
| `AMS_API_BASE_URL` | Audience Management Service HTTP base URL for metadata pushes | yes | None | env |
| `SMTP_HOST` | SMTP relay hostname for operational alert emails | no | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

> No evidence found. Explicit feature flag infrastructure is not visible in the architecture model. Job-mode flags (e.g., daily vs. backfill, region selection) are passed as CLI arguments rather than as runtime feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `core-site.xml` | XML | Hadoop core configuration — `fs.defaultFS` and HDFS settings (cluster-deployed) |
| `hive-site.xml` | XML | Hive Metastore URI and session settings (cluster-deployed) |
| `spark-defaults.conf` | properties | Spark session defaults — executor memory, parallelism, serializer (cluster-deployed) |
| `build.sbt` | SBT DSL | Project definition, dependency versions, assembly settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Kerberos keytab | Authentication to HDFS and Hive Metastore | Cluster-managed (Kerberos KDC) |
| Holmes publisher credentials | Authentication to Message Bus for event publishing | > No evidence found — managed by cluster/deployment |
| AMS API credentials | Authentication to Audience Management Service HTTP API | > No evidence found — managed by cluster/deployment |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Job behavior differs across environments primarily through CLI argument values and cluster-specific Hadoop/Spark configuration files rather than a per-environment config management system. The region parameter (`--region NA|INTL|GBL`) selects which output table (`user_attrs`, `user_attrs_intl`, `user_attrs_gbl`) is written and which source partitions are processed. Run date is supplied explicitly via CLI, allowing backfill runs to override the default daily date.

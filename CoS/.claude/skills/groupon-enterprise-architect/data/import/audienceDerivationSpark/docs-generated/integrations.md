---
service: "audienceDerivationSpark"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

Audience Derivation Spark depends on five external infrastructure systems within Groupon's Hadoop/Cerebro cluster: YARN (job scheduling), HDFS (config and data storage), Hive Metastore (table registry), Cassandra (payload output writes), and Bigtable ingestion (delta attribute uploads). It also depends on two internal Groupon services: the AMS API (for field metadata synchronization) and `AudiencePayloadSpark` (as a compiled JAR dependency for payload write utilities). All dependencies are consumed synchronously within Spark job execution; no circuit breakers or retry frameworks are observable in the operations scripts.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| YARN Cluster | Apache Spark on YARN | Distributed job scheduling and execution | yes | `yarnCluster` |
| HDFS | HDFS | Configuration file storage and output table data | yes | `hdfsStorage` |
| Hive Metastore | Spark SQL with Hive support | Source and derived audience table storage | yes | `hiveMetastore` |
| Cassandra Cluster | Spark Cassandra connector | Audience payload output writes | yes | `cassandraCluster` |
| Bigtable Ingestion Pipeline | Payload upload pipeline | Delta attribute uploads for user and bcookie records | yes | `bigtableIngestion` |
| Splunk | Log4j / Filebeat | Execution log aggregation and search | no | `splunkLogging` |

### YARN Cluster Detail

- **Protocol**: Apache Spark on YARN (`--master yarn --deploy-mode cluster`)
- **Base URL / SDK**: YARN Resource Manager at `http://cerebro-resourcemanager-vip.snc1:8088/ws/v1/cluster/apps` (evidenced in `resourcemanager_util.py`)
- **Auth**: Service account `audiencedeploy`; jobs submitted via `spark-submit` from `cerebro-audience-job-submitter1.snc1` (production) or `cerebro-audience-job-submitter3.snc1` (staging/UAT)
- **Purpose**: Schedules and runs Spark executors for derivation jobs; dynamic allocation with 5–10 executors per job
- **Failure mode**: Job submission fails; cron log captures error; no automatic retry
- **Circuit breaker**: No

### HDFS Detail

- **Protocol**: Hadoop HDFS CLI (`hdfs dfs`) for config uploads; Spark native HDFS client for job reads/writes
- **Base URL / SDK**: `hdfs://cerebro-namenode/user/audiencedeploy/derivation/` (evidenced in `fabfile.py`)
- **Auth**: Kerberos / service account `audiencedeploy`
- **Purpose**: Stores derivation YAML configuration and serves as backing store for Hive table data
- **Failure mode**: Config upload fails during deploy; Spark job fails to read YAML at startup
- **Circuit breaker**: No

### Hive Metastore Detail

- **Protocol**: Spark SQL with Hive support (`spark-hive` dependency); Thrift-based Hive Metastore connection
- **Base URL / SDK**: Hive metastore host/port passed as CLI args (`-h`, `-p`) to AudienceDerivationMain
- **Auth**: Kerberos / service account `audiencedeploy`; `hive-site.xml` passed as `--files` to spark-submit
- **Purpose**: Reads all source tables (`prod_groupondw.*`, `cia_realtime.*`); registers derived output tables
- **Failure mode**: SQL tempview step fails; Spark job aborts with exception; no partial writes
- **Circuit breaker**: No

### Cassandra Cluster Detail

- **Protocol**: Spark Cassandra connector (from `audiencepayloadspark` dependency)
- **Auth**: Credential configuration within `audiencepayloadspark` library (not directly in this repo)
- **Purpose**: Writes audience payload output records for downstream consumer delivery systems
- **Failure mode**: Payload write fails; Spark job stage fails
- **Circuit breaker**: No

### Bigtable Ingestion Detail

- **Protocol**: Payload upload pipeline (from `audiencepayloadspark` dependency)
- **Purpose**: Uploads delta user and bcookie attributes for downstream serving
- **Failure mode**: Upload stage fails; Spark job stage fails
- **Circuit breaker**: No

### Splunk Detail

- **Protocol**: Log4j / Filebeat log shipping
- **Base URL / SDK**: Log source: `/var/groupon/log/gdoop/audiencederivation-Main.log` on Cerebro nodes (evidenced in README)
- **Purpose**: Execution log aggregation; operators search with `sourcetype=gdoop_app host="cerebro-*"` queries
- **Failure mode**: Log search unavailable; no impact on job execution
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AMS API (`amsApi`) | HTTP / gRPC | Fetches current system table name; receives field metadata sync writes after derivation | `amsApi` |
| AudiencePayloadSpark | Compiled JAR dependency (SBT) | Provides Cassandra and Bigtable write utilities used within Spark jobs | `audiencepayloadspark` on Nexus |

### AMS API Detail

- **Protocol**: HTTP / gRPC (evidenced by `grpc-netty` and `grpc-okhttp` dependencies in `build.sbt`)
- **Auth**: Internal service-to-service (credential configuration not visible in this repo)
- **Purpose**: (1) Retrieves the current AMS system table name before derivation begins; (2) Receives updated field metadata after successful derivation run
- **Failure mode**: Field sync is a best-effort post-derivation step; derivation output is unaffected if AMS API is unavailable
- **Circuit breaker**: No evidence found

### AudiencePayloadSpark Detail

- **Protocol**: Compiled Maven/SBT dependency (`com.groupon.audiencemanagement:audiencepayloadspark:1.56.9-SNAPSHOT` from Nexus)
- **Purpose**: Encapsulates Cassandra connector and Bigtable write logic reused across audience Spark applications
- **Failure mode**: If JAR is not published to Nexus, CI build fails (documented in README)

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Derived Hive tables (`users_derived_*`, `bcookie_derived_*`) are consumed by:
- Audience payload delivery pipelines (Cassandra writes for email/push targeting)
- CRM campaign systems reading audience attributes for segmentation
- Bigtable ingestion pipeline for delta attribute serving

## Dependency Health

No health check endpoints or automated dependency health verification are implemented in this service. Operators check job status via YARN Resource Manager API (`resourcemanager_util.py`) and Splunk log queries. Dependency availability is verified implicitly by job success/failure; failed jobs are logged to the cron log at `/home/audiencedeploy/ams/derivation/derivation_cron.log`.

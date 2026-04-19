---
service: "campaign-performance-spark"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

Campaign Performance Spark has five runtime integration points: two internal Groupon systems (Janus Kafka event stream and the Campaign Performance PostgreSQL database) and three infrastructure dependencies (HDFS/GCS distributed storage, Telegraf/InfluxDB metrics pipeline, and the Janus schema service for Avro decoding). There is no inbound integration — no other service calls this job directly.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka (`janus-all` topic) | Kafka (Spark Structured Streaming) | Ingest Janus user-event stream | yes | `janusTier1Topic` |
| HDFS / GCS | Hadoop FileSystem API / GCS connector | Checkpoint, status marker, and dedup cache persistence | yes | `hdfsStorage` |
| Telegraf / InfluxDB | HTTP (InfluxDB line protocol) | Emit processing and lag metrics for Wavefront dashboards | no | (metrics pipeline) |

### Kafka (`janus-all`) Detail

- **Protocol**: Kafka (Spark Structured Streaming `kafka` format, `spark-sql-kafka-0-10`)
- **Broker (on-prem production)**: `kafka-aggregate.snc1:9092`
- **Broker (GCP production)**: `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`
- **Auth**: SSL (PKCS12 keystore at `/var/groupon/cm-performance-keystore.jks`, truststore at `/var/groupon/truststore.jks`) on GCP environments; plaintext on on-prem
- **Purpose**: Primary data source; all campaign metric processing begins with events from this topic
- **Failure mode**: `failOnDataLoss=true` in production (the job fails and must be restarted); `failOnDataLoss=false` in staging/development
- **Circuit breaker**: None — Spark's checkpoint and retry mechanism handles transient failures

### HDFS / GCS Detail

- **Protocol**: Hadoop FileSystem API (HDFS for on-prem Cerebro; GCS connector for GCP environments)
- **Base paths**: `hdfs://cerebro-namenode/user/grp_gdoop_pmp/` (on-prem); `gs://grpn-dnd-{env}-analytics-grp-pmp/` (GCP)
- **Auth**: Kerberos/YARN credentials on Cerebro; GCS service account via YARN on GCP
- **Purpose**: Stores Spark streaming checkpoints, app status marker file, and Parquet-based dedup cache
- **Failure mode**: Job will throw `RuntimeException` on filesystem access errors, causing streaming query failure

### Telegraf / InfluxDB Detail

- **Protocol**: HTTP (InfluxDB write endpoint)
- **Base URL (on-prem dev)**: `http://localhost:8086`
- **Base URL (GCP production)**: `http://telegraf.production.service`
- **Base URL (GCP staging)**: `http://telegraf.us-central1.conveyor.stable.gcp.groupondev.com`
- **Auth**: None (internal network)
- **Purpose**: Receives `dbBatchWrite`, `cacheRefresh`, `deduppedCount`, `dbClean`, `dbCleanNumDeleted`, and `kafka.lag` metrics; surfaced in Wavefront dashboards
- **Failure mode**: Metrics emission failure is non-fatal; the application logs an error but continues processing

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Campaign Performance Postgres | JDBC (PostgreSQL 42.2.5 driver) | Write campaign metrics and Kafka offsets; read offsets for lag computation | `continuumCampaignPerformanceDb` |
| Janus Schema Service | HTTPS (via `janus-thin-mapper` SDK) | Fetch Avro schema definitions for decoding Janus event payloads | (Janus service — schema lookup at startup) |

### Campaign Performance Postgres Detail

- **Protocol**: JDBC via `jtier-jdbi` and `jtier-daas-postgres`
- **Host (production on-prem)**: `emailsearch-campaign-rw-na-production-db.gds.prod.gcp.groupondev.com`
- **Host (GCP production)**: `emailsearch-campaign-rw-na-production-db.gds.prod.gcp.groupondev.com`
- **Database (production)**: `campaign_perform_prod`; (staging): `campaign_perform_stg`
- **Auth**: Username/password from secrets file (`secrets-production.conf` / `secrets-staging.conf`)
- **Purpose**: Persist metric aggregates and offsets; supports DB-offset-based recovery at restart
- **Failure mode**: JDBC write failures surface as exceptions in the `foreachPartition` call, causing the micro-batch to fail and Spark to retry

### Janus Schema Service Detail

- **Protocol**: HTTPS via `janus-thin-mapper` SDK (`SchemaRepository`)
- **Base URL (GCP production)**: `https://edge-proxy--production--default.prod.us-west-2.aws.groupondev.com`
- **Domain (GCP production)**: `janus-web-cloud.production.service`
- **Auth**: SSL (same keystore/truststore as Kafka consumer on GCP)
- **Purpose**: Resolves Avro schema IDs embedded in Janus Kafka messages to enable payload deserialization
- **Failure mode**: Schema resolution failure at startup prevents job from processing events

## Consumed By

> Upstream consumers are tracked in the central architecture model. The `campaign-performance-app` (Jtier API) reads from `continuumCampaignPerformanceDb` to serve campaign performance query results.

## Dependency Health

- **Kafka lag** is monitored continuously by `KafkaLagChecker` (runs every 1 minute via cron); emits `kafka.lag` metric per partition to Telegraf
- **Spark job liveness** is monitored via a Wavefront alert on the status marker file and YARN application state (alert: "Campaign Performance Spark Job Active")
- **Database health** is monitored via Wavefront alert "Campaign Performance High DB Latency"; the `dbBatchWrite` timer metric reflects per-batch write latency
- No explicit circuit breakers are implemented; failures propagate as Spark task/stage failures, which trigger Spark's built-in retry

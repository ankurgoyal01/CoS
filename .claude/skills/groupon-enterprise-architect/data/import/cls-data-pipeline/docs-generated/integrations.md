---
service: "cls-data-pipeline"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 5
---

# Integrations

## Overview

The CLS Data Pipeline integrates with five infrastructure platforms and five internal Groupon services. All integrations are one-directional from the pipeline's perspective: it consumes from Kafka, writes to Hive/HDFS, checks YARN application status, and sends alerts via SMTP. There are no outbound REST or gRPC calls. Integration with the Janus schema registry is used for Avro schema URL resolution at job startup.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apache Kafka (NA) | Kafka consumer | Reads PTS and GSS events from `kafka-aggregate.snc1:9092`; Proximity from `kafka.snc1:9092` | yes | `kafkaPlatform` |
| Apache Kafka (EMEA) | Kafka consumer | Reads PTS, Proximity, and GSS events from `kafka.dub1:9092` | yes | `kafkaPlatform` |
| Apache Kafka (output) | Kafka producer | Publishes normalized records to `cls_coalesce_pts_na` on `kafka.snc1:9092` | yes | `kafkaPlatform` |
| Apache Hive / HDFS | Spark SQL / HDFS API | Reads and writes partitioned ORC tables in `grp_gdoop_cls_db`; stores ML model artifacts | yes | `hiveMetastorePlatform`, `hdfsDataPlatform` |
| SMTP Relay | SMTP | Sends pipeline failure alerts via `smtp.snc1` to on-call email recipients | no | `smtpRelay` |

### Kafka (Input — NA) Detail

- **Protocol**: Kafka consumer (Spark Streaming Kafka 0-10 direct stream)
- **Base URL / SDK**: `kafka-aggregate.snc1:9092` (PTS NA, GSS NA); `kafka.snc1:9092` (Proximity NA)
- **Auth**: No auth configured in source code (internal network)
- **Purpose**: Provides the raw Loggernaut-encoded consumer location events for all three NA-region pipeline jobs
- **Failure mode**: Spark Streaming job fails and YARN marks application as failed; `PipelineMonitorJob` detects the non-running state and pages on-call
- **Circuit breaker**: No

### Kafka (Input — EMEA) Detail

- **Protocol**: Kafka consumer (Spark Streaming Kafka 0-10 direct stream)
- **Base URL / SDK**: `kafka.dub1:9092`
- **Auth**: No auth configured in source code (internal network)
- **Purpose**: Provides raw consumer location events for PTS EMEA, Proximity EMEA, and GSS EMEA pipelines
- **Failure mode**: EMEA streaming job fails; monitored by `PipelineMonitorJob`
- **Circuit breaker**: No

### Kafka (Output) Detail

- **Protocol**: Kafka producer (Spark SQL `kafka` sink via `spark-sql-kafka-0-10`)
- **Base URL / SDK**: `kafka.snc1:9092` (configured via `--output_kafka_broker`)
- **Auth**: No auth configured in source code
- **Purpose**: Publishes normalized, transformed location records to `cls_coalesce_pts_na` for downstream coalescing consumers; enabled only when `--enableKafkaOutput` flag is passed
- **Failure mode**: Kafka write errors result in Spark task failure and micro-batch retry
- **Circuit breaker**: No

### Hive / HDFS Detail

- **Protocol**: Spark SQL (HiveQL) for table reads/writes; Hadoop FileSystem API for ML model save/load
- **Base URL / SDK**: Configured via `--files /var/groupon/spark-2.4.0/conf/hive-site.xml` in spark-submit
- **Auth**: Kerberos / service account `svc_cls` (inferred from SSH user in deployment commands)
- **Purpose**: Primary persistence layer for all normalized location history tables and ML model artifacts
- **Failure mode**: Table write failures cause micro-batch to fail; data for that batch is lost (no retry mechanism documented)
- **Circuit breaker**: No

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: `smtp.snc1` (hardcoded in `EmailSender.createMessage`)
- **Auth**: None (internal relay, unauthenticated)
- **Purpose**: Delivers pipeline failure alert emails from `noreply@groupon.com` to configured pager/email recipients
- **Failure mode**: Silent — email send failure would result in uncaught exception in `PipelineMonitorJob`
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Push Token Service (PTS) | Kafka (upstream producer) | Publishes `mobile_notifications` topic events containing device token and location data | `ptsService` |
| Proximity Service | Kafka (upstream producer) | Publishes `mobile_proximity_locations` topic events with geofence-detected user coordinates | `proximityService` |
| Global Subscription Service (GSS) | Kafka (upstream producer) | Publishes `global_subscription_service` topic events for division subscription changes | `gssService` |
| Janus Schema Registry | SDK (`janus-mapper 1.13`) | Resolves Avro schema URLs used by `kafka-message-serde` for Loggernaut event decoding | — |
| YARN / Cerebro (Spark runtime) | YARN CLI / spark-submit | Executes Spark Streaming and batch jobs; `PipelineMonitorJob` queries YARN via `yarn application -status` shell command | `sparkRuntimePlatform` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The pipeline's Hive table outputs are consumed by the CLS Optimus jobs (separate subservice `consumer-location-service-data-pipeline::optimus`) and downstream analytics workflows. The `cls_coalesce_pts_na` Kafka topic output is consumed by further CLS coalescing jobs.

## Dependency Health

No circuit breakers or explicit retry policies are implemented. Health is monitored by the `PipelineMonitorJob`, which polls YARN application status via `yarn application -status <app_id>` on a scheduled basis. If any registered job is found in a non-`RUNNING` state, an email/pager alert is sent to `consumer-location-service@groupon.pagerduty.com`. Manual restart is required for all failed jobs.

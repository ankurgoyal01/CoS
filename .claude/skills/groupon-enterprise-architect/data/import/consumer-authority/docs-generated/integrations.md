---
service: "consumer-authority"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 9
internal_count: 1
---

# Integrations

## Overview

Consumer Authority integrates with nine external systems and one internal Continuum service. External dependencies cover job orchestration (Airflow, Cerebro Job Submitter), shared data infrastructure (Hive Warehouse, HDFS, ZooKeeper), event publishing (Message Bus), notifications (SMTP Relay), and observability (logging, metrics, tracing stacks). The single internal Continuum dependency is the Audience Management Service, which receives attribute metadata updates via HTTP after each run.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Airflow | schedule trigger | Triggers daily and backfill batch runs | yes | stub |
| Cerebro Job Submitter | job submission | Submits Spark jobs to the production Hadoop/YARN cluster | yes | stub |
| Hive Warehouse | Hive Metastore | Source table and partition metadata | yes | `hiveWarehouse` |
| HDFS Storage | HDFS | Managed table data files (read and write) | yes | `hdfsStorage` |
| ZooKeeper | coordination | Distributed coordination for Spark/Hadoop cluster operations | yes | stub |
| Message Bus (Kafka) | Kafka (Holmes publisher) | Publishes consumer-attribute events | yes | `messageBus` |
| SMTP Relay | SMTP | Operational email and pager alerts | no | `smtpRelay` |
| Logging Stack | SDK | Application and job log aggregation | no | `loggingStack` |
| Metrics / Tracing Stack | SDK | Runtime and pipeline metrics; distributed traces | no | `metricsStack`, `tracingStack` |

### Airflow Detail

- **Protocol**: External scheduler (DAG-based cron trigger)
- **Base URL / SDK**: Managed externally; triggers `cdeJobOrchestrator` via Cerebro Job Submitter
- **Auth**: > No evidence found
- **Purpose**: Schedules daily and backfill execution runs on a defined cron cadence
- **Failure mode**: Job does not execute; no attributes computed for that run date
- **Circuit breaker**: No

### Cerebro Job Submitter Detail

- **Protocol**: Spark job submission API
- **Base URL / SDK**: > No evidence found — managed by Cerebro infrastructure
- **Auth**: > No evidence found
- **Purpose**: Submits the Spark application to the production Hadoop/YARN cluster for execution
- **Failure mode**: Spark job never launches; Airflow DAG reports failure and triggers alerts
- **Circuit breaker**: No

### Hive Warehouse Detail

- **Protocol**: Hive Metastore (Thrift)
- **Base URL / SDK**: Configured via Spark's HiveContext / `spark.sql.warehouse.dir`
- **Auth**: Kerberos (standard Hadoop cluster auth)
- **Purpose**: `cdeMetadataAdapter` reads table schema, partition layouts, and file locations before executing transformations
- **Failure mode**: Attribute pipeline cannot resolve source table metadata; job fails at dependency resolution step
- **Circuit breaker**: No

### HDFS Storage Detail

- **Protocol**: HDFS
- **Base URL / SDK**: Configured via `fs.defaultFS` / Hadoop core-site
- **Auth**: Kerberos (standard Hadoop cluster auth)
- **Purpose**: Physical read and write of Parquet/ORC data files backing Hive tables
- **Failure mode**: Spark jobs fail at I/O stage; output partitions not written
- **Circuit breaker**: No

### ZooKeeper Detail

- **Protocol**: ZooKeeper client
- **Base URL / SDK**: Configured via Hadoop cluster settings
- **Auth**: Kerberos (standard Hadoop cluster auth)
- **Purpose**: Distributed coordination for Spark/Hadoop cluster operations
- **Failure mode**: Cluster coordination disrupted; Spark job may fail to launch or execute
- **Circuit breaker**: No

### Message Bus (Kafka) Detail

- **Protocol**: Kafka (via Holmes publisher)
- **Base URL / SDK**: Holmes publisher (Kafka client)
- **Auth**: > No evidence found
- **Purpose**: `cdeExternalPublisher` publishes derived consumer-attribute signals after attribute computation completes
- **Failure mode**: Attribute data computed and written to warehouse but not propagated to downstream consumers
- **Circuit breaker**: No

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Configured via SMTP host settings
- **Auth**: > No evidence found
- **Purpose**: `cdeAlertingNotifier` sends email and pager notifications on job success, failure, or anomaly detection
- **Failure mode**: Alerts not delivered; job outcome still recorded in logs
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Audience Management Service | HTTP | Receives attribute metadata updates after each computation run | `continuumAudienceManagementService` |

### Audience Management Service Detail

- **Protocol**: HTTP (REST)
- **Base URL / SDK**: Internal Continuum service endpoint; `cdeExternalPublisher` calls the AMS API directly
- **Auth**: > No evidence found
- **Purpose**: After `cdeExternalPublisher` emits attribute events to the message bus, it also pushes attribute metadata updates (attribute definitions, availability signals) to the AMS API so downstream audience-targeting systems reflect new attribute availability
- **Failure mode**: Attribute data available in warehouse and on message bus, but AMS metadata not updated; audience targeting may use stale attribute catalog
- **Circuit breaker**: No

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Consumer Authority Warehouse (`continuumConsumerAuthorityWarehouse`) is read by marketing, personalization, and audience-targeting systems. Consumer-attribute events on the Message Bus are consumed by any downstream subscriber.

## Dependency Health

> No evidence found. Explicit health checks, retry policies, or circuit breakers for dependencies are not visible in the architecture model. Operational procedures for dependency failures should be defined by the service owner (see [Runbook](runbook.md)).

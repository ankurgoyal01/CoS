---
service: "logging-elasticstack"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumLoggingElasticsearch"
    type: "elasticsearch"
    purpose: "Primary searchable log document store with hot/warm tiered ILM-managed indices"
  - id: "messageBus"
    type: "kafka"
    purpose: "Distributed message queue for log event buffering between Filebeat and Logstash"
  - id: "metricsStack"
    type: "wavefront-tsdb"
    purpose: "Operational metrics and dashboards for platform health monitoring"
  - id: "awsS3Snapshots"
    type: "s3"
    purpose: "Elasticsearch snapshot and backup repository for index archival"
---

# Data Stores

## Overview

The Logging Elastic Stack owns and operates four data stores serving distinct purposes: Elasticsearch as the primary log document store with tiered hot/warm storage, Apache Kafka as the message buffer between ingestion and processing, Wavefront TSDB for operational metrics, and AWS S3 for long-term Elasticsearch snapshot archival. Elasticsearch is the central and most critical store, managed via Index Lifecycle Management (ILM) policies with configurable per-sourcetype retention.

## Stores

### Elasticsearch Cluster (`continuumLoggingElasticsearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `continuumLoggingElasticsearch` |
| Purpose | Primary searchable log document store; receives enriched log events from Logstash, serves search queries from Kibana and API consumers |
| Ownership | owned |
| Migrations path | > Not applicable — schema managed via index templates and ILM policies |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `<sourcetype>-<date>` index | Per-sourcetype daily or rollover-based index containing log documents | `@timestamp`, `message`, `sourcetype`, `host`, `log.level`, parsed fields per sourcetype |
| ILM policy (`/_ilm/policy`) | Defines hot/warm/delete lifecycle phases per index pattern | `min_age`, `rollover`, `shrink`, `delete` actions |
| Index template | Defines field mappings and settings for each sourcetype index pattern | `index_patterns`, `mappings`, `settings.number_of_shards` |

#### Access Patterns

- **Read**: Kibana Discover and Dashboard queries via KQL/Lucene; Python automation scripts via `elasticsearch` client for index management; direct REST API access for scripted searches
- **Write**: Logstash pipeline bulk-indexes enriched log documents via REST `_bulk` API; Python ILM management scripts create/update policies and templates
- **Indexes**: Per-sourcetype index templates define field mappings; hot/warm tier routing controlled via ILM `_tier_preference` settings

### Apache Kafka (`messageBus`)

| Property | Value |
|----------|-------|
| Type | kafka |
| Architecture ref | `messageBus` |
| Purpose | Distributed message queue buffering log events between Filebeat shippers and Logstash consumers; decouples ingestion rate from processing capacity |
| Ownership | shared |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `logging_<env>_<sourcetype>` topic | Per-environment, per-sourcetype Kafka topic for log events | Raw log message bytes, Kafka metadata (offset, partition, timestamp) |

#### Access Patterns

- **Read**: Logstash Kafka input plugin consumes topics via consumer group offset management
- **Write**: Filebeat Kafka output plugin produces events to `logging_production_<sourcetype>` topics
- **Indexes**: > Not applicable

### Wavefront TSDB (`metricsStack`)

| Property | Value |
|----------|-------|
| Type | wavefront-tsdb |
| Architecture ref | `metricsStack` |
| Purpose | Stores operational metrics emitted by Elasticsearch Watcher and Telegraf; provides dashboards and alert triggers for platform health |
| Ownership | shared |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Elasticsearch cluster metrics | JVM heap, index rate, search latency, shard health | `metric_name`, `value`, `timestamp`, `cluster_name`, `node` |
| Kafka consumer lag metrics | Logstash consumer group lag per topic/partition | `consumer_group`, `topic`, `partition`, `lag` |

#### Access Patterns

- **Read**: Wavefront dashboards and PagerDuty alert integrations
- **Write**: Telegraf agent scrapes Elasticsearch metrics and pushes to Wavefront; ES Watcher may push aggregated counts
- **Indexes**: > Not applicable

### AWS S3 Snapshots (`awsS3Snapshots`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | > No Structurizr container ID defined in inventory |
| Purpose | Long-term Elasticsearch snapshot repository; used for index backup, disaster recovery, and archival of aged-out indices |
| Ownership | shared |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Snapshot repository (`/_snapshot/<repository>`) | Registered S3 bucket as Elasticsearch snapshot target | `bucket`, `region`, `base_path` |
| Snapshot (`/_snapshot/<repository>/<snapshot>`) | Point-in-time backup of one or more indices | `indices`, `state`, `start_time`, `end_time` |

#### Access Patterns

- **Read**: Elasticsearch restore operations; boto3-based Python scripts for snapshot inventory
- **Write**: Scheduled or manual `_snapshot` API calls; boto3 used for S3-level management
- **Indexes**: > Not applicable

## Caches

> Not applicable. No caching layer is used within the logging platform.

## Data Flows

Log events flow from Filebeat → Kafka (raw event buffering) → Logstash (parsing and enrichment) → Elasticsearch (indexed storage). Aged indices transition through hot → warm → delete lifecycle phases managed by ILM policies. Elasticsearch periodically snapshots selected indices to AWS S3 for backup. Operational metrics flow from Elasticsearch Watcher and Telegraf → Wavefront for monitoring and alerting.

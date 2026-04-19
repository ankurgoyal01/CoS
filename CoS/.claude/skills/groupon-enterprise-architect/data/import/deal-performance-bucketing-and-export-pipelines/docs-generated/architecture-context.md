---
service: "deal-performance-bucketing-and-export-pipelines"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealPerformanceDataPipelines"]
---

# Architecture Context

## System Context

The Deal Performance Data Pipelines sit within the `continuumSystem` (Continuum Platform) and form the data processing backbone of Groupon's deal performance analytics. The pipelines consume raw deal event data written to GCS by upstream instance store services, enrich events with A/B experiment metadata from Janus, bucket and aggregate metrics across user dimensions, write results back to GCS for ranking pipeline consumption, and export aggregates to a managed PostgreSQL database (`continuumDealPerformancePostgres`) that powers the deal-performance-api-v2 REST API. Pipeline execution metrics are emitted to `influxDb` via Telegraf/Wavefront.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Performance Data Pipelines | `continuumDealPerformanceDataPipelines` | Batch / DataPipeline | Java, Apache Beam, Spark | 3.7 | Batch pipelines for deal performance bucketing, decoration, export, and cleanup |
| Deal Performance PostgreSQL | `continuumDealPerformancePostgres` | Database | PostgreSQL 13 | — | GDS-managed PostgreSQL storing aggregated hourly and daily deal performance data |
| InfluxDB / Wavefront | `influxDb` | Metrics | InfluxDB / Wavefront | — | Receives pipeline execution metrics via Telegraf |
| HDFS / GCS Cluster | `hdfsCluster` | Storage | GCS / HDFS | — | Object storage for raw events and bucketed output (stub in federated model) |
| Spark Cluster | `sparkCluster` | Compute | AWS EMR / YARN | — | Executes Beam pipelines in Spark mode (stub in federated model) |

## Components by Container

### Deal Performance Data Pipelines (`continuumDealPerformanceDataPipelines`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `userDealBucketingPipeline` | Reads raw deal events from GCS, decorates with geo and experiment data, buckets by user dimensions, writes Avro output to GCS | Java, Apache Beam |
| `eventDecorationPipeline` | Reads A/B experiment instance data from Janus HDFS and joins to deal events by bcookie | Java, Apache Beam |
| `dealPerformanceExportPipeline` | Reads bucketed GCS data, aggregates hourly/daily counts, writes to PostgreSQL via JDBC | Java, Apache Beam |
| `dealPerformanceDbCleaner` | Deletes stale rows from deal performance PostgreSQL tables on a scheduled basis | Java |
| `hdfsReadTransform` | Reads raw deal performance events from GCS/HDFS using Beam file IO | Apache Beam |
| `hdfsOutputTransform` | Writes bucketed Avro results to GCS output path | Apache Beam |
| `exportHdfsReadTransform` | Reads previously bucketed deal performance Avro data from GCS for export | Apache Beam |
| `jdbcWriteTransform` | Writes aggregated deal performance records to PostgreSQL via JDBC | Apache Beam, JDBC |
| `metricsPublisher` | Publishes pipeline counters, distributions, and timing metrics to InfluxDB/Wavefront via Telegraf | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealPerformanceDataPipelines` | `continuumDealPerformancePostgres` | Writes and cleans exported hourly/daily aggregates | JDBC (PostgreSQL port 5432) |
| `continuumDealPerformanceDataPipelines` | `influxDb` | Publishes pipeline execution metrics | HTTP (Telegraf endpoint) |
| `continuumDealPerformanceDataPipelines` | `hdfsCluster` | Reads raw events and writes bucketed results | GCS / HDFS API |
| `continuumDealPerformanceDataPipelines` | `sparkCluster` | Submits Beam jobs in Spark runner mode | YARN spark-submit |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumDealPerformanceDataPipelines`
- Component: `components-continuumDealPerformanceDataPipelines`

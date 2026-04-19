---
service: "janus-metric"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumJanusMetricService"]
---

# Architecture Context

## System Context

janus-metric is a batch data pipeline service within the **Continuum** platform's Data Engineering domain. It acts as a pure compute/aggregation worker: it pulls pre-validated Parquet event data from GCS buckets, runs Spark SQL aggregations to produce metric cubes, and pushes results to the Janus Metadata Service (`janus-web-cloud`). Watermark state (tracking which files have been processed) is maintained in Ultron, preventing duplicate processing across hourly DAG runs. The service has no inbound HTTP API — it is triggered exclusively by Airflow DAG schedules on Cloud Dataproc.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus Metric Service | `continuumJanusMetricService` | Batch / DataPipeline | Scala, Apache Spark, Maven | 1.0.x | Spark-based metrics aggregation service for Janus and Juno streams with Ultron-based watermarking |

## Components by Container

### Janus Metric Service (`continuumJanusMetricService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `janusVolumeQualityRunner` | Entry point for Janus volume and quality cube jobs (`JanusMetricsUltronRunner`) | Scala object |
| `janusRawMetricRunner` | Entry point for Janus raw-event audit cube jobs (`JanusMetricsRawUltronRunner`) | Scala object |
| `junoMetricRunner` | Entry point for Juno hourly volume cube jobs (`JunoMetricsUltronRunner`) | Scala object |
| `attributeCardinalityRunner` | Entry point for attribute cardinality aggregation jobs (`AttributeCardinalityJobMain`) | Scala object |
| `janusMetricComputationEngine` | Generates Janus volume, quality, and catfood cubes from Parquet inputs using Spark SQL | Spark SQL + transformations |
| `janusRawMetricEngine` | Aggregates raw event counts per source topic and event type | Spark transformations |
| `junoMetricEngine` | Generates Juno hourly volume cubes with country filtering and batch grouping | Spark SQL + transformations |
| `attributeCardinalityEngine` | Computes approximate distinct cardinality and top-N values per attribute from Jupiter data | Spark SQL + aggregations |
| `ultronDeltaManager` | Builds delta managers, file listers, and watermark state providers using the Ultron client | Ultron client integration |
| `jm_janusApiClient` | HTTPS client for Janus metric persistence endpoints (`HttpJanusClient`) | Apache HttpClient |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusMetricService` | Janus Metadata Service API | Writes metrics cubes and attribute cardinality | HTTPS / REST (JSON) |
| `continuumJanusMetricService` | Ultron State API | Reads/writes watermark state for Ultron-managed jobs | HTTPS |
| `continuumJanusMetricService` | GCS Object Storage (Parquet) | Reads Janus/Juno/raw Parquet inputs from bucket paths | GCS SDK |
| `continuumJanusMetricService` | `metricsStack` | Publishes pipeline health gauges and runtime duration metrics | InfluxDB line protocol (via Telegraf gateway) |
| `janusMetricComputationEngine` | `jm_janusApiClient` | Persists Janus volume, quality, and catfood cubes | Internal (direct call) |
| `janusRawMetricEngine` | `jm_janusApiClient` | Persists raw-event audit cubes | Internal (direct call) |
| `junoMetricEngine` | `jm_janusApiClient` | Persists Juno volume cubes | Internal (direct call) |
| `attributeCardinalityEngine` | `jm_janusApiClient` | Persists attribute cardinality results | Internal (direct call) |
| `janusMetricComputationEngine` | `ultronDeltaManager` | Uses delta watermarks and file listing for batch orchestration | Internal (direct call) |
| `janusRawMetricEngine` | `ultronDeltaManager` | Uses delta watermarks and file listing for audit orchestration | Internal (direct call) |
| `junoMetricEngine` | `ultronDeltaManager` | Uses delta watermarks and file listing for Juno orchestration | Internal (direct call) |

## Architecture Diagram References

- Component: `components-janus-metric-service`

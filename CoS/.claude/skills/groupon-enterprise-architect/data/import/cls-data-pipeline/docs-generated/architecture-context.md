---
service: "cls-data-pipeline"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumClsDataPipelineService", "continuumClsRealtimeHive", "continuumClsModelArtifactStore"]
---

# Architecture Context

## System Context

The CLS Data Pipeline sits within Groupon's Continuum platform as a data-movement and transformation tier. It acts as the bridge between real-time event producers (PTS, Proximity, GSS) and the analytical/ML layer. Upstream services publish consumer location events to Kafka; the pipeline consumes those events, normalizes them, and writes structured records to HDFS-backed Hive tables. A downstream coalescing process (Optimus jobs) reads from those tables to compute the primary user location. The pipeline also writes a coalesced stream back to Kafka (`cls_coalesce_pts_na`) for additional downstream consumers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLS Data Pipeline Service | `continuumClsDataPipelineService` | Service | Scala 2.11, Apache Spark Streaming | 2.4.0 | Spark streaming jobs that consume CLS events, transform records, and persist outputs |
| CLS Realtime Hive Tables | `continuumClsRealtimeHive` | Database | Hive/ORC | — | Partitioned ORC Hive tables storing realtime PTS, Proximity, GSS, and prediction outputs in `grp_gdoop_cls_db` |
| CLS Model Artifact Store | `continuumClsModelArtifactStore` | Storage | HDFS | — | HDFS paths storing trained RandomForest model artifacts used by prediction jobs |

## Components by Container

### CLS Data Pipeline Service (`continuumClsDataPipelineService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Ingestion Jobs | Spark Streaming jobs that subscribe to Kafka topics (PTS: `mobile_notifications`, Proximity: `mobile_proximity_locations`, GSS: `global_subscription_service`) and parse Loggernaut-encoded event frames | Scala / Spark Streaming |
| Transformation Processors | Processor classes (`PtsLocationProcessor`, `ProximityLocationProcessor`, `GssDivProcessor`) that filter, normalize field names, and produce cleaned DataFrames per pipeline source | Scala |
| Prediction Jobs | Batch jobs (`PredictionJobV4`, `TrainModelV2`) that train RandomForest regressors on coalesced location data and produce predicted latitude/longitude per device | Scala / Spark MLlib |
| Pipeline Monitoring | `PipelineMonitorJob` — queries the `pipeline_monitoring_table` in Hive, checks YARN application status for each registered job, and triggers email/pager alerts on non-running jobs | Scala |
| Kafka Writer | Publishes transformed records to downstream Kafka output topics (e.g., `cls_coalesce_pts_na`) via Spark SQL Kafka connector when `--enableKafkaOutput` flag is set | Spark SQL Kafka Connector |
| Spark Client Adapter | `DefaultSparkClient` — encapsulates SparkSession lifecycle, SQL execution, and Hive table DDL operations used across all jobs | Scala / Spark SQL |
| Notification Adapter | `EmailSender` — sends plain-text and HTML email alerts via SMTP (`smtp.snc1`) using JavaMail; used by `PipelineMonitorJob` for failure notifications | JavaMail |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `ptsService` | `kafkaPlatform` | Publishes PTS event streams to `mobile_notifications` topic | Kafka |
| `proximityService` | `kafkaPlatform` | Publishes Proximity event streams to `mobile_proximity_locations` topic | Kafka |
| `gssService` | `kafkaPlatform` | Publishes GSS event streams to `global_subscription_service` topic | Kafka |
| `continuumClsDataPipelineService` | `kafkaPlatform` | Consumes upstream Kafka topics; publishes transformed records to `cls_coalesce_pts_na` | Kafka |
| `continuumClsDataPipelineService` | `continuumClsRealtimeHive` | Writes processed and predicted datasets into partitioned Hive tables | Hive / Spark SQL |
| `continuumClsDataPipelineService` | `continuumClsModelArtifactStore` | Loads and saves RandomForest model binaries at `/user/grp_gdoop_cls/rdfV2ModelLat` and `/user/grp_gdoop_cls/rdfV2ModelLng` | HDFS |
| `continuumClsDataPipelineService` | `smtpRelay` | Sends email notifications for pipeline alerts and failures via `smtp.snc1` | SMTP |
| `predictionJobs` | `continuumClsModelArtifactStore` | Loads and saves trained model binaries | HDFS |

## Architecture Diagram References

- System context: `contexts-clsDataPipeline`
- Container: `containers-clsDataPipeline`
- Component: `clsDataPipelineService_components`

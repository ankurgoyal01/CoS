---
service: "deal-performance-bucketing-and-export-pipelines"
title: "Deal Event Bucketing"
generated: "2026-03-03"
type: flow
flow_name: "deal-event-bucketing"
flow_type: batch
trigger: "Airflow DAG task DpsUserDealBucketingTask (scheduled hourly)"
participants:
  - "continuumDealPerformanceDataPipelines"
  - "hdfsCluster"
  - "influxDb"
architecture_ref: "dynamic-continuumDealPerformanceDataPipelines"
---

# Deal Event Bucketing

## Summary

The Deal Event Bucketing flow is the core pipeline of the service. It reads raw deal event data (impressions, views, purchases, CLO claims) from GCS partitioned by date and hour, optionally joins A/B experiment instance data from Janus, applies geo-decoration (division mapping), groups events by deal ID, applies bucket dimensions (gender, distance, age, experiment ID, purchaser division, activation, country), and writes bucketed `AvroDealPerformance` Avro records back to GCS partitioned for downstream consumption. This pipeline is the replacement for Watson Analytics DDO and Deal Performance Service v1.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow DAG task `DpsUserDealBucketingTask` on `relevance-airflow`
- **Frequency**: Hourly (processes one or more recent hours per run, controlled by `dirsToScanPerRunInHours: 7`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| UserDealBucketingPipeline | Orchestrates all bucketing steps; entry point (`main` method) | `continuumDealPerformanceDataPipelines` |
| HDFSReadTransform | Reads raw deal event Avro files from GCS | `continuumDealPerformanceDataPipelines` / `hdfsCluster` |
| GeoDecorationDoFn | Decorates events with geo/division data using DivisionMapping lookup | `continuumDealPerformanceDataPipelines` |
| AbExperimentHDFSReadTransform | Reads A/B experiment instance records from Janus HDFS | `continuumDealPerformanceDataPipelines` / `hdfsCluster` |
| DecorationJoinDoFn | CoGroupByKey join of deal events with experiment instances by bcookie | `continuumDealPerformanceDataPipelines` |
| ProcessDealPerformanceDoFn | Applies bucket dimensions and computes counts per deal | `continuumDealPerformanceDataPipelines` |
| HDFSOutputDoFn | Writes partitioned bucketed Avro records to GCS | `continuumDealPerformanceDataPipelines` / `hdfsCluster` |
| MetricsPublisher | Publishes processing-delay and runtime metrics | `continuumDealPerformanceDataPipelines` / `influxDb` |

## Steps

1. **Resolve input directories**: `TimeBasedDirectoryFilter` determines which GCS date-hour partition directories to process based on `--date`, `--hour`, and `dirsToScanPerRunInHours`.
   - From: `UserDealBucketingPipeline`
   - To: GCS (`hdfsCluster`)
   - Protocol: GCS Hadoop FileSystem API

2. **Publish processing delay metrics**: For each directory, computes the lag between event timestamp and current time and emits `processing-delay` metric.
   - From: `UserDealBucketingPipeline`
   - To: `MetricsPublisher` → Wavefront/InfluxDB (`influxDb`)
   - Protocol: HTTP (Telegraf)

3. **Read raw deal events**: `HDFSReadTransform` reads `InstanceStoreAttributedDealImpression` Avro records from all resolved GCS directories and flattens into a single `PCollection<InternalDealEvent>`.
   - From: `hdfsCluster`
   - To: `UserDealBucketingPipeline`
   - Protocol: GCS Hadoop FileSystem API (Avro)

4. **Geo-decorate events**: `GeoDecorationDoFn` applies `DivisionMapping` to attach geographic division attributes to each `InternalDealEvent`.
   - From: `UserDealBucketingPipeline`
   - To: `UserDealBucketingPipeline` (in-pipeline transform)
   - Protocol: direct (in-process Beam transform)

5. **Read A/B experiment instances** (if decoration enabled): `AbExperimentHDFSReadTransform` reads `ExperimentInstance` Avro records from Janus HDFS for matching date-hour directories, filtered by `experimentNamePrefix: relevance-explore-exploit-`.
   - From: `hdfsCluster` (HDFS `janus` path)
   - To: `UserDealBucketingPipeline`
   - Protocol: HDFS API (Avro)

6. **Key events and experiments by bcookie**: Both deal events and experiment instances are keyed by `bcookie` for the join step.
   - From/To: `UserDealBucketingPipeline` (in-pipeline transform)
   - Protocol: direct (in-process Beam)

7. **Join events with experiment data**: `CoGroupByKey` joins deal events and experiment instances by bcookie. `DecorationJoinDoFn` attributes experiment IDs to matching deal events, producing `DecoratedDealEvent` records.
   - From/To: `UserDealBucketingPipeline` (in-pipeline transform)
   - Protocol: direct (in-process Beam)

8. **Group decorated events by deal ID**: All `DecoratedDealEvent` records are grouped by `dealId` for per-deal aggregation.
   - From/To: `UserDealBucketingPipeline` (in-pipeline transform)
   - Protocol: direct (in-process Beam `GroupByKey`)

9. **Apply bucket dimensions and compute counts**: `ProcessDealPerformanceDoFn` iterates bucket configurations (gender, distance, age, experimentId, purchaserDivision, activation, country) and produces `AvroDealPerformance` records with bucket IDs and count values (eventCount, soldQuantity, grossBooking, grossRevenue).
   - From/To: `UserDealBucketingPipeline` (in-pipeline transform)
   - Protocol: direct (in-process Beam)

10. **Partition and write output**: `AvroDealPerformance` records are grouped by partition key (event_source, date, hour, event_type) and written by `HDFSOutputDoFn` to GCS at path `/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source={src}/date={date}/hour={hour}/event_type={type}`.
    - From: `UserDealBucketingPipeline`
    - To: `hdfsCluster` (GCS)
    - Protocol: GCS Hadoop FileSystem API (Avro)

11. **Publish pipeline metrics**: Beam counters, distributions, and gauges are extracted from the `PipelineResult` and emitted to Wavefront via `MetricsPublisher`.
    - From: `UserDealBucketingPipeline`
    - To: `influxDb`
    - Protocol: HTTP (Telegraf)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No deal event directories found for date-hour | TimeBasedDirectoryFilter returns empty list; pipeline produces no output | Airflow task may succeed with zero records; no alert unless Wavefront detects no pipeline run for 2h |
| Experiment data (Janus) missing for date-hour | Warning logged; empty `PCollection<ExperimentInstance>` used; pipeline continues | Events bucketed without experiment attribution |
| Invalid/malformed event fields | Invalid field counter incremented; record skipped or partially processed | `[DPS V2] High Invalid Field Count` Wavefront alert fires above threshold |
| GCS write failure | Beam pipeline fails; Airflow marks task failed | Airflow retry triggered; PagerDuty/Slack alert via `darwin-offline` |

## Sequence Diagram

```
Airflow -> UserDealBucketingPipeline: spark-submit with --date --hour --env
UserDealBucketingPipeline -> GCS (hdfsCluster): Resolve and list input directories
GCS (hdfsCluster) -> UserDealBucketingPipeline: Directory listing
UserDealBucketingPipeline -> GCS (hdfsCluster): Read InstanceStoreAttributedDealImpression Avro records
GCS (hdfsCluster) --> UserDealBucketingPipeline: InternalDealEvent PCollection
UserDealBucketingPipeline -> UserDealBucketingPipeline: GeoDecorationDoFn (DivisionMapping)
UserDealBucketingPipeline -> HDFS/Janus (hdfsCluster): Read ExperimentInstance Avro records
HDFS/Janus (hdfsCluster) --> UserDealBucketingPipeline: ExperimentInstance PCollection
UserDealBucketingPipeline -> UserDealBucketingPipeline: CoGroupByKey join by bcookie (DecorationJoinDoFn)
UserDealBucketingPipeline -> UserDealBucketingPipeline: GroupByKey by dealId
UserDealBucketingPipeline -> UserDealBucketingPipeline: ProcessDealPerformanceDoFn (apply buckets, compute counts)
UserDealBucketingPipeline -> UserDealBucketingPipeline: GroupByKey by partition key
UserDealBucketingPipeline -> GCS (hdfsCluster): Write AvroDealPerformance Avro files (partitioned)
UserDealBucketingPipeline -> Wavefront (influxDb): Publish pipeline metrics
```

## Related

- Architecture dynamic view: `dynamic-continuumDealPerformanceDataPipelines`
- Related flows: [Experiment Event Decoration](experiment-event-decoration.md), [Deal Performance DB Export](deal-performance-db-export.md)

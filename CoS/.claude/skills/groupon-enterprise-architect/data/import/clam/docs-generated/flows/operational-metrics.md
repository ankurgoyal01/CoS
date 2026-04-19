---
service: "clam"
title: "Operational Metrics Reporting Flow"
generated: "2026-03-03"
type: flow
flow_name: "operational-metrics"
flow_type: scheduled
trigger: "Spark job completion and streaming query progress events (approximately every 1 minute)"
participants:
  - "continuumClamSparkStreamingJob"
  - "clamMetricsInstrumentation"
architecture_ref: "dynamic-clamHistogramAggregationFlow"
---

# Operational Metrics Reporting Flow

## Summary

CLAM reports its own operational health through two registered listeners: `ClamSparkListener` (tracks Spark job timing and speculative tasks) and `ClamStreamingQueryListener` (tracks input row counts and emits a liveness heartbeat). All metrics are submitted via the `MetricsSubmitter` abstraction from the `metrics-sma-influxdb` library and are written to the Metrics Gateway as InfluxDB line-protocol data under the namespace `custom.clam`. Each Spark executor also initialises its own `InfluxDB` connection (via `MetricsWriterSetup.setup()`) to submit per-executor metrics.

## Trigger

- **Type**: scheduled (event-driven by Spark internals)
- **Source**: Spark job lifecycle events (`onJobStart`, `onJobEnd`, `onSpeculativeTaskSubmitted`) and streaming query progress events (`onQueryProgress`) — approximately every 1 minute aligned to the `Trigger.ProcessingTime("1 minutes")` micro-batch interval
- **Frequency**: Every micro-batch (~1 min) for query progress; per Spark job for processing time

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Metrics Instrumentation — `ClamSparkListener` | Listens to Spark job lifecycle events; emits `processing-time` and `speculative-task-count` | `clamMetricsInstrumentation` |
| Metrics Instrumentation — `ClamStreamingQueryListener` | Listens to streaming query progress; emits `input-count` and `heartbeat` | `clamMetricsInstrumentation` |
| Metrics Gateway | Receives operational metric payloads via HTTP | External (`unknownMetricsGatewayEndpoint_18b7c61a`) |
| CLAM streaming executors | Emit per-executor `update-count`, `output-count`, `bad-data` counters during aggregation | `continuumClamSparkStreamingJob` |

## Steps

### Spark Job Timing (ClamSparkListener)

1. **Capture job start**: `onJobStart()` records the job ID and wall-clock start time in a `ConcurrentHashMap<Integer, Long>`.
   - From: Spark scheduler event bus
   - To: `ClamSparkListener`
   - Protocol: Spark listener callback (in-process)

2. **Compute and emit processing time**: `onJobEnd()` retrieves the stored start time, computes the duration in milliseconds, and calls `MetricsUtil.time("processing-time", Duration.ofMillis(duration), clamConfig)`. This submits a timer measurement to `MetricsSubmitter`.
   - From: `ClamSparkListener`
   - To: Metrics Gateway
   - Protocol: HTTP (InfluxDB line protocol via `MetricsSubmitter`)

3. **Emit speculative task count**: `onSpeculativeTaskSubmitted()` calls `MetricsUtil.inc("speculative-task-count", clamConfig)` each time Spark speculatively re-launches a slow task.
   - From: `ClamSparkListener`
   - To: Metrics Gateway
   - Protocol: HTTP

### Streaming Query Progress (ClamStreamingQueryListener)

4. **Receive query progress event**: Spark calls `onQueryProgress()` after each micro-batch completes. The event contains `numInputRows` (total records processed in that batch).
   - From: Spark streaming engine
   - To: `ClamStreamingQueryListener`
   - Protocol: Spark listener callback (in-process)

5. **Emit input count**: `MetricsUtil.aggregate("input-count", inputCount, clamConfig)` submits the input row count as an aggregate measurement.
   - From: `ClamStreamingQueryListener`
   - To: Metrics Gateway
   - Protocol: HTTP

6. **Load CLAM version (once)**: On the first `onQueryProgress()` call, the listener reads the version from the `/.properties` resource file (`version.clam`). This version tag is applied to subsequent heartbeat metrics.
   - From: `ClamStreamingQueryListener`
   - To: Classpath resource
   - Protocol: in-process classloader read

7. **Emit heartbeat**: An `ImmutableMeasurement` named `heartbeat` is constructed with `alive=1` and tags: `version.spark`, `version.java`, `version.clam`, `rate=60`. It is submitted via `MetricsSubmitter.submitMeasurement()`.
   - From: `ClamStreamingQueryListener`
   - To: Metrics Gateway
   - Protocol: HTTP

### Per-Executor Metrics (emitted during aggregation mapPartitions)

8. **Executor InfluxDB setup**: On the first `mapPartitions` invocation per executor, `MetricsWriterSetup.setup()` lazily opens an `InfluxDB` connection to the metrics endpoint. A JVM shutdown hook closes it on executor exit.
   - From: Executor JVM (mapPartitions)
   - To: Metrics Gateway
   - Protocol: HTTP

9. **Emit input-count.clocked**: `MetricsUtil.incAt("input-count.clocked", config, eventTime)` is called for each successfully decoded TDigest record, using the record's event time (not wall clock). This metric is used to measure Kafka consumer lag by comparing event time against wall time.
   - From: Executor (TDigestDecoder)
   - To: Metrics Gateway
   - Protocol: HTTP

10. **Emit update-count**: `MetricsUtil.inc("update-count", config)` is called by `TDigestStateFunction` whenever an existing group state is merged with new data.
    - From: Executor (TDigestStateFunction)
    - To: Metrics Gateway
    - Protocol: HTTP

11. **Emit output-count**: `MetricsUtil.inc("output-count", config)` is called for each `StatisticsBean` emitted by `TDigestStateFunction`.
    - From: Executor (TDigestStateFunction)
    - To: Metrics Gateway
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metrics Gateway unreachable | `MetricsSubmitter` logs the failure; no exception is propagated | Self-metrics are lost; streaming pipeline continues unaffected |
| `/.properties` resource file missing or unreadable | `ClamStreamingQueryListener` catches `Throwable`, logs a warning, uses `"INVALID"` as the version tag | Heartbeat is still emitted with `version.clam=INVALID` |
| InfluxDB executor connection failure | `RuntimeException` logged; executor may emit partial metrics | Operational metrics gap for that executor; pipeline continues |

## Sequence Diagram

```
SparkScheduler -> ClamSparkListener: onJobStart(jobId, time)
ClamSparkListener -> ClamSparkListener: store(jobId -> startTime)

SparkScheduler -> ClamSparkListener: onJobEnd(jobId, time)
ClamSparkListener -> MetricsSubmitter: time("processing-time", duration)
MetricsSubmitter -> MetricsGateway: POST custom.clam.processing-time

SparkStreaming -> ClamStreamingQueryListener: onQueryProgress(numInputRows)
ClamStreamingQueryListener -> MetricsSubmitter: aggregate("input-count", numInputRows)
ClamStreamingQueryListener -> MetricsSubmitter: submitMeasurement(heartbeat{alive=1})
MetricsSubmitter -> MetricsGateway: POST custom.clam.input-count
MetricsSubmitter -> MetricsGateway: POST heartbeat

SparkExecutor -> MetricsWriterSetup: setup() [once per executor]
MetricsWriterSetup -> MetricsGateway: InfluxDBFactory.connect()
SparkExecutor -> MetricsSubmitter: incAt("input-count.clocked", eventTime)
SparkExecutor -> MetricsSubmitter: inc("update-count")
SparkExecutor -> MetricsSubmitter: inc("output-count")
MetricsSubmitter -> MetricsGateway: POST custom.clam.* metrics
```

## Related

- Architecture dynamic view: `dynamic-clamHistogramAggregationFlow`
- Related flows: [Histogram Aggregation](histogram-aggregation.md), [Job Startup and Initialisation](job-startup.md)
- Runbook: [Monitoring](../runbook.md)
- Dashboards: https://groupon.wavefront.com/dashboards/clam

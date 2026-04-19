---
service: "clam"
title: "Job Startup and Initialisation Flow"
generated: "2026-03-03"
type: flow
flow_name: "job-startup"
flow_type: scheduled
trigger: "gdoop-cron YARNApplicationRestarter submits the Spark job if it is not already running"
participants:
  - "continuumClamSparkStreamingJob"
  - "clamMainEntrypoint"
  - "clamConfigurationLoader"
  - "clamMetricsInstrumentation"
  - "clamKafkaIoAdapter"
  - "clamHistogramAggregator"
architecture_ref: "dynamic-clamHistogramAggregationFlow"
---

# Job Startup and Initialisation Flow

## Summary

This flow describes how CLAM starts up and wires all of its components before the streaming pipeline begins processing. It is triggered by the gdoop-cron scheduler on every 1-minute interval when the YARN application is not detected as `RUNNING`. The Spark `main()` method initialises the Spark session, loads the YAML config, connects to InfluxDB for self-metric publishing, registers Spark and streaming listeners, and then hands off to the `HistogramAggregator` to begin the continuous streaming query. The job runs indefinitely until killed or until an unhandled `StreamingQueryException` occurs.

## Trigger

- **Type**: scheduled
- **Source**: gdoop-cron (`YARNApplicationRestarter` class) running on the job-submitter host; cron expression `0 0/1 * * * ?` (every 1 minute); YARN queue: `clam`
- **Frequency**: Only if YARN reports no `RUNNING` application named `com.groupon.metrics.Clam`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| gdoop-cron | Schedules and submits the Spark YARN job | External (not modelled) |
| Application Entrypoint (`Clam.main`) | Bootstraps the entire job | `clamMainEntrypoint` |
| Configuration Loader | Parses the YAML config file | `clamConfigurationLoader` |
| Metrics Instrumentation | Registers listeners and initialises InfluxDB connection on driver | `clamMetricsInstrumentation` |
| Kafka I/O Adapter | Instantiated and wired as both input and output for the streaming query | `clamKafkaIoAdapter` |
| Histogram Aggregator | Builds and starts the Structured Streaming pipeline | `clamHistogramAggregator` |
| HDFS Checkpoint Store | Consulted on startup to restore prior Kafka offsets and TDigest state | External (stub: `unknownSparkCheckpointStore_8af4b0ce`) |

## Steps

1. **Submit YARN application**: gdoop-cron calls `submit-clam.sh <env> <region>` which invokes `spark-submit` with `--master yarn --deploy-mode cluster --queue clam`. The JAR and config files are distributed to all YARN containers via `--files`.
   - From: gdoop-cron (job-submitter host)
   - To: YARN ResourceManager
   - Protocol: YARN application submission

2. **Start Spark session**: `SparkSession.builder().config(new SparkConf()).getOrCreate()` constructs the Spark session. All `spark.*` settings from the submission command and `sparkConfig` map are applied.
   - From: `clamMainEntrypoint`
   - To: Spark runtime
   - Protocol: in-process

3. **Load configuration**: `ClamConfig.get(configPath)` reads the distributed config file (either from `SparkFiles.get(args[0])` for on-prem cluster mode, or directly from the path for local mode). SnakeYAML parses the file into `ClamConfig`.
   - From: `clamMainEntrypoint`
   - To: `clamConfigurationLoader`
   - Protocol: in-process (filesystem read)

4. **Connect to InfluxDB (driver)**: `InfluxDBFactory.connect(metricsEndPoint)` opens a connection to the Metrics Gateway. `ConfiguredInfluxWriter` registers it as the metrics writer for the Spark driver process.
   - From: `clamMainEntrypoint`
   - To: Metrics Gateway (`http://localhost:8186` in production)
   - Protocol: HTTP

5. **Broadcast MetricsWriterSetup**: A `MetricsWriterSetup` object (holding the metrics endpoint URL) is broadcast to all Spark executors via `jsc.broadcast()`. Each executor will call `MetricsWriterSetup.setup()` lazily on first use to create its own `InfluxDB` connection.
   - From: `clamMainEntrypoint`
   - To: All Spark executors
   - Protocol: Spark broadcast variable

6. **Register Spark listener**: `ClamSparkListener` is added to the Spark context. It will track job start/end times and report `processing-time` and `speculative-task-count` metrics.
   - From: `clamMainEntrypoint`
   - To: `clamMetricsInstrumentation`
   - Protocol: in-process

7. **Register streaming query listener**: `ClamStreamingQueryListener` is added to `spark.streams()`. It will report `input-count` and `heartbeat` metrics on each query progress event.
   - From: `clamMainEntrypoint`
   - To: `clamMetricsInstrumentation`
   - Protocol: in-process

8. **Instantiate Kafka I/O Adapter**: `new KafkaIO(clamConfig, spark)` creates the adapter, which holds references to the config and Spark session but does not yet open any Kafka connections.
   - From: `clamMainEntrypoint`
   - To: `clamKafkaIoAdapter`
   - Protocol: in-process

9. **Build and start streaming query**: `HistogramAggregator.aggregate(kafkaIo, kafkaIo)` constructs the full Spark Structured Streaming DAG (read → decode → filter → watermark → groupBy → flatMapGroupsWithState → write). `KafkaIO.write()` calls `writeStream().start()`, which begins the streaming query and returns a `StreamingQuery` handle.
   - From: `clamHistogramAggregator`
   - To: `clamKafkaIoAdapter`
   - Protocol: in-process

10. **Restore checkpoint state**: Spark reads the HDFS checkpoint directory to restore committed Kafka consumer offsets and any in-flight TDigest group state from the prior run. The streaming query resumes from where it left off.
    - From: Spark runtime
    - To: HDFS (`/user/grp_gdoop_metrics/clam_spark_app/checkpoint/`)
    - Protocol: HDFS filesystem read

11. **Await termination**: `q.awaitTermination()` blocks indefinitely. The job runs until a `StreamingQueryException` is thrown (e.g., Kafka connectivity failure) or the YARN application is killed.
    - From: `clamMainEntrypoint`
    - To: Streaming query
    - Protocol: in-process blocking call

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing config file argument | `InterruptedException` thrown immediately | Job exits; gdoop-cron resubmits after 1 minute |
| Config file not found / unparseable | `IOException` thrown from `ClamConfig.get()` | Job exits with error log; gdoop-cron resubmits |
| InfluxDB connection failure at startup | `RuntimeException` from `InfluxDBFactory.connect()` | Job exits; self-metrics will not be emitted; gdoop-cron resubmits |
| StreamingQueryException during execution | Caught and rethrown from `main()`; InfluxDB and Spark context closed via `finally` block | Job exits cleanly; gdoop-cron resubmits within 1 minute |

## Sequence Diagram

```
gdoop-cron -> YARN: spark-submit com.groupon.metrics.Clam config.yaml on-prem
YARN -> Clam.main: start JVM, distribute files
Clam.main -> ClamConfig: load config.yaml
Clam.main -> MetricsGateway: InfluxDBFactory.connect()
Clam.main -> SparkContext: broadcast(MetricsWriterSetup)
Clam.main -> SparkContext: addSparkListener(ClamSparkListener)
Clam.main -> SparkSession.streams: addListener(ClamStreamingQueryListener)
Clam.main -> KafkaIO: new KafkaIO(config, spark)
Clam.main -> HistogramAggregator: aggregate(kafkaIo, kafkaIo)
HistogramAggregator -> KafkaIO: writeStream().start() — begins streaming query
KafkaIO -> HDFS: restore checkpoint state
KafkaIO --> Clam.main: StreamingQuery handle
Clam.main -> StreamingQuery: awaitTermination() [blocks indefinitely]
```

## Related

- Related flows: [Histogram Aggregation](histogram-aggregation.md), [Operational Metrics Reporting](operational-metrics.md)
- Deployment: [Deployment](../deployment.md)
- Configuration: [Configuration](../configuration.md)

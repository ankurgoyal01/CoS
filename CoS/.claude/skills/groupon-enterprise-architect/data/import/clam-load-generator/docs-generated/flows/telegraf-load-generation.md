---
service: "clam-load-generator"
title: "Telegraf Load Generation"
generated: "2026-03-03"
type: flow
flow_name: "telegraf-load-generation"
flow_type: batch
trigger: "test-target=telegraf Spring profile active at startup"
participants:
  - "influxStrategy"
  - "influxClient"
  - "metricLineFactory"
architecture_ref: "dynamic-clam-load-generation-flow"
---

# Telegraf Load Generation

## Summary

When `test-target=telegraf` is active, the `InfluxDbLoadGenerationStrategy` writes synthetic InfluxDB `Point` objects directly to a Telegraf HTTP listener. It initializes one `PartitionService` per configured thread (each using a random seed for metric name variation), opens a single shared InfluxDB connection, and then — for each batch — creates a `Line` object per thread, converts it to an InfluxDB `Point`, and writes it to the connection. With batching enabled, writes are buffered (up to 5000 actions or 500 ms flush interval) before being sent to the Telegraf endpoint. This mode is used to validate Telegraf's raw ingest throughput and aggregation behavior at high data rates (up to 20,000 ops/sec).

## Trigger

- **Type**: event
- **Source**: Spring Boot `ApplicationReadyEvent` with `test-target=telegraf` profile active
- **Frequency**: Once per JVM execution; batch loop runs until `maxOperations` or `timeout`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| InfluxDbLoadGenerationStrategy | Manages connection lifecycle, initializes partition services, and generates write operations | `influxStrategy` |
| InfluxDbClient | Creates and configures the InfluxDB HTTP client connection to `telegraf.url` with optional batch settings | `influxClient` |
| MetricLineFactory / PartitionService | Generates randomized `Line` objects (name, tags, fields, nanosecond timestamp) per thread | `metricLineFactory` |
| Telegraf HTTP listener (external) | Receives InfluxDB line-protocol `Point` writes for aggregation and forwarding | external |

## Steps

1. **Open InfluxDB connection** (`before()` phase): `InfluxDbClient.getConnection()` calls `InfluxDBFactory.connect(telegraf.url)` and sets the database to `"na"`. If `telegraf.influxDb.batch-enabled=true`, configures `BatchOptions` (actions, bufferLimit, flushDuration, error handler).
   - From: `influxStrategy`
   - To: `influxClient` → `InfluxDBFactory` → Telegraf HTTP listener (`telegraf.url`)
   - Protocol: HTTP (InfluxDB line-protocol)

2. **Initialize partition services**: Creates `config.getThreads()` `PartitionService` instances via `senderFactory.getPartitionService(randomInt)`, each seeded with a random integer for metric name distribution.
   - From: `influxStrategy`
   - To: `SenderFactory` / `PartitionService`
   - Protocol: in-process

3. **Generate operation batch** (`getNextBatch()`): For each thread index (0 to `threads-1`), creates an `Operation` lambda that will run on that thread's `PartitionService`.
   - From: `influxStrategy`
   - To: in-process operation list
   - Protocol: in-process

4. **Create metric line**: Each `Operation` calls `partitionService.createLine()` to generate a `Line` object with randomized metric name (from the `metrics.*` cluster and shared pools), dimension tags, field values, and a nanosecond timestamp.
   - From: `Operation` lambda (worker thread)
   - To: `PartitionService` / `MetricLineFactory`
   - Protocol: in-process

5. **Build InfluxDB Point**: Converts the `Line` to an `org.influxdb.dto.Point` using `Point.measurement(line.getName()).fields(line.getFields()).tag(line.getTags()).time(line.getTimestamp(), TimeUnit.NANOSECONDS).build()`.
   - From: `Operation` lambda (worker thread)
   - To: `influxdb-java` Point builder
   - Protocol: in-process

6. **Write point to Telegraf**: Calls `connection.write(point)`. With batch mode enabled, the point is queued in the InfluxDB batch buffer and flushed automatically when `batchActions` (5000) or `flushDuration` (500 ms) threshold is reached.
   - From: `Operation` lambda (worker thread)
   - To: Telegraf HTTP listener (`telegraf.url`)
   - Protocol: HTTP POST / InfluxDB line-protocol

7. **Close connection** (`after()` phase): Calls `connection.close()` to flush any remaining buffered points and terminate the HTTP connection.
   - From: `influxStrategy`
   - To: Telegraf HTTP listener
   - Protocol: HTTP (final flush)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Telegraf endpoint unreachable at connection time | `InfluxDBFactory.connect()` may succeed (lazy); first write fails | Batch error handler logs "Failed to submit points" with exception |
| Batch write error | `BatchOptions.exceptionHandler` logs the error | Points lost; load generation continues |
| Connection close failure | Exception propagates from `connection.close()` | Logged at application level; JVM exits |

## Sequence Diagram

```
InfluxDbLoadGenerationStrategy -> InfluxDbClient: getConnection()
InfluxDbClient -> InfluxDBFactory: connect(telegraf.url) + BatchOptions
InfluxDBFactory --> InfluxDbClient: InfluxDB connection
InfluxDbClient --> InfluxDbLoadGenerationStrategy: connection
InfluxDbLoadGenerationStrategy -> SenderFactory: getPartitionService(randomSeed) × threads
loop [for each batch iteration, per thread]
  OperationLambda -> PartitionService: createLine()
  PartitionService --> OperationLambda: Line (name, tags, fields, timestamp_ns)
  OperationLambda -> Point.Builder: measurement + fields + tags + time(ns)
  Point.Builder --> OperationLambda: Point
  OperationLambda -> InfluxDB: write(point)
  InfluxDB -> TelegrafHTTP: POST line-protocol (batched, 5000 actions / 500ms)
end
InfluxDbLoadGenerationStrategy -> InfluxDB: close()
InfluxDB -> TelegrafHTTP: final flush
```

## Related

- Architecture dynamic view: `dynamic-clam-load-generation-flow`
- Related flows: [Load Generation Orchestration](load-generation-orchestration.md), [Post-Load Verification](post-load-verification.md)

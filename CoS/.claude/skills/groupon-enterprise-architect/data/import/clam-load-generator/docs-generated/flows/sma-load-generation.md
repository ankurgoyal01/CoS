---
service: "clam-load-generator"
title: "SMA Load Generation"
generated: "2026-03-03"
type: flow
flow_name: "sma-load-generation"
flow_type: batch
trigger: "test-target=sma Spring profile active at startup"
participants:
  - "smaStrategy"
  - "smaMetricService"
  - "jtierMetricsAdapter"
  - "influxClient"
architecture_ref: "dynamic-clam-load-generation-flow"
---

# SMA Load Generation

## Summary

When `test-target=sma` is active, the `SmaLoadGenerationStrategy` generates Service Metrics API (SMA) measurements using the jtier metrics library and submits them via a `BufferingInfluxWriter` to a Telegraf HTTP listener. Before load generation begins, the strategy warms up the buffer by submitting dummy measurements until the `watermark` level is reached. Each batch operation then submits one `ImmutableMeasurement` (HTTP in/out metric) drawn from a randomized factory built by `SmaMetricService`. This mode validates the SMA → jtier → Telegraf write path and is the default mode when running the service as a Conveyor Cloud pod. In production load test runs (`sma-load-test` profile), it generates up to 8333 ops/sec for up to 10 minutes.

## Trigger

- **Type**: event
- **Source**: Spring Boot `ApplicationReadyEvent` with `test-target=sma` profile active
- **Frequency**: Once per JVM execution; batch loop runs until `maxOperations` or `timeout`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SmaLoadGenerationStrategy | Orchestrates warm-up, batch generation, and connection teardown | `smaStrategy` |
| SmaMetricService | Creates the `SmaMetricFactory` that generates randomized HTTP in/out measurement batches | `smaMetricService` |
| JtierMetricsConfiguration | Builds the `BufferingInfluxWriter` and OkHttp3 connection pool for the jtier SMA writer | `jtierMetricsAdapter` |
| InfluxDbClient | Creates the raw `InfluxDB` connection used by the jtier writer | `influxClient` |
| Telegraf HTTP listener (external) | Receives buffered InfluxDB line-protocol writes from the jtier writer | external |

## Steps

1. **Build OkHttp3 client** (`before()` phase): `JtierMetricsConfiguration.buildOkHttpClientBuilder()` creates an OkHttp3 `Dispatcher` (max requests: 64, max per host: 20) and `ConnectionPool` (max idle: 20, keep-alive: 5 minutes) and returns a configured `OkHttpClient.Builder`.
   - From: `smaStrategy`
   - To: `jtierMetricsAdapter`
   - Protocol: in-process

2. **Open InfluxDB connection**: `InfluxDbClient.getConnection(okHttpClientBuilder)` connects to `telegraf.url` with the configured OkHttp3 client and optional `BatchOptions`.
   - From: `smaStrategy` → `influxClient`
   - To: Telegraf HTTP listener (`telegraf.url`)
   - Protocol: HTTP connection establishment

3. **Build MeasurementWriter**: `JtierMetricsConfiguration.buildMeasurementWriter(connection)` creates a `BufferingInfluxWriter` with `OverflowPoolBufferConfig` (bufferSize: 1500, watermark: 1000, poolSize: 3). The writer is set as the `MeasurementEnvironment` default writer.
   - From: `smaStrategy` → `jtierMetricsAdapter`
   - To: `MeasurementEnvironment.setDefaultWriter(writer)`
   - Protocol: in-process

4. **Get SMA metric factory**: Calls `smaMetricService.getFactory()` to obtain a `SmaMetricFactory` configured with the endpoint/integration/integrationEndpoint counts from `sma.*` properties.
   - From: `smaStrategy`
   - To: `smaMetricService`
   - Protocol: in-process

5. **Warm up buffer**: Submits `watermark` (e.g., 1000) dummy `ImmutableMeasurement` objects with name `"warmUp"` and tag `warmUp=ignore` via `MetricsSubmitter.submitMeasurement()` to pre-fill the buffer before actual load begins.
   - From: `smaStrategy.warmUp()`
   - To: `MetricsSubmitter` → `BufferingInfluxWriter`
   - Protocol: in-process

6. **Generate operation batch** (`getNextBatch()`): Calls `smaMetricFactory.getRandomHttpInOutBatch()` to get a list of randomized `ImmutableMeasurement` objects (simulating HTTP inbound/outbound service metrics).
   - From: `smaStrategy`
   - To: `smaMetricService` / `SmaMetricFactory`
   - Protocol: in-process

7. **Submit measurements**: Each `Operation` lambda calls `MetricsSubmitter.submitMeasurement(httpInMetric)`. The `BufferingInfluxWriter` buffers the measurement; when the buffer reaches the `watermark` (1000 measurements), it flushes to Telegraf via HTTP using OkHttp3.
   - From: `Operation` lambda (worker thread) → `MetricsSubmitter`
   - To: `BufferingInfluxWriter` → Telegraf HTTP listener
   - Protocol: HTTP POST / InfluxDB line-protocol (asynchronous, via `HandoverAsyncExecutor`)

8. **Teardown** (`after()` phase): Calls `connection.close()` to flush remaining InfluxDB buffer, then `jtierMetricsConfiguration.cleanup()` to close the `HandoverAsyncExecutor`.
   - From: `smaStrategy`
   - To: Telegraf HTTP listener (final flush), `HandoverAsyncExecutor`
   - Protocol: HTTP (final flush) + in-process close

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Telegraf endpoint unreachable | OkHttp3 connection error propagates from `influxClient.getConnection()` | Application fails during `before()` phase |
| Buffer overflow (buffer > bufferSize) | `OverflowPoolBufferConfig` manages multiple pool buffers (poolSize: 3) | Overflow handled by the pool; additional overflow may be dropped silently |
| `HandoverAsyncExecutor.close()` throws `IOException` | Caught and logged as error: "error while closing handover async executor" | Cleanup proceeds; JVM exits |

## Sequence Diagram

```
SmaLoadGenerationStrategy -> JtierMetricsConfiguration: buildOkHttpClientBuilder()
JtierMetricsConfiguration --> SmaLoadGenerationStrategy: OkHttpClient.Builder
SmaLoadGenerationStrategy -> InfluxDbClient: getConnection(okHttpBuilder)
InfluxDbClient -> TelegrafHTTP: HTTP connection (telegraf.url)
TelegrafHTTP --> InfluxDbClient: connected
InfluxDbClient --> SmaLoadGenerationStrategy: InfluxDB connection
SmaLoadGenerationStrategy -> JtierMetricsConfiguration: buildMeasurementWriter(connection)
JtierMetricsConfiguration -> BufferingInfluxWriter: new(db, bufferConfig, handoverExecutor)
JtierMetricsConfiguration --> SmaLoadGenerationStrategy: MeasurementWriter
SmaLoadGenerationStrategy -> MeasurementEnvironment: setDefaultWriter(writer)
SmaLoadGenerationStrategy -> SmaMetricService: getFactory()
SmaMetricService --> SmaLoadGenerationStrategy: SmaMetricFactory
SmaLoadGenerationStrategy -> MetricsSubmitter: submitMeasurement(warmUp) × watermark
loop [for each batch iteration]
  SmaLoadGenerationStrategy -> SmaMetricFactory: getRandomHttpInOutBatch()
  SmaMetricFactory --> SmaLoadGenerationStrategy: List<ImmutableMeasurement>
  loop [for each measurement]
    OperationLambda -> MetricsSubmitter: submitMeasurement(measurement)
    MetricsSubmitter -> BufferingInfluxWriter: buffer(measurement)
    alt [buffer >= watermark]
      BufferingInfluxWriter -> HandoverAsyncExecutor: flush via OkHttp3
      HandoverAsyncExecutor -> TelegrafHTTP: POST line-protocol
    end
  end
end
SmaLoadGenerationStrategy -> InfluxDB: close()
SmaLoadGenerationStrategy -> JtierMetricsConfiguration: cleanup()
JtierMetricsConfiguration -> HandoverAsyncExecutor: close()
```

## Related

- Architecture dynamic view: `dynamic-clam-load-generation-flow`
- Related flows: [Load Generation Orchestration](load-generation-orchestration.md), [Post-Load Verification](post-load-verification.md)

---
service: "clam-load-generator"
title: "Post-Load Verification"
generated: "2026-03-03"
type: flow
flow_name: "post-load-verification"
flow_type: batch
trigger: "Completion of LoadGenerator.start(); TelegrafIntegrationVerifier or GatewayIntegrationVerifier enabled"
participants:
  - "telegrafVerifier"
  - "wavefrontClient"
  - "influxClient"
architecture_ref: "dynamic-clam-load-generation-flow"
---

# Post-Load Verification

## Summary

After `LoadGenerator.start()` completes, `LoadGeneratorApplication.afterApplicationStart()` optionally invokes one or both integration verifiers. `TelegrafIntegrationVerifier` writes a known set of metric values directly to a Telegraf endpoint, waits 60 seconds for CLAM to aggregate them, then polls Wavefront's `GET /api/v2/chart/raw` endpoint for up to 5 minutes to confirm that the aggregated output matches the expected values in `aggregation.dataExpectations`. `GatewayIntegrationVerifier` performs the same verification but sends T-Digest centroid-encoded payloads to the metrics gateway endpoint instead of raw values to Telegraf. Both verifiers are skipped unless their respective write URLs are configured (non-empty `aggregation.telegrafUrl` or `aggregation.gatewayUrl`).

## Trigger

- **Type**: event
- **Source**: `LoadGenerator.start()` completion (post-batch); conditional on `isEnabled()` returning true
- **Frequency**: Once per JVM execution, after load generation completes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TelegrafIntegrationVerifier | Writes raw timer metric values to Telegraf and verifies Wavefront aggregation | `telegrafVerifier` |
| GatewayIntegrationVerifier | Writes T-Digest encoded payloads to the metrics gateway and verifies Wavefront aggregation | `telegrafVerifier` |
| WavefrontVerifier (base class) | Manages Wavefront API client auth, query execution, polling loop, and result comparison | `telegrafVerifier` |
| Wavefront Query Client (`QueryApi`) | Generated Swagger client issuing `GET /api/v2/chart/raw` and `GET /api/v2/chart/api` | `wavefrontClient` |
| Telegraf HTTP listener / Metrics gateway (external) | Write targets for test metric values | external |
| Wavefront (external) | Source of aggregated metric timeseries for verification read-back | external |

## Steps

### Telegraf Verifier Path

1. **Check if enabled**: `telegrafIntegrationVerifier.isEnabled()` returns `true` if `aggregation.telegrafUrl` is non-empty.
   - From: `LoadGeneratorApplication`
   - To: `TelegrafIntegrationVerifier`
   - Protocol: in-process

2. **Write test metric values to Telegraf**: For each value in `aggregation.dataValues`, writes an InfluxDB `Point` with measurement `aggregation.metricName`, tag `_rollup=timer:*`, tag `service=<aggregation.serviceName>`, and `value=<number>`. Timestamp is the current time in milliseconds.
   - From: `TelegrafIntegrationVerifier`
   - To: Telegraf HTTP listener (`aggregation.telegrafUrl`)
   - Protocol: HTTP / InfluxDB line-protocol

3. **Wait for aggregation (60 seconds)**: Sleeps 60 seconds with progress output to allow CLAM to process and aggregate the metric values.
   - From: `WavefrontVerifier.verify()`
   - To: Thread sleep
   - Protocol: in-process

4. **Poll Wavefront for each expected aggregate**: For each key in `aggregation.dataExpectations`, constructs the full metric name as `<metricName>.<fieldName>.<aggregateName>` and calls `queryApi.queryRaw(metricName, null, serviceName, startTime, endTime)` where the time window is `[now - 1 minute, now + 1 minute]`.
   - From: `WavefrontVerifier`
   - To: Wavefront Query API (`GET /api/v2/chart/raw`)
   - Protocol: REST / Bearer token (`aggregation.wavefrontKey`)

5. **Retry polling loop**: If Wavefront returns empty results, retries up to 12 times with 5-second intervals (60-second maximum additional wait).
   - From: `WavefrontVerifier`
   - To: Wavefront Query API
   - Protocol: REST

6. **Assert expected values**: Compares `rawTimeseries[0].points[0].value` against the expected value from `aggregation.dataExpectations`. Logs "expectation met" or "failed" with actual vs. expected values.
   - From: `WavefrontVerifier`
   - To: stdout
   - Protocol: in-process

7. **Late data verification** (optional): If `aggregation.dataValuesLate` is non-empty, writes late-arriving metric values to Telegraf using the same timestamp as the original data and polls Wavefront for up to 24 × 5-second intervals to verify that late-arriving values are incorporated into the aggregate.
   - From: `TelegrafIntegrationVerifier.testLateData()`
   - To: Telegraf + Wavefront
   - Protocol: HTTP / REST

### Gateway Verifier Path

Steps 1–7 are the same flow structure. The key differences are:

- **Write step**: Instead of raw `value` fields, writes an InfluxDB `Point` containing T-Digest encoded centroid data: `compression` (30), `sum._utility` (sum of `aggregation.dataValues`), and `centroids` (AVL-tree digest string). Tags include `bucket_key` (random UUID), `aggregates` (comma-joined expectation keys), and `service`.
- **Write target**: `aggregation.gatewayUrl` instead of `aggregation.telegrafUrl`.
- **Metric name prefix**: Verification queries use `<metricName>.<aggregateName>` (no field name segment).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Verifier `isEnabled()` returns false (URL is empty) | Verifier is skipped entirely | No verification performed; no error |
| `ApiException` from Wavefront query | Caught; stack trace printed to stderr | Verification for that aggregate is aborted |
| `InterruptedException` during sleep | Caught; stack trace printed to stderr | Verification continues with partial wait |
| Wavefront returns no data after all retries | Loop exits; `rawTimeseries.get(0)` would throw `IndexOutOfBoundsException` | Not explicitly handled — potential uncaught exception |
| Total verification time exceeds expectations | Final log: "Total time to visible in WF: X seconds. Expected (60-120)" | Informational only |

## Sequence Diagram

```
LoadGeneratorApplication -> TelegrafIntegrationVerifier: isEnabled()?
alt [telegrafUrl is non-empty]
  LoadGeneratorApplication -> TelegrafIntegrationVerifier: test()
  TelegrafIntegrationVerifier -> TelegrafHTTP: write Point(metric, value, _rollup=timer:*, service)
  TelegrafHTTP --> TelegrafIntegrationVerifier: 204 No Content
  TelegrafIntegrationVerifier -> Thread: sleep(60s)
  loop [for each aggregate in dataExpectations]
    TelegrafIntegrationVerifier -> QueryApi: queryRaw(metricName, null, service, start, end)
    QueryApi -> WavefrontAPI: GET /api/v2/chart/raw (Bearer token)
    WavefrontAPI --> QueryApi: List<RawTimeseries>
    alt [empty result, up to 12 retries]
      TelegrafIntegrationVerifier -> Thread: sleep(5s)
      TelegrafIntegrationVerifier -> QueryApi: queryRaw(...)
    end
    TelegrafIntegrationVerifier -> stdout: "met" or "failed: expected X actual Y"
  end
end
LoadGeneratorApplication -> GatewayIntegrationVerifier: isEnabled()?
alt [gatewayUrl is non-empty]
  LoadGeneratorApplication -> GatewayIntegrationVerifier: test()
  GatewayIntegrationVerifier -> GatewayHTTP: write Point(metric, tdigest-fields, bucket_key, aggregates)
  GatewayIntegrationVerifier -> WavefrontVerifier: verify(metricName)
  WavefrontVerifier -> WavefrontAPI: GET /api/v2/chart/raw (polling)
  WavefrontAPI --> WavefrontVerifier: RawTimeseries
  WavefrontVerifier -> stdout: assertion result
end
```

## Related

- Architecture dynamic view: `dynamic-clam-load-generation-flow`
- Related flows: [Telegraf Load Generation](telegraf-load-generation.md), [Load Generation Orchestration](load-generation-orchestration.md)

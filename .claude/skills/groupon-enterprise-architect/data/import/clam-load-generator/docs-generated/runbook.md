---
service: "clam-load-generator"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. The CLAM Load Generator does not expose an HTTP health check endpoint. It is a short-lived batch service; operational health is determined by observing its log output and exit code.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Process exit code | exec | On completion | Per `generator.timeout` setting |
| Log output: "Load test started." | log | On startup | — |
| Log output: "Timed out." | log | On timeout | — |

## Monitoring

### Metrics

The CLAM Load Generator itself does not expose application metrics to any monitoring system. The load generation summary is printed to standard output at completion.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `LoadGenerationSummary` (stdout) | counter | Count of SUCCESS/FAILURE operation results | Manual inspection |
| Kafka producer stats (stdout, every 120s) | gauge | `producer-metrics` and `producer-topic-metrics` groups logged by `KafkaLoadGenerationStrategy.Reporter` | Manual inspection |

### Dashboards

> No evidence found in codebase. No dashboards are defined within this repository. Monitor target-system dashboards (Telegraf, CLAM, Wavefront) to observe the effect of load generation.

### Alerts

> No evidence found in codebase. No automated alerts are configured for this service. It is a manually-triggered load testing tool.

## Common Operations

### Run a load test (JAR)

Select the appropriate profile and set required environment variables:

```
export TARGET_URL="http://telegraf-agent1-uat.snc1:8186/"
java -jar target/load-generator-1.0.0.jar --spring.profiles.active=sma-load-test
```

### Run a load test (Docker / Conveyor pod)

The default container entrypoint runs the `sma-load-test` profile. Override for other profiles:

```
docker run \
  -e TARGET_URL="http://telegraf-agent1-uat.snc1:8186/" \
  docker-conveyor.groupondev.com/metrics/pod-load-generator:1.0.0
```

### Run with a custom configuration

```
java -jar target/load-generator-1.0.0.jar \
  --spring.config.additional-location=file:./custom-config.yml
```

### Build the JAR

```
mvn clean package
```

### Stop a running load test

The service terminates automatically when `generator.max-operations` is reached or `generator.timeout` elapses. To abort manually, send `SIGTERM` to the JVM process or terminate the pod.

### Scale Up / Down

Increase `generator.threads` and `generator.rate-per-second` in the profile YAML to scale up throughput. For Kafka mode, thread count is overridden automatically to match the number of available Kafka partitions.

### Database Operations

> Not applicable. This service does not own any data stores.

## Troubleshooting

### Load test completes immediately with zero operations

- **Symptoms**: Process exits with "Load test started." and "Load test summary" showing 0 operations
- **Cause**: `generator.max-operations` set to 0 in profile (e.g., `application-kafka-minimal.yml`)
- **Resolution**: Set `generator.max-operations` to a positive value in your config

### Kafka partition discovery fails at startup

- **Symptoms**: Exception during `before()` phase: `KafkaTemplate.partitionsFor()` throws or returns empty
- **Cause**: `kafka.broker-address` is unreachable, or the configured `kafka.topic` does not exist
- **Resolution**: Verify `kafka.broker-address` is correct and reachable; confirm the topic exists on the broker

### Telegraf writes fail with connection errors

- **Symptoms**: `InfluxDB batch error` log entries; `OperationResult.FAILURE` in summary
- **Cause**: `TARGET_URL` not set or points to an unreachable Telegraf endpoint
- **Resolution**: Verify `TARGET_URL` is exported and the Telegraf HTTP listener is running at that address

### Wavefront verification times out

- **Symptoms**: "Waiting ############" printed for each metric; no "met" confirmation
- **Cause**: Metrics did not propagate from Telegraf → CLAM → Wavefront within the expected 60–120 second window, or `aggregation.wavefrontKey` is invalid
- **Resolution**: Check that the CLAM aggregation pipeline is running; verify `aggregation.wavefrontUrl` and `aggregation.wavefrontKey` are correct; increase wait time if pipeline latency is higher than expected

### SMA warm-up hangs

- **Symptoms**: Service pauses after startup for an extended period before load generation begins
- **Cause**: `jtier-metrics.metricsWriter.watermark` is high relative to `bufferSize`, requiring many warm-up measurements before the buffer flushes
- **Resolution**: Lower `watermark` value in the profile YAML, or verify that the Telegraf HTTP listener is accepting connections

### WireMock not intercepting requests

- **Symptoms**: Load test sends to the real `TARGET_URL` instead of WireMock
- **Cause**: `wiremock.enabled=false` (default) or profile does not include WireMock configuration
- **Resolution**: Set `wiremock.enabled: true` in the profile YAML; WireMock starts on port 2345 with stubs from `src/main/resources`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Load test blocking a production deployment validation | Immediate | Metrics team (#bot---metrics) |
| P2 | Load test failing to produce expected Wavefront results | 30 min | Metrics team |
| P3 | Load test producing lower-than-expected throughput | Next business day | Metrics team |

## Dependencies Health

| Dependency | Health Check | Fallback Behavior |
|------------|-------------|-------------------|
| Apache Kafka | Check broker connectivity: `kafka-topics.sh --bootstrap-server <broker> --list` | Load test aborts at `before()` phase; no partial run |
| Telegraf HTTP listener | `curl -v http://<TARGET_URL>/ping` (InfluxDB ping endpoint) | Write errors logged; summary shows FAILURE counts |
| Wavefront Query API | Query `GET <wavefrontUrl>/api/v2/chart/raw` with Bearer token | Verification phase is skipped if `aggregation.wavefrontUrl` is empty; otherwise retries up to 60 seconds |
| Metrics gateway | `curl -v <aggregation.gatewayUrl>` | Gateway verification is skipped if `aggregation.gatewayUrl` is empty |

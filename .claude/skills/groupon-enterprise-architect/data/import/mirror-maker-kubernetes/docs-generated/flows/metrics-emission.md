---
service: "mirror-maker-kubernetes"
title: "Metrics Emission"
generated: "2026-03-03"
type: flow
flow_name: "metrics-emission"
flow_type: scheduled
trigger: "60-second Telegraf scrape cycle"
participants:
  - "continuumMirrorMakerService"
  - "metricsStack"
architecture_ref: "dynamic-mirror-maker-replication-flow"
---

# Metrics Emission

## Summary

Every MirrorMaker pod runs a Telegraf sidecar container that periodically scrapes the Jolokia JMX-over-HTTP agent embedded in the MirrorMaker JVM. The scraped JMX metrics — covering consumer lag, throughput, error rates, latency, and the critical dropped-message count — are forwarded to InfluxDB for operational monitoring and alerting. This flow is fully independent of the Kafka replication loop and cannot affect replication throughput or correctness.

## Trigger

- **Type**: Schedule
- **Source**: Telegraf sidecar internal ticker (`interval = "60s"`, `round_interval = true`)
- **Frequency**: Every 60 seconds per pod

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MirrorMaker JVM (Jolokia agent) | Exposes JMX metrics as JSON over HTTP on port 8778 | `continuumMirrorMakerService` |
| Telegraf sidecar | Scrapes Jolokia, applies tags, batches up to 1000 metrics, flushes to InfluxDB | `continuumMirrorMakerService` (co-located sidecar) |
| InfluxDB (metricsStack) | Stores time-series metrics for dashboards and alerting | `metricsStack` |

## Steps

1. **Telegraf collector ticker fires**: After each 60-second interval, the Telegraf `jolokia2_agent` input plugin initiates an HTTP GET against the Jolokia agent endpoint at `http://localhost:8778/jolokia`.
   - From: Telegraf sidecar
   - To: `continuumMirrorMakerService` (Jolokia agent, port 8778)
   - Protocol: HTTP

2. **Collect consumer metrics**: Telegraf queries the following MBeans from the `kafka.consumer` domain:
   - `consumer-fetch-manager-metrics`: `fetch-size-max`, `bytes-consumed-rate`, `fetch-size-avg`, `records-consumed-rate`, `records-per-request-avg`, `records-lag-max`, `fetch-rate`
   - `consumer-coordinator-metrics`: `heartbeat-rate`, `commit-rate`, `join-rate`, `sync-rate`, `assigned-partitions`, `heartbeat-response-time-max`, `commit-latency-avg`
   - `consumer-metrics`: `request-rate`, `response-rate`, `incoming-byte-rate`, `outgoing-byte-rate`, `connection-creation-rate`, `connection-close-rate`, `select-rate`, `request-latency-avg`, `request-latency-max`, `io-ratio`, `io-time-ns-avg`, `io-wait-ratio`
   - From: Telegraf (jolokia2_agent input)
   - To: Jolokia HTTP endpoint
   - Protocol: HTTP GET (Jolokia JSON)

3. **Collect producer metrics**: Telegraf queries the following MBeans from the `kafka.producer` domain:
   - `producer-topic-metrics`: `byte-rate`, `record-send-rate`, `record-retry-rate`, `record-error-rate`, `compression-rate` (per topic)
   - `producer-metrics`: `request-rate`, `response-rate`, `incoming-byte-rate`, `outgoing-byte-rate`, `connection-creation-rate`, `connection-close-rate`, `select-rate`, `request-latency-avg`, `request-latency-max`, `io-ratio`, `io-time-ns-avg`, `io-wait-ratio`
   - `producer-node-metrics`: `request-rate`, `response-rate`, `incoming-byte-rate`, `outgoing-byte-rate`, `request-size-max`, `request-size-avg` (per broker node)
   - From: Telegraf (jolokia2_agent input)
   - To: Jolokia HTTP endpoint
   - Protocol: HTTP GET (Jolokia JSON)

4. **Collect MirrorMaker-specific metric**: Telegraf queries `kafka.tools:name=MirrorMaker-numDroppedMessages,type=MirrorMaker` — the total count of messages dropped by the MirrorMaker instance. This is the primary data-loss indicator.
   - From: Telegraf (jolokia2_agent input)
   - To: Jolokia HTTP endpoint
   - Protocol: HTTP GET (Jolokia JSON)

5. **Apply global tags**: Telegraf adds the following global tags to all metrics: `agent=telegraf-grpn`, `service=mirror-maker-kubernetes`, `component=<mirror-component>`, `instance=topic`, `env=production`, `az=local`, `source=mirror-maker-kubernetes-production`, `atom=v1.0.0-SNAPSHOT`. Tag `_rollup=counter:*` is applied to throughput/rate counters; `_rollup=gauge:*` to latency and ratio metrics.
   - From: Telegraf (in-process tagging)
   - To: Telegraf output buffer
   - Protocol: In-process

6. **Forward to InfluxDB**: Telegraf flushes the metric batch to InfluxDB at `$TELEGRAF_URL` using the InfluxDB line protocol. Flush interval is 60 seconds with up to 29 seconds of jitter. Batch size up to 1000 metrics; buffer limit 10000.
   - From: Telegraf sidecar
   - To: `metricsStack` (InfluxDB at `$TELEGRAF_URL`)
   - Protocol: HTTP (InfluxDB line protocol)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jolokia endpoint not responding (JVM not started yet) | Telegraf logs error; skips collection cycle | Metric gap for that interval; no impact on replication |
| InfluxDB (`$TELEGRAF_URL`) unreachable | Telegraf buffers metrics up to 10000; drops oldest if buffer fills | Metric loss; no impact on replication |
| Jolokia returns partial data | Telegraf emits available metrics only | Partial metric coverage for that scrape cycle |

## Sequence Diagram

```
Telegraf(sidecar) -> JolokiaAgent(port 8778): HTTP GET /jolokia (60s interval)
JolokiaAgent --> Telegraf: JMX metrics JSON (consumer lag, producer rates, drop count)
Telegraf -> Telegraf: Apply global tags (service, component, env, rollup)
Telegraf -> MetricsStack(InfluxDB): POST metrics in line protocol to $TELEGRAF_URL
MetricsStack --> Telegraf: 204 No Content (success)
```

## Related

- Architecture dynamic view: `dynamic-mirror-maker-replication-flow`
- Related flows: [Topic Replication](topic-replication.md)
- Runbook: [Runbook](../runbook.md) — Monitoring section for metric thresholds

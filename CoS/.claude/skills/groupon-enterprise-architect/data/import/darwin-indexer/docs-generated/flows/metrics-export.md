---
service: "darwin-indexer"
title: "Metrics Export"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "metrics-export"
flow_type: scheduled
trigger: "Continuous periodic timer — Dropwizard Metrics reporter interval"
participants:
  - "continuumDealIndexerService"
  - "continuumHotelOfferIndexerService"
architecture_ref: "dynamic-metrics-export"
---

# Metrics Export

## Summary

darwin-indexer uses Dropwizard Metrics 4.1.8 to collect, aggregate, and periodically export operational metrics. Both the Deal Indexer Service and the Hotel Offer Indexer Service maintain metric registries that track job durations, document counts, bulk-write throughput, upstream service latency, JVM health, and error rates. A configured Dropwizard Metrics reporter emits these metrics at a fixed interval to the monitoring backend. The Dropwizard admin server on port 9001 also exposes metrics on demand via `GET /metrics`.

## Trigger

- **Type**: schedule
- **Source**: Dropwizard Metrics reporter (scheduled at a configurable interval, typically 60 seconds)
- **Frequency**: Continuous — fires at each reporter interval while the service is running

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Indexer Service | Maintains metric registry; exports metrics on reporter interval | `continuumDealIndexerService` |
| Hotel Offer Indexer Service | Maintains metric registry; exports metrics on reporter interval | `continuumHotelOfferIndexerService` |

> The metrics monitoring backend (e.g., Graphite, Datadog, or equivalent) is not referenced explicitly in the architecture DSL model. The exact reporter type and destination should be confirmed by the service owner.

## Steps

1. **Metrics registered at startup**: On service start, Dropwizard Metrics registers counters, gauges, histograms, and timers for all tracked operations (job durations, document counts, error counts, JVM stats, upstream call latencies).
   - From: `continuumDealIndexerService` / `continuumHotelOfferIndexerService`
   - To: In-process Dropwizard MetricRegistry
   - Protocol: internal / in-process

2. **Metrics updated during job execution**: As each indexing job runs, the metric registry is updated — timers are started/stopped, counters incremented, and gauges set.
   - From: Indexing job handlers (internal to indexer services)
   - To: In-process Dropwizard MetricRegistry
   - Protocol: internal / in-process

3. **Reporter fires on interval**: The configured Dropwizard Metrics reporter (e.g., GraphiteReporter, JmxReporter, or SLF4JReporter) fires at the configured interval and reads the current snapshot of all metrics from the registry.
   - From: Dropwizard Metrics scheduler (internal)
   - To: In-process MetricRegistry snapshot
   - Protocol: internal / in-process

4. **Emits metrics to monitoring backend**: The reporter serializes and transmits metric data to the configured monitoring system.
   - From: `continuumDealIndexerService` / `continuumHotelOfferIndexerService`
   - To: Monitoring backend (Graphite, Datadog, or equivalent — not specified in DSL)
   - Protocol: Reporter-specific (TCP/UDP for Graphite; HTTPS for Datadog; etc.)

5. **Admin endpoint exposes on-demand metrics**: At any time, operators can query `GET :9001/metrics` on the Dropwizard admin server to receive a JSON snapshot of all current metric values.
   - From: Operator / monitoring scraper
   - To: `continuumDealIndexerService` / `continuumHotelOfferIndexerService` (admin server)
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Monitoring backend unreachable | Reporter logs error; retries on next interval | Metrics gap in monitoring backend; service continues operating normally |
| Metrics registry corrupted or OOM | JVM-level failure; service restart required | Service unavailable; metrics export ceases |
| Admin endpoint request fails | HTTP 500 from Dropwizard admin server | Operator receives error; service continues; metrics still exported via reporter |

## Sequence Diagram

```
Quartz/Timer -> DropwizardMetricsReporter: Fire reporter interval
DropwizardMetricsReporter -> MetricRegistry: Snapshot all metrics
MetricRegistry --> DropwizardMetricsReporter: Metric values (counters, gauges, histograms, timers)
DropwizardMetricsReporter -> MonitoringBackend: Emit metrics (protocol per reporter)
MonitoringBackend --> DropwizardMetricsReporter: Acknowledgement (or silent UDP)

Operator -> DealIndexerService:AdminServer: GET :9001/metrics
DealIndexerService:AdminServer -> MetricRegistry: Snapshot all metrics
MetricRegistry --> DealIndexerService:AdminServer: Metric values
DealIndexerService:AdminServer --> Operator: JSON metrics response
```

## Related

- Architecture dynamic view: `dynamic-metrics-export`
- Related flows: [Deal Indexing Pipeline](deal-indexing-pipeline.md), [Hotel Offer Indexing](hotel-offer-indexing.md), [Logging and Validation](logging-and-validation.md)

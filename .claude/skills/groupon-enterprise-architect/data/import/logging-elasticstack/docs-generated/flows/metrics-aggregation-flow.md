---
service: "logging-elasticstack"
title: "Metrics Aggregation Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "metrics-aggregation-flow"
flow_type: scheduled
trigger: "Telegraf scrape interval and/or Elasticsearch Watcher schedule"
participants:
  - "continuumLoggingElasticsearch"
  - "metricsStack"
architecture_ref: "dynamic-logging-logstashPipeline-flow"
---

# Metrics Aggregation Flow

## Summary

The Logging Elastic Stack continuously aggregates operational metrics from its Elasticsearch cluster and Kafka consumer groups, routes them to the Wavefront TSDB, and uses Wavefront alerts to trigger PagerDuty notifications for critical conditions. Telegraf scrapes Elasticsearch node and cluster APIs on a scheduled interval, while Elasticsearch Watcher can execute aggregation queries on a defined schedule and push results to external destinations.

## Trigger

- **Type**: schedule
- **Source**: Telegraf scrape interval (e.g., every 60 seconds) and/or Elasticsearch Watcher schedule (defined per watch)
- **Frequency**: Continuous scheduled polling

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Elasticsearch Cluster | Source of operational metrics via `_nodes/stats`, `_cluster/health`, and `_cluster/stats` APIs; also runs ES Watcher for scheduled aggregation queries | `continuumLoggingElasticsearch` |
| Telegraf Agent | Scrapes Elasticsearch metrics APIs on a schedule; pushes time-series data points to Wavefront | `metricsStack` (via Telegraf) |
| Wavefront TSDB | Receives metric data points; stores time-series data; evaluates alert conditions; routes alerts to PagerDuty | `metricsStack` |
| PagerDuty | Receives alert notifications from Wavefront for critical metric threshold breaches | external |
| Logstash Pipeline | Consumer group tracked via Kafka metrics; consumer lag is a key operational metric | `continuumLoggingLogstash` |

## Steps

1. **Telegraf scrapes Elasticsearch metrics**: Telegraf's Elasticsearch input plugin polls the Elasticsearch nodes stats API (`/_nodes/stats`) and cluster health API (`/_cluster/health`) on the configured scrape interval.
   - From: `Telegraf agent`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (Basic Auth via `ELASTICSEARCH_API_VIP`)

2. **Telegraf scrapes Kafka consumer lag**: Telegraf's Kafka consumer group input plugin or a dedicated Kafka metrics exporter polls the Kafka broker for Logstash consumer group lag per topic and partition.
   - From: `Telegraf agent`
   - To: `messageBus` (Kafka)
   - Protocol: Kafka admin API

3. **Telegraf pushes metrics to Wavefront**: Telegraf's Wavefront output plugin serializes collected metric data points and pushes them to the Wavefront ingestion endpoint.
   - From: `Telegraf agent`
   - To: `metricsStack`
   - Protocol: Wavefront API (TCP/HTTP)

4. **Elasticsearch Watcher executes scheduled aggregation** (where configured): ES Watcher triggers a predefined aggregation query on the log indices at the scheduled interval, computes counts or statistics, and can push results via webhook.
   - From: `continuumLoggingElasticsearch` (Watcher)
   - To: `continuumLoggingElasticsearch` (internal search)
   - Protocol: internal Elasticsearch Watcher

5. **Wavefront evaluates alert conditions**: Wavefront continuously evaluates alert conditions (e.g., JVM heap > 85%, consumer lag growing, cluster health != green) against incoming metric data points.
   - From: `metricsStack` (Wavefront alert engine)
   - To: `metricsStack` (internal evaluation)
   - Protocol: internal Wavefront

6. **PagerDuty alert triggered**: When a Wavefront alert condition is met, Wavefront sends an alert notification to PagerDuty to page the on-call Logging Platform Team member.
   - From: `metricsStack`
   - To: `PagerDuty`
   - Protocol: Wavefront → PagerDuty webhook integration

7. **On-call engineer responds**: The on-call engineer receives the PagerDuty page, investigates the issue using Wavefront dashboards and Kibana, and follows the runbook procedures.
   - From: `PagerDuty`
   - To: `On-call engineer`
   - Protocol: PagerDuty notification (mobile/email)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Telegraf scrape failure (ES unavailable) | Telegraf logs scrape error; retries on next interval | Metric gap in Wavefront; dashboards show no data for affected interval; does not affect log ingestion |
| Wavefront ingestion unavailable | Telegraf buffers metric data points in memory up to configured queue size; drops oldest on overflow | Metric gaps during outage; no impact on log ingestion or search |
| ES Watcher execution failure | Watcher records execution failure in `.watches` index; alert may not fire | Silent failure; requires manual inspection of Watcher execution history |
| PagerDuty notification failure | Wavefront retries alert delivery per PagerDuty integration retry policy | Alert may be delayed; Wavefront alert remains active until resolved |

## Sequence Diagram

```
Telegraf -> Elasticsearch: GET /_nodes/stats (scrape node metrics)
Elasticsearch --> Telegraf: JSON node stats response
Telegraf -> Kafka: Poll consumer group lag for logging_<env>_* topics
Kafka --> Telegraf: Consumer group lag per partition
Telegraf -> Wavefront: Push metric data points (Wavefront API)
Elasticsearch -> Elasticsearch: Watcher executes scheduled aggregation query
Elasticsearch -> Elasticsearch: Watcher evaluates output condition
Wavefront -> Wavefront: Evaluates alert conditions on incoming metrics
Wavefront -> PagerDuty: POST alert notification (condition breached)
PagerDuty -> On-Call Engineer: Mobile/email page notification
On-Call Engineer -> Wavefront: Reviews dashboard
On-Call Engineer -> Kibana: Investigates via log search
```

## Related

- Architecture dynamic view: `dynamic-logging-logstashPipeline-flow`
- Related flows: [Log Ingestion and Search Flow](logging-ingestion-search-flow.md), [Cluster Deployment Flow](cluster-deployment-flow.md)

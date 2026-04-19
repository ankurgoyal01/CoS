---
service: "logging-elasticstack"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The Logging Elastic Stack uses Apache Kafka as the primary message buffer between Filebeat log shippers and Logstash processing pipelines. Filebeat agents publish raw log events to Kafka topics partitioned by sourcetype. Logstash consumes those topics, processes events, and writes enriched documents to Elasticsearch. This decoupling allows Filebeat to continue shipping logs during Logstash downtime and protects Elasticsearch from write spikes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `logging_production_<sourcetype>` | Raw log event | Log line written to a monitored file or stream by a Groupon service | `message`, `sourcetype`, `host`, `@timestamp`, `log.file.path` |

### Raw Log Event Detail

- **Topic**: `logging_production_<sourcetype>` (where `<sourcetype>` is the service/application log type identifier, e.g., `logging_production_nginx`, `logging_production_app_server`)
- **Trigger**: Filebeat harvester detects a new log line in a monitored file or container stdout stream
- **Payload**: Raw log message string plus Filebeat-added metadata fields (`host`, `@timestamp`, `log.file.path`, `agent.*`, `input.type`)
- **Consumers**: `continuumLoggingLogstash` (Logstash pipeline)
- **Guarantees**: at-least-once (Kafka consumer group offset management by Logstash)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `logging_<env>_<sourcetype>` | Raw log event | `logstashPipeline` — sourcetype-specific filter pipeline | Parsed and enriched document indexed to Elasticsearch; operational metrics emitted to Wavefront |

### Raw Log Event (Logstash Consumer) Detail

- **Topic**: `logging_<env>_<sourcetype>` (where `<env>` is the deployment environment, e.g., `logging_production_nginx`, `logging_staging_app_server`)
- **Handler**: Logstash pipeline selects the matching per-sourcetype filter configuration; applies grok parsing, field mutations, date parsing, and enrichment; routes enriched events to the appropriate Elasticsearch index
- **Idempotency**: Not guaranteed — duplicate log events may be indexed if Logstash restarts mid-batch; Elasticsearch document IDs are auto-generated, so duplicates result in separate documents
- **Error handling**: Events failing filter parsing are tagged with `_grokparsefailure` and routed to a dedicated error index rather than discarded; no DLQ configured at the Kafka layer
- **Processing order**: Unordered within a topic partition; ordering is preserved per partition (by Kafka), but cross-partition ordering is not enforced

## Dead Letter Queues

> No evidence found in codebase. Failed parse events are tagged (`_grokparsefailure`) and written to an error index in Elasticsearch rather than a Kafka DLQ.

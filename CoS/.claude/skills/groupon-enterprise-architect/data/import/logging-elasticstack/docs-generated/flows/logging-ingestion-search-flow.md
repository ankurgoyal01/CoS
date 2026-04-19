---
service: "logging-elasticstack"
title: "Log Ingestion and Search Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "logging-ingestion-search-flow"
flow_type: asynchronous
trigger: "Log line written to a monitored file or container stream by any Groupon service"
participants:
  - "continuumLoggingFilebeat"
  - "messageBus"
  - "continuumLoggingLogstash"
  - "continuumLoggingElasticsearch"
  - "continuumLoggingKibana"
  - "metricsStack"
architecture_ref: "dynamic-logging-logstashPipeline-flow"
---

# Log Ingestion and Search Flow

## Summary

This is the primary end-to-end flow of the Logging Elastic Stack. A log line written by any Groupon service is collected by a co-deployed Filebeat agent, buffered through Apache Kafka, processed and enriched by a sourcetype-specific Logstash pipeline, indexed in Elasticsearch, and made available for search via Kibana. Operational metrics about the platform itself are emitted to Wavefront TSDB throughout the pipeline.

## Trigger

- **Type**: event
- **Source**: Any Groupon service writing a log line to a monitored file path or container stdout/stderr stream
- **Frequency**: Continuous / per log line (near real-time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Filebeat Agent | Collects log lines from monitored files and container streams; ships events to Kafka | `continuumLoggingFilebeat` |
| Apache Kafka | Buffers log events; decouples ingestion rate from processing capacity | `messageBus` |
| Logstash Pipeline | Consumes events from Kafka; applies per-sourcetype filter logic; writes enriched documents to Elasticsearch | `continuumLoggingLogstash` |
| Elasticsearch Cluster | Indexes enriched log documents; serves search and aggregation queries | `continuumLoggingElasticsearch` |
| Kibana | Provides search UI (Discover), dashboards, and data view management for engineers | `continuumLoggingKibana` |
| Wavefront TSDB | Receives operational metrics from Elasticsearch and Logstash via Telegraf | `metricsStack` |

## Steps

1. **Collect log line**: Filebeat harvester detects a new log line in a monitored file or container stream.
   - From: `Groupon service (log producer)`
   - To: `continuumLoggingFilebeat`
   - Protocol: File I/O / Docker log driver

2. **Publish to Kafka topic**: Filebeat Kafka output plugin publishes the raw log event to the appropriate topic.
   - From: `continuumLoggingFilebeat`
   - To: `messageBus`
   - Protocol: Kafka producer — topic `logging_production_<sourcetype>`

3. **Consume from Kafka topic**: Logstash Kafka input plugin reads the raw log event from the topic.
   - From: `messageBus`
   - To: `continuumLoggingLogstash`
   - Protocol: Kafka consumer — topic `logging_<env>_<sourcetype>`, consumer group offset management

4. **Apply sourcetype filter pipeline**: Logstash applies the matching per-sourcetype filter configuration (grok parsing, field mutations, date parsing, enrichment).
   - From: `logstashPipeline` (Kafka input)
   - To: `logstashPipeline` (filter chain)
   - Protocol: internal Logstash pipeline

5. **Index enriched document**: Logstash output plugin bulk-writes the enriched log document to Elasticsearch.
   - From: `continuumLoggingLogstash`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`_bulk` API)

6. **Apply ILM and store**: Elasticsearch applies the index template mapping, routes to the hot-tier shard, and acknowledges the write.
   - From: `elasticsearchIndexer`
   - To: `elasticsearchIndexer` (internal)
   - Protocol: internal Elasticsearch

7. **Search log documents**: An engineer queries logs via Kibana Discover or a dashboard.
   - From: `continuumLoggingKibana`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`_search` API with KQL/Lucene)

8. **Return search results**: Elasticsearch returns matching log documents to Kibana for display.
   - From: `continuumLoggingElasticsearch`
   - To: `continuumLoggingKibana`
   - Protocol: REST HTTP (JSON response)

9. **Emit operational metrics**: Elasticsearch cluster metrics (indexing rate, JVM heap, search latency) are scraped by Telegraf and pushed to Wavefront.
   - From: `continuumLoggingElasticsearch`
   - To: `metricsStack`
   - Protocol: Wavefront API (Telegraf push)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Logstash grok parse failure | Event tagged with `_grokparsefailure`; routed to error index in Elasticsearch | Event preserved but not fully parsed; visible in error index for investigation |
| Elasticsearch write rejection (429 Too Many Requests) | Logstash retries with exponential backoff | Temporary ingestion delay; Kafka consumer lag increases until ES recovers |
| Kafka broker unavailable | Filebeat in-memory queue holds events; Logstash consumer stalls | Short outages tolerated; extended outages may cause Filebeat queue overflow and event loss |
| Kibana search timeout | Elasticsearch returns timeout error; Kibana displays error to user | User retries query with narrower time range or simpler filter |

## Sequence Diagram

```
Groupon Service -> Filebeat: Writes log line to file / stdout
Filebeat -> Kafka: Publishes event to logging_production_<sourcetype>
Kafka -> Logstash: Delivers event from logging_<env>_<sourcetype>
Logstash -> Logstash: Applies grok/mutate/date filter for sourcetype
Logstash -> Elasticsearch: Bulk indexes enriched document (_bulk API)
Elasticsearch --> Logstash: 200 OK (write acknowledged)
Engineer -> Kibana: Queries logs via Discover or Dashboard
Kibana -> Elasticsearch: Executes _search with KQL/Lucene
Elasticsearch --> Kibana: Returns matching log documents
Kibana --> Engineer: Displays search results
Telegraf -> Elasticsearch: Scrapes cluster metrics (_nodes/stats)
Telegraf -> Wavefront: Pushes operational metrics
```

## Related

- Architecture dynamic view: `dynamic-logging-logstashPipeline-flow`
- Related flows: [Index Lifecycle Flow](index-lifecycle-flow.md), [Metrics Aggregation Flow](metrics-aggregation-flow.md)

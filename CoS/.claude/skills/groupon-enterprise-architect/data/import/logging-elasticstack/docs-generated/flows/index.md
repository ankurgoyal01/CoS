---
service: "logging-elasticstack"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Logging Elastic Stack.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Log Ingestion and Search Flow](logging-ingestion-search-flow.md) | asynchronous | Log line written by any Groupon service | End-to-end flow from Filebeat log collection through Kafka buffering, Logstash processing, Elasticsearch indexing, to Kibana search and Wavefront metrics |
| [Index Lifecycle Flow](index-lifecycle-flow.md) | scheduled | ILM policy evaluation (continuous background) | Automated hot-to-warm-to-delete index lifecycle management with configurable retention policies |
| [Log Source Onboarding Flow](log-source-onboarding-flow.md) | manual | New service or application requests logging integration | Manual process to add a new sourcetype: create Logstash filter, ES index template, and Kibana data view |
| [Metrics Aggregation Flow](metrics-aggregation-flow.md) | scheduled | ES Watcher schedule / Telegraf scrape interval | Elasticsearch operational metrics aggregation and routing to Wavefront TSDB with PagerDuty alerting |
| [Cluster Deployment Flow](cluster-deployment-flow.md) | event-driven | Jenkins branch push (`release-gcp-us`, `release-gcp-staging`, `release-eu`) or manual Ansible run | Full cluster deployment pipeline from Jenkins build through filter tests to cluster provisioning and rollout |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |
| Manual / Operational | 1 |

## Cross-Service Flows

The primary ingestion flow (`dynamic-logging-logstashPipeline-flow`) spans all four core platform containers (`continuumLoggingFilebeat`, `continuumLoggingLogstash`, `continuumLoggingElasticsearch`, `continuumLoggingKibana`) and the two shared infrastructure stubs (`messageBus`, `metricsStack`). This is the only cross-service dynamic view defined in the central architecture model. See [Architecture Context](../architecture-context.md) for the full dynamic view reference.

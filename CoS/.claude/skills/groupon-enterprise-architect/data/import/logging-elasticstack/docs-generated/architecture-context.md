---
service: "logging-elasticstack"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumLogging"
  containers: [continuumLoggingFilebeat, continuumLoggingLogstash, continuumLoggingElasticsearch, continuumLoggingKibana]
---

# Architecture Context

## System Context

The Logging Elastic Stack sits within the Continuum platform as the centralized observability infrastructure for all Groupon services. Every Groupon service deploys a Filebeat agent that ships logs into the platform. The platform depends on the shared `messageBus` (Apache Kafka) for log buffering and the `metricsStack` (Wavefront TSDB) for operational metrics emission. Engineers and SRE teams interact with the platform via the Kibana UI (authenticated via Okta SSO) or directly via the Elasticsearch REST API.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Logging Filebeat | `continuumLoggingFilebeat` | Log Shipper | Elastic Filebeat | paired with ES | Deployed as agents on all Groupon services; harvests log files and ships events to Kafka topics |
| Logging Logstash | `continuumLoggingLogstash` | Processing Pipeline | Elastic Logstash | 8.12.1 | Consumes log events from Kafka, applies sourcetype-specific filter pipelines, and writes enriched documents to Elasticsearch |
| Logging Elasticsearch | `continuumLoggingElasticsearch` | Event Store | Elastic Elasticsearch | 7.17.6 | Primary searchable document store; hot/warm tiered cluster managed via ILM policies |
| Logging Kibana | `continuumLoggingKibana` | Visualization UI | Elastic Kibana | paired with ES | Provides search (Discover), dashboards, and data view management; secured via Okta OAuth |

## Components by Container

### Logging Filebeat (`continuumLoggingFilebeat`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `filebeatCollector` | Filebeat Input/Harvester — reads log files from container stdout/stderr and log file paths; applies initial multiline handling; publishes raw events to Kafka topics named `logging_production_<sourcetype>` | Elastic Filebeat |

### Logging Logstash (`continuumLoggingLogstash`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `logstashPipeline` | Logstash Pipeline — reads from Kafka topics `logging_<env>_<sourcetype>`, applies per-sourcetype filter plugins (grok, mutate, date, etc.), enriches events, and outputs to Elasticsearch index per sourcetype | Elastic Logstash 8.12.1 |

### Logging Elasticsearch (`continuumLoggingElasticsearch`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `elasticsearchIndexer` | Elasticsearch Cluster Services — accepts document writes from Logstash via REST, manages index templates, applies ILM policies for hot/warm/delete lifecycle, serves search queries from Kibana and API consumers | Elastic Elasticsearch 7.17.6 |

### Logging Kibana (`continuumLoggingKibana`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `kibanaDiscoverUi` | Kibana App — provides Discover UI for ad-hoc log search, Dashboard UI for visualizations, and data view/index pattern management; authenticated via Okta SSO on port 5601 | Elastic Kibana |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLoggingFilebeat` | `messageBus` | Publishes log events to Kafka topics `logging_production_<sourcetype>` | Kafka producer |
| `messageBus` | `continuumLoggingLogstash` | Delivers buffered log events from Kafka topics `logging_<env>_<sourcetype>` | Kafka consumer |
| `continuumLoggingLogstash` | `continuumLoggingElasticsearch` | Writes processed and enriched log documents | REST (HTTP) |
| `continuumLoggingKibana` | `continuumLoggingElasticsearch` | Runs search and dashboard queries via REST | REST (HTTP) |
| `continuumLoggingElasticsearch` | `metricsStack` | Emits operational metrics via ES Watcher and Telegraf | Wavefront API |

## Architecture Diagram References

- System context: `contexts-continuumLogging`
- Container: `containers-continuumLogging`
- Component: `components-continuumLoggingLogstash`
- Dynamic flow: `dynamic-logging-logstashPipeline-flow`

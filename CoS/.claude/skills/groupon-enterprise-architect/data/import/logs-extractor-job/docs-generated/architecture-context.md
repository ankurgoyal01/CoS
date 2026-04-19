---
service: "logs-extractor-job"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumLogExtractorJob"
    - "continuumLogExtractorBigQuery"
    - "continuumLogExtractorMySQL"
    - "continuumLogExtractorElasticsearch"
---

# Architecture Context

## System Context

The Log Extractor Job is a batch container within the `continuumSystem` (Continuum Platform). It runs on a Kubernetes CronJob schedule and sits between the Elasticsearch logging clusters (source) and analytical/operational data stores (sinks). It has no inbound API or event consumers — it is driven exclusively by schedule. The job pulls logs from Elasticsearch via the `@groupon/logs-processor` SDK, transforms them, and writes them to BigQuery and/or MySQL. It is deployed under the `orders` service namespace in GCP `us-central1`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Log Extractor Job | `continuumLogExtractorJob` | Backend / Batch | Node.js, npm | 20 | Hourly batch job that extracts logs from Elasticsearch and uploads transformed datasets to analytics and relational stores |
| Log Extractor BigQuery Dataset | `continuumLogExtractorBigQuery` | Database | BigQuery | — | Managed analytical datastore for consolidated logs; tables created and maintained per ingestion |
| Log Extractor MySQL Database | `continuumLogExtractorMySQL` | Database | MySQL 8 | 8 | Optional relational store for extracted logs to support operational reporting and ad-hoc queries |
| Source Elasticsearch Cluster | `continuumLogExtractorElasticsearch` | Database | Elasticsearch | — | Elasticsearch cluster providing raw PWA, proxy, Lazlo, and orders logs via the logs-processor SDK |

## Components by Container

### Log Extractor Job (`continuumLogExtractorJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| CLI Job Runner (`continuumLogExtractorJob_cliRunner`) | Parses CLI arguments, validates inputs, configures the logger, and orchestrates extraction plus downstream uploads | Node.js (ESM), `src/index.js` |
| Config Loader (`continuumLogExtractorJob_configLoader`) | Loads and deep-merges default and environment-specific configuration, honoring environment flags | Node.js, `config` package, `src/config/index.js` |
| Log Extractor (`continuumLogExtractorJob_logExtractor`) | Wraps logs-processor extraction to fetch time-bounded logs from Elasticsearch for the configured region | Node.js, `@groupon/logs-processor`, `src/services/logExtractor.js` |
| Logs Processor Adapter (`continuumLogExtractorJob_logsProcessorAdapter`) | CommonJS adapter exposing logger and logExtraction from `@groupon/logs-processor` into ESM modules | Node.js, `createRequire`, `src/utils/commonjsAdapter.js` |
| BigQuery Service (`continuumLogExtractorJob_bigQueryService`) | Ensures datasets/tables exist, transforms log batches, and uploads to BigQuery with partitioning | Node.js, `@google-cloud/bigquery`, `src/services/bigQueryService.js` |
| MySQL Service (`continuumLogExtractorJob_mySQLService`) | Manages MySQL connection pooling, ensures tables via DDL, and batches inserts for transformed logs | Node.js, `mysql2/promise`, `src/services/mysqlService.js` |
| Schema Definitions (`continuumLogExtractorJob_schemaDefinitions`) | Shared BigQuery schemas and MySQL DDL used by upload services | JavaScript modules, `src/schemas/` |
| Structured Logger (`continuumLogExtractorJob_logging`) | Structured logger reused from logs-processor to emit sections, debug data, and errors | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLogExtractorJob` | `continuumLogExtractorElasticsearch` | Extracts raw operational logs by region via logs-processor SDK | HTTPS, Elasticsearch API |
| `continuumLogExtractorJob` | `continuumLogExtractorBigQuery` | Creates tables and uploads transformed log datasets | BigQuery API |
| `continuumLogExtractorJob` | `continuumLogExtractorMySQL` | Creates tables and performs batched inserts of transformed logs | MySQL protocol |
| `continuumLogExtractorJob_cliRunner` | `continuumLogExtractorJob_configLoader` | Loads environment-specific and CLI configuration before execution | in-process |
| `continuumLogExtractorJob_cliRunner` | `continuumLogExtractorJob_logExtractor` | Triggers time-bounded log retrieval | function call |
| `continuumLogExtractorJob_cliRunner` | `continuumLogExtractorJob_bigQueryService` | Coordinates BigQuery table preparation and uploads | function call |
| `continuumLogExtractorJob_cliRunner` | `continuumLogExtractorJob_mySQLService` | Coordinates MySQL table preparation and uploads | function call |
| `continuumLogExtractorJob_logExtractor` | `continuumLogExtractorJob_logsProcessorAdapter` | Uses logs-processor extraction API for Elasticsearch | module import |
| `continuumLogExtractorJob_bigQueryService` | `continuumLogExtractorJob_schemaDefinitions` | Reads BigQuery schemas for table creation and transformations | module import |
| `continuumLogExtractorJob_mySQLService` | `continuumLogExtractorJob_schemaDefinitions` | Reads MySQL DDL for ensuring tables before inserts | module import |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumLogExtractorJob`
- Dynamic view: `dynamic-hourly-log-extraction`

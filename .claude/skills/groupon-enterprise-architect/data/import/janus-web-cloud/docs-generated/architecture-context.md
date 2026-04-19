---
service: "janus-web-cloud"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusWebCloudService", "continuumJanusMetadataMySql"]
---

# Architecture Context

## System Context

Janus Web Cloud is a container within the `continuumSystem` software system — Groupon's core commerce and data engine. It sits in the data-ingestion subdomain and serves as the management-plane API for the Janus platform. Operator tooling and internal services interact with it over REST. It depends on a dedicated MySQL store for all persistent state, and integrates outward to Bigtable/HBase, Elasticsearch, BigQuery, and SMTP for specialised read, metrics, and notification capabilities.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus Web Cloud Service | `continuumJanusWebCloudService` | Service / API | Java 17, Dropwizard, JTier | 5.14.0 | REST API service for Janus metadata management, replay orchestration, alerts, and GDPR workflows |
| Janus Metadata MySQL | `continuumJanusMetadataMySql` | Database | MySQL | 8.0.27 (connector) | Relational datastore for metadata, schema registry, replay state, and Quartz scheduling tables |

## Components by Container

### Janus Web Cloud Service (`continuumJanusWebCloudService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`jwc_apiResources`) | Exposes all REST endpoints under `/janus/api`, `/annotations`, `/attributes`, `/avro`, `/events`, `/destinations`, `/contexts`, `/gdpr`, `/metrics`, `/replay`, and `/promote` | JAX-RS Resources |
| Domain Services (`jwc_domainServices`) | Core Janus domain logic: mappings, validation, metrics computation, sandbox evaluation, and timeline behaviors | Java Services |
| Replay Orchestration (`jwc_replayOrchestration`) | Schedules, splits, validates, and tracks asynchronous replay jobs over historical event data | Replay Controllers / Processors |
| Alerting Engine (`jwc_alertingEngine`) | Evaluates threshold expressions against Elasticsearch metrics on a Quartz schedule and orchestrates notification dispatch | Quartz + Alerting |
| MySQL DAOs (`jwc_mysqlDaos`) | JDBI DAO layer: reads and writes metadata, schema registry records, replay state, user data, and alert definitions | JDBI DAOs |
| Integration Adapters (`jwc_integrationAdapters`) | Client adapters for Bigtable/HBase, Elasticsearch, SMTP, and the GDOOP resource-manager scheduler | Client Adapters |

### Janus Metadata MySQL (`continuumJanusMetadataMySql`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Janus Operational Schema (`janusOperationalSchema`) | Core Janus tables: source/event/attribute mappings, values, users, permissions, replay entities, and alert metadata | MySQL Schema |
| Janus Schema Registry Tables (`janusSchemaRegistry`) | Avro schema and version tracking records for the schema registry | MySQL Schema |
| Quartz Scheduler Tables (`quartzSchedulerTables`) | Persistent Quartz job and trigger state enabling clustered scheduling | MySQL Schema |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusWebCloudService` | `continuumJanusMetadataMySql` | Reads/writes metadata, replay, alerting, schema-registry, and Quartz state | JDBC / MySQL |
| `continuumJanusWebCloudService` | `bigQuery` | Queries analytical datasets for metrics and reporting flows | BigQuery SDK |
| `continuumJanusWebCloudService` | `bigtableRealtimeStore` | Reads GDPR-related event data from Bigtable/HBase | HBase API |
| `continuumJanusWebCloudService` | `elasticSearch` | Queries Elasticsearch-backed metrics and alert indices | Elasticsearch REST / SDK |
| `continuumJanusWebCloudService` | `smtpRelay` | Sends alert notification emails | SMTP |
| `continuumJanusWebCloudService` | `loggingStack` | Emits service logs | Internal |
| `continuumJanusWebCloudService` | `metricsStack` | Emits and consumes operational metrics | Internal |
| `continuumJanusWebCloudService` | `tracingStack` | Emits distributed traces | Internal |
| `jwc_apiResources` | `jwc_domainServices` | Invokes domain use-cases for API requests | Direct (in-process) |
| `jwc_apiResources` | `jwc_replayOrchestration` | Triggers replay and monitoring operations | Direct (in-process) |
| `jwc_apiResources` | `jwc_alertingEngine` | Configures and triggers alerting workflows | Direct (in-process) |
| `jwc_domainServices` | `jwc_mysqlDaos` | Reads and writes Janus metadata state | Direct (in-process) |
| `jwc_replayOrchestration` | `jwc_mysqlDaos` | Persists replay requests, jobs, and statuses | Direct (in-process) |
| `jwc_alertingEngine` | `jwc_mysqlDaos` | Loads thresholds, expressions, notifications, and writes outcomes | Direct (in-process) |
| `jwc_integrationAdapters` | `jwc_mysqlDaos` | Reads persisted integration metadata and credentials | Direct (in-process) |
| `jwc_domainServices` | `jwc_integrationAdapters` | Calls Bigtable, Elasticsearch, and outbound notification adapters | Direct (in-process) |
| `jwc_alertingEngine` | `jwc_integrationAdapters` | Sends notifications and executes metrics lookups | Direct (in-process) |
| `jwc_mysqlDaos` | `janusOperationalSchema` | Persists and queries operational metadata | JDBC |
| `jwc_mysqlDaos` | `janusSchemaRegistry` | Persists and queries Avro schema versions | JDBC |
| `jwc_mysqlDaos` | `quartzSchedulerTables` | Persists clustered Quartz scheduling state | JDBC |

## Architecture Diagram References

- System context: `contexts-janus-web-cloud`
- Container: `containers-janus-web-cloud`
- Component: `components-janus-web-cloud-component-view`
- Dynamic (alert notification flow): `dynamic-alert-notification-flow`

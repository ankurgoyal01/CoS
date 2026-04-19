---
service: "janus-web-cloud"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Data Ingestion / Metadata Management"
platform: "Continuum"
team: "dnd-ingestion (aabdulwakeel)"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Janus Web Cloud Overview

## Purpose

Janus Web Cloud is a Dropwizard/JTier HTTP service that acts as the management and control plane for the Janus data-ingestion platform. It provides REST APIs for managing event metadata (sources, attributes, schemas, destinations), orchestrating replay jobs over historical event data, evaluating and dispatching threshold-based alerts, and generating GDPR-related event reports. The service backs all operator and tooling interactions with the Janus metadata layer and coordinates asynchronous workloads through a clustered Quartz scheduler.

## Scope

### In scope

- CRUD management of Janus metadata: sources, events, attributes, contexts, annotations, destinations, and promotions
- Avro schema registry: registration, versioning, and retrieval of event schemas
- Replay orchestration: scheduling, splitting, validating, and tracking replay jobs over historical data
- Alert management: defining alert rules, evaluating thresholds against Elasticsearch metrics, and dispatching email notifications via SMTP
- GDPR event report generation: querying Bigtable/HBase for GDPR-relevant event data and producing reports
- Metrics querying: surfacing operational metrics from Elasticsearch through the `/metrics/*` API group
- Clustered job scheduling via Quartz with persistent state in MySQL

### Out of scope

- Real-time event ingestion and streaming (owned by separate Janus ingestion services)
- Kafka/Pub-Sub topic production and consumption (no async messaging in this service)
- Consumer-facing commerce workflows (owned by other Continuum services)
- Analytics query execution in BigQuery (BigQuery is queried read-only for reporting)

## Domain Context

- **Business domain**: Data Ingestion / Metadata Management
- **Platform**: Continuum
- **Upstream consumers**: Operator tooling, internal dashboards, and services that query Janus metadata via REST
- **Downstream dependencies**: `continuumJanusMetadataMySql` (MySQL), `bigtableRealtimeStore` (Bigtable/HBase), `elasticSearch`, `bigQuery`, `smtpRelay`, `loggingStack`, `metricsStack`, `tracingStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | dnd-ingestion team (aabdulwakeel) |
| Operator / Admin | Internal Groupon engineers who manage Janus metadata, replay jobs, and alert rules via the REST API |
| Data consumer | Services and tools that read schema registry, annotations, and attribute definitions from this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Service summary |
| Framework | Dropwizard / JTier | 5.14.0 | Service summary |
| Runtime | JVM | — | Service summary |
| Build tool | Maven | — | Service summary |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-quartz-bundle | — | scheduling | Clustered Quartz job scheduling integrated with JTier/Dropwizard lifecycle |
| curator-api | 0.0.41 | scheduling | ZooKeeper-backed distributed coordination for Quartz cluster |
| jdbi | — | db-client | SQL query mapping and DAO layer over MySQL |
| mysql-connector | 8.0.27 | db-client | JDBC driver for MySQL connectivity |
| hbase-client | 2.2.3 | db-client | HBase client for reading GDPR event data from Bigtable |
| bigtable-hbase | 1.26.3 | db-client | Bigtable adapter exposing HBase API for Cloud Bigtable access |
| elasticsearch | 5.6.16 | db-client | Elasticsearch client for metrics and alert index queries |
| thymeleaf | 3.0.14 | ui-framework | HTML/email template rendering for alert notification emails |
| simple-java-mail | 4.1.1 | http-framework | SMTP email dispatch for alert notifications |
| commons-math3 | 3.6.1 | validation | Mathematical expression evaluation for alert threshold logic |
| sshj | 0.15.0 | http-framework | SSH client for secure resource-manager (GDOOP) communication |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.

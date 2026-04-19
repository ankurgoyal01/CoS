---
service: "janus-web-cloud"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumJanusMetadataMySql"
    type: "mysql"
    purpose: "Primary relational store for all Janus metadata, schema registry, replay state, and Quartz scheduler tables"
  - id: "bigtableRealtimeStore"
    type: "bigtable"
    purpose: "Read-only source of GDPR-relevant event data"
  - id: "elasticSearch"
    type: "elasticsearch"
    purpose: "Read-only source of Janus operational metrics and alert indices"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Read-only analytical datasets for metrics and reporting flows"
---

# Data Stores

## Overview

Janus Web Cloud uses MySQL as its primary owned data store for all persistent operational state. Three additional external stores are accessed read-only: Bigtable/HBase (GDPR events), Elasticsearch (metrics and alert indices), and BigQuery (analytics). No caching layer is in evidence.

## Stores

### Janus Metadata MySQL (`continuumJanusMetadataMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumJanusMetadataMySql` |
| Purpose | Primary relational store for Janus metadata, schema registry, replay state, alert definitions, and Quartz scheduling state |
| Ownership | owned |
| Migrations path | > No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Janus Operational Schema (`janusOperationalSchema`) | Source/event/attribute mappings, values, users, permissions, replay entities, alert metadata | source_id, event_id, attribute_id, user_id, alert_id |
| Janus Schema Registry (`janusSchemaRegistry`) | Avro schema registration and version tracking | schema_id, version, avro_definition |
| Quartz Scheduler Tables (`quartzSchedulerTables`) | Clustered Quartz job and trigger persistent state | job_name, trigger_name, next_fire_time, trigger_state |

#### Access Patterns

- **Read**: Domain Services and Alerting Engine read metadata definitions, alert rules, and schema versions on every API request and scheduled job execution. MySQL DAOs load Quartz trigger state on every scheduler tick.
- **Write**: API Resources write through Domain Services and the Replay Orchestration component. Alert outcomes, job statuses, and replay progress records are written after each processing cycle.
- **Indexes**: No evidence found of specific index definitions in the architecture model.

---

### Bigtable Realtime Store (`bigtableRealtimeStore`)

| Property | Value |
|----------|-------|
| Type | bigtable (HBase API) |
| Architecture ref | `bigtableRealtimeStore` |
| Purpose | Read-only source of GDPR-relevant event records for report generation |
| Ownership | external / shared |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Integration Adapters query Bigtable via the HBase client API (`hbase-client 2.2.3` + `bigtable-hbase 1.26.3`) when a GDPR report generation request is processed.
- **Write**: Not applicable — Janus Web Cloud does not write to Bigtable.

---

### Elasticsearch (`elasticSearch`)

| Property | Value |
|----------|-------|
| Type | elasticsearch |
| Architecture ref | `elasticSearch` |
| Purpose | Read-only source of Janus operational metrics and alert evaluation indices |
| Ownership | external / shared |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Alerting Engine queries metric indices via the Elasticsearch 5.6.16 client to evaluate alert threshold expressions. Domain Services and the `/metrics/*` API also read metric data.
- **Write**: Not applicable — Janus Web Cloud does not write to Elasticsearch.

---

### BigQuery (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` |
| Purpose | Read-only analytical datasets for metrics and reporting flows |
| Ownership | external / shared |
| Migrations path | > Not applicable |

#### Access Patterns

- **Read**: Integration Adapters query BigQuery via SDK when serving analytical metrics or reporting API calls.
- **Write**: Not applicable.

---

## Caches

> No evidence found of any caching layer (Redis, Memcached, or in-memory) in this service.

## Data Flows

Operational data flows from the REST API through the MySQL DAOs to `continuumJanusMetadataMySql` for all create/update/delete operations. For GDPR report generation, data flows from `bigtableRealtimeStore` into the service, where it is assembled into a report response. Alert evaluation pulls metrics from `elasticSearch` and writes outcomes back to `janusOperationalSchema` in MySQL. BigQuery is queried directly on demand for analytical reporting calls; results are not persisted locally.

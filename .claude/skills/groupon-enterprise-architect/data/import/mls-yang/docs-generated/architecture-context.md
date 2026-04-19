---
service: "mls-yang"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSmaMetrics"
  containers: [continuumSmaMetricsApi, continuumSmaMetricsBatch, mlsYangDb, mlsYangRinDb, mlsYangHistoryDb, mlsYangDealIndexDb]
---

# Architecture Context

## System Context

mls-yang is the read-side (Yang) component of the Merchant Lifecycle Service within Groupon's Continuum platform. It sits downstream of MLS Yin-side command producers: it receives all merchant lifecycle state changes as Kafka command messages and projects them into PostgreSQL read models. The batch subsystem additionally queries Hive/Janus and Cerebro data warehouses on a schedule to enrich those read models with deal engagement metrics and risk data. Downstream consumers include internal analytics services and other MLS platform components that read from the Yang databases.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| MLS Yang API | `continuumSmaMetricsApi` | Backend service | Java, Dropwizard | Consumes MLS commands from Kafka and serves merchant lifecycle snapshot APIs over HTTP |
| MLS Yang Batch | `continuumSmaMetricsBatch` | Worker / Batch | Java, Quartz | Runs scheduled imports, retention jobs, and backfills for merchant lifecycle datasets |
| MLS Yang Primary DB | `mlsYangDb` | Database | PostgreSQL | Primary persistence for Yang projections, vouchers, CLO data, and batch/Quartz state |
| MLS Yang RIN DB | `mlsYangRinDb` | Database | PostgreSQL | Merchant lifecycle database for inventory and lifecycle data |
| MLS Yang History DB | `mlsYangHistoryDb` | Database | PostgreSQL | History service relational store for whitelisted history events |
| MLS Yang Deal Index DB | `mlsYangDealIndexDb` | Database | PostgreSQL | Read-optimised deal index datastore for deal snapshot/event persistence lookups |

## Components by Container

### MLS Yang API (`continuumSmaMetricsApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Command Ingestion Pipeline (`smaApi_commandIngestion`) | Kafka listeners and handlers for all MLS command topics; deserialises messages and dispatches to typed handlers | Kafka Consumer, Handler Layer |
| Read API Resources (`smaApi_readApi`) | Dropwizard JAX-RS resources exposing merchant facts, voucher counts, and CLO transaction lookups over HTTP | JAX-RS (Dropwizard) |
| Persistence Layer (`smaApi_persistence`) | DAO/JDBI layer for all database reads and writes across yangDb, rinDb, historyDb, and dealIndexDb | JDBI |

### MLS Yang Batch (`continuumSmaMetricsBatch`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Quartz Scheduler (`smaBatch_quartzScheduler`) | Stateful clustered Quartz scheduler that fires all import and retention jobs on configured cron schedules | Quartz (PostgreSQL-backed JobStore) |
| Import and Retention Workers (`smaBatch_importWorkers`) | Deal metrics importers (Janus), inventory/risk importers, CLO retention, deal backfill, and partition management executors | Batch Executors |
| Batch Persistence Layer (`smaBatch_persistence`) | DAO and SQL layer used by scheduled jobs to read/write yangDb, rinDb, and dealIndexDb | JDBI |
| Batch Feedback Emitter (`smaBatch_feedbackEmitter`) | Publishes completion feedback commands to the shared MLS message bus destination (`jms.queue.mls.batchCommands`) | Message Bus Producer |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSmaMetricsApi` | `messageBus` | Consumes MLS command topics | Kafka (SSL, v0.10.2.1) |
| `continuumSmaMetricsApi` | `continuumDealCatalogService` | Retrieves deal metadata and permalink-to-UUID mappings | REST (HTTP) |
| `continuumSmaMetricsApi` | `mlsYangDb` | Reads and writes projection data, vouchers, CLO, and Quartz state | JDBC/JDBI |
| `continuumSmaMetricsApi` | `mlsYangRinDb` | Reads and writes merchant lifecycle data | JDBC/JDBI |
| `continuumSmaMetricsApi` | `mlsYangHistoryDb` | Writes whitelisted history events | JDBC/JDBI |
| `continuumSmaMetricsApi` | `mlsYangDealIndexDb` | Reads and writes deal snapshot/index data | JDBC/JDBI |
| `continuumSmaMetricsBatch` | `mlsYangDb` | Maintains partitions and writes import results | JDBC/JDBI |
| `continuumSmaMetricsBatch` | `mlsYangRinDb` | Performs inventory and lifecycle backfills | JDBC/JDBI |
| `continuumSmaMetricsBatch` | `mlsYangDealIndexDb` | Uses deal index data during imports and backfills | JDBC/JDBI |
| `continuumSmaMetricsBatch` | `messageBus` | Publishes batch feedback commands to `jms.queue.mls.batchCommands` | Message Bus (JMS) |
| `continuumSmaMetricsBatch` | `continuumDealCatalogService` | Retrieves deal catalog data for deal metrics imports | REST (HTTP) |

## Architecture Diagram References

- Component view (API): `components-continuumSmaMetricsApi`
- Component view (Batch): `components-continuumSmaMetricsBatch`
- Dynamic view (command ingestion): `dynamic-yang-command-smaApi_commandIngestion-flow`
- Dynamic view (batch import): `dynamic-yang-batch-import-flow`

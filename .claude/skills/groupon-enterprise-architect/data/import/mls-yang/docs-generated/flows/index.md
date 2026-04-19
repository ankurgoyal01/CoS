---
service: "mls-yang"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Merchant Lifecycle Service Yang (mls-yang).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [MLS Command Ingestion and Projection](command-ingestion.md) | event-driven | Kafka message arrival on any MLS command topic | Consumes MLS command messages and projects merchant state into read-model databases |
| [CLO Transaction Processing](clo-transaction-processing.md) | event-driven | Kafka message on `mls.CloTransaction` topic | Processes card-linked offer AUTH/CLEAR/REWARD transactions into the CLO read model |
| [History Event Processing](history-event-processing.md) | event-driven | Kafka message on `mls.HistoryEvent` topic | Writes whitelisted merchant history events to history and Yang databases with idempotency |
| [Deal Metrics Batch Import](deal-metrics-batch-import.md) | scheduled | Quartz cron trigger (every 3 hours + daily retro) | Imports deal engagement metrics from Janus/Hive into the Yang deal metrics store |
| [Batch Feedback Publication](batch-feedback-publication.md) | event-driven | Batch job completion | Publishes a feedback command to the MLS message bus after each scheduled job completes |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Command Ingestion**: Spans Kafka (MLS command producers), `continuumSmaMetricsApi` (command ingestion pipeline), and all four Yang PostgreSQL databases. Architecture dynamic view: `dynamic-yang-command-smaApi_commandIngestion-flow`.
- **Batch Import**: Spans `continuumSmaMetricsBatch` (Quartz scheduler + import workers), Hive/Janus, Deal Catalog service, `mlsYangDb`, `mlsYangRinDb`, `mlsYangDealIndexDb`, and the MLS message bus for feedback. Architecture dynamic view: `dynamic-yang-batch-import-flow`.

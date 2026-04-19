---
service: "EC_StreamJob"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for EC Stream Job.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Janus Event Ingestion and Filtering](janus-event-ingestion.md) | event-driven | New Avro message on `janus-tier2` or `janus-tier2_snc1` Kafka topic | Decodes Avro event bytes, filters for valid dealview/dealpurchase events in the correct colo, deduplicates within the partition |
| [TDM User Data Update](tdm-user-data-update.md) | event-driven | Filtered event queue ready after ingestion step | Posts enriched event payloads to TDM `/v1/updateUserData` concurrently across a thread pool |
| [Spark Job Startup and Colo Selection](spark-job-startup.md) | manual | Operator invokes `spark-submit` with colo and env arguments | Bootstraps Spark context, selects Kafka broker + topic, TDM endpoint, and Janus API URL based on colo/env args |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Manual / Operational | 1 |

## Cross-Service Flows

The TDM update flow spans `continuumEcStreamJob` → `kafkaTopicJanusTier2` → `janusApi` → `tdmApi`. The Structurizr dynamic view `TDMUpdateFlow` is defined in `architecture/views/dynamics/tdm-update-flow.dsl` but is currently disabled pending federation of the stub targets into the central model.

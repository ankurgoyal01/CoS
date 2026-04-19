---
service: "keboola"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Keboola Connection.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Pipeline Run Flow](pipeline-run-flow.md) | batch | Scheduled orchestrator trigger or manual run | End-to-end ETL pipeline: extraction from Salesforce, transformation, and batch load to BigQuery |
| [Extraction Flow](extraction-flow.md) | batch | Pipeline Orchestrator schedule | Pulls raw datasets from Salesforce CRM via HTTPS/API and stages them in the Keboola runtime |
| [Ops Notification Flow](ops-notification-flow.md) | event-driven | Pipeline stage completion or failure | Publishes run status and failure alerts to Google Chat via webhook |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The [Pipeline Run Flow](pipeline-run-flow.md) spans three external systems — Salesforce, Keboola Connection, and BigQuery — and is captured in the central architecture dynamic view `dynamic-pipeline-run-flow`. The flow is fully contained within the `continuumKeboolaConnectionService` container and its five internal components.

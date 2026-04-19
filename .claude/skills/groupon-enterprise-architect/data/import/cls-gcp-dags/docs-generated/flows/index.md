---
service: "cls-gcp-dags"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for CLS GCP DAGs.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Scheduled DAG Execution](scheduled-dag-execution.md) | scheduled | Cloud Scheduler time-based trigger | End-to-end CLS DAG lifecycle from schedule trigger through task orchestration to curated data load |
| [Data Validation](data-validation.md) | batch | Initiated by Task Orchestrator within a DAG run | Source completeness and schema validation gate that must pass before curated load proceeds |
| [Curated Data Load](curated-data-load.md) | batch | Initiated by Task Orchestrator after successful validation | Loads validated CLS datasets into curated downstream GCP storage targets |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The primary cross-service interaction is the Cloud Scheduler trigger that initiates DAG execution. All three flows documented here operate within the `continuumClsGcpDags` container boundary. The output of the [Curated Data Load](curated-data-load.md) flow reaches downstream CLS analytics consumers outside this container, but those downstream relationships are tracked in the central Continuum architecture model rather than this service's DSL.

- Architecture dynamic view: `dynamic-continuumClsGcpDags` (see `architecture/views/dynamics/clsGcpDagsFlow.dsl`)

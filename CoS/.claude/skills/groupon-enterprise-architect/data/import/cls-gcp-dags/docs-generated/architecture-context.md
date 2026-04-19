---
service: "cls-gcp-dags"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumClsGcpDags"]
---

# Architecture Context

## System Context

`cls-gcp-dags` is a data pipeline orchestration service within the **Continuum Platform** — Groupon's core commerce engine. It sits in the Data, Analytics & Reporting layer, triggered by Google Cloud Scheduler and orchestrating Airflow DAGs on Cloud Composer. The service does not expose an external API; instead it operates as a batch/scheduled pipeline that reads from CLS data sources and writes validated, curated outputs to downstream GCP storage targets.

Within the Continuum Platform, `continuumClsGcpDags` is a single container (one federated unit) with no currently modeled external container-level relationships, meaning cross-service integration points are managed by the central Continuum architecture model rather than this service's own DSL.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLS GCP DAGs | `continuumClsGcpDags` | DataPipeline | Python, Apache Airflow DAGs | Not specified | Defines and orchestrates Cloud Scheduler-triggered Apache Airflow DAGs for CLS data ingestion and transformation pipelines. |

## Components by Container

### CLS GCP DAGs (`continuumClsGcpDags`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Schedule Trigger (`dagScheduleTrigger`) | Accepts Cloud Scheduler events and initiates CLS DAG execution windows | Airflow scheduler integration |
| Task Orchestrator (`dagTaskOrchestrator`) | Coordinates task dependencies and runtime branching logic for CLS DAG runs | Airflow operators and dependency graph |
| Data Validation Task (`dagDataValidationTask`) | Validates source completeness and schema expectations before loading datasets | Python validation operators |
| Curated Load Task (`dagLoadTask`) | Loads validated outputs into curated downstream storage targets | Python load operators |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dagScheduleTrigger` | `dagTaskOrchestrator` | Triggers DAG runs | Airflow internal scheduler |
| `dagTaskOrchestrator` | `dagDataValidationTask` | Runs data quality checks | Airflow task dependency graph |
| `dagTaskOrchestrator` | `dagLoadTask` | Executes curated data load | Airflow task dependency graph |
| `dagDataValidationTask` | `dagLoadTask` | Passes validated dataset to load task | Airflow task dependency graph |

> No additional container-level external relationships are currently modeled (see `architecture/models/relations.dsl`).

## Architecture Diagram References

- Component: `components-continuumClsGcpDags`
- Dynamic flow: `dynamic-continuumClsGcpDags` (see `architecture/views/dynamics/clsGcpDagsFlow.dsl`)

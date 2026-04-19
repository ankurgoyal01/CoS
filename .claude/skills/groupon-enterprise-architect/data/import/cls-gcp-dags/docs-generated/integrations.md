---
service: "cls-gcp-dags"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

`cls-gcp-dags` has a minimal integration footprint. It is triggered by Google Cloud Scheduler (external GCP platform service) and writes curated outputs to downstream GCP storage targets. No container-level external relationships to other Continuum platform services are currently modeled in the architecture DSL. The architecture DSL notes zero external relationship stubs resolved and zero new elements added for this service during federation (see `federation-tracker.yml`).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Scheduler | Airflow scheduler integration | Emits scheduled triggers that initiate CLS DAG execution windows | yes | Not modeled as a separate Structurizr element |
| Google Cloud Composer (Airflow) | Airflow runtime | Provides the managed Airflow execution environment for all DAGs | yes | Not modeled as a separate Structurizr element |

### Google Cloud Scheduler Detail

- **Protocol**: Airflow scheduler integration (Cloud Scheduler → Cloud Composer trigger)
- **Base URL / SDK**: GCP Cloud Scheduler service; managed through GCP Console / Terraform
- **Auth**: GCP IAM service account
- **Purpose**: Emits time-based triggers that start CLS DAG execution windows, received by the `dagScheduleTrigger` component
- **Failure mode**: If Cloud Scheduler fails to trigger, DAG runs are skipped for that window; Airflow can be configured for catch-up runs
- **Circuit breaker**: No evidence found in codebase.

### Google Cloud Composer (Airflow) Detail

- **Protocol**: Python Airflow operators (internal Airflow runtime)
- **Base URL / SDK**: Google Cloud Composer — managed Apache Airflow environment
- **Auth**: GCP IAM service account
- **Purpose**: Executes the DAG task graph — scheduler, validation operators, and load operators all run within the Composer-managed Airflow environment
- **Failure mode**: If Composer is unavailable, all DAG execution stops; no fallback mechanism is modeled
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

> No evidence found in codebase. No container-level relationships to other Continuum internal services are modeled in the architecture DSL. The DSL `relations.dsl` file explicitly states: "No additional container-level external relationships are currently modeled."

## Consumed By

> Upstream consumers are tracked in the central architecture model. The curated data outputs written by `dagLoadTask` are consumed by downstream analytics and science workloads within the CLS domain, but these relationships are not modeled in this service's DSL.

## Dependency Health

> No evidence found in codebase. No specific health check endpoints, retry policies, or circuit breaker patterns for GCP dependencies are discoverable from the architecture DSL alone. Operational health of Cloud Composer and Cloud Scheduler is typically monitored via GCP Console dashboards and Cloud Monitoring.

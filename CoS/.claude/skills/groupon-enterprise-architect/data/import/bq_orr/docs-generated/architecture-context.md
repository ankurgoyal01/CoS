---
service: "bq_orr"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBigQueryOrchestration"]
---

# Architecture Context

## System Context

`bq_orr` (BigQuery Orchestration Service) is a container within the `continuumSystem` (Continuum Platform). It sits at the boundary between Groupon's internal data engineering CI/CD pipeline and the Google Cloud Platform data infrastructure. The service packages Airflow DAGs from this repository and deploys them via `deploybot_gcs` into GCS-backed Cloud Composer environments, from which the DAGs are picked up and executed against Google BigQuery. The Continuum Platform hosts this orchestration layer; Google Cloud owns the execution substrate.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| BigQuery Orchestration Service | `continuumBigQueryOrchestration` | Service | Python, Apache Airflow | — | Repository-managed Apache Airflow DAG package deployed through CI/CD into shared Composer environments. |

## Components by Container

### BigQuery Orchestration Service (`continuumBigQueryOrchestration`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `bqOrr_shankarTestDag` | Daily Airflow DAG defined in `orchestrator/hello_world.py`; executes a Python callable (`print_hello`) on a daily schedule | PythonOperator DAG |
| `bqOrr_amitTestDag` | Daily Airflow DAG defined in `orchestrator/hello_world2.py`; executes a Python callable (`print_hello`) on a daily schedule | PythonOperator DAG |
| `bqOrr_deployBotConfig` | Environment-specific deployment configuration from `.deploy_bot.yml`; drives artifact promotion across dev, staging, and production | YAML Configuration |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBigQueryOrchestration` | `bigQuery` | Orchestrates data warehouse workloads | Apache Airflow / BigQuery API |
| `bqOrr_deployBotConfig` | `bqOrr_shankarTestDag` | Publishes DAG artifact as part of deployment flow | deploybot_gcs (GCS upload) |
| `bqOrr_deployBotConfig` | `bqOrr_amitTestDag` | Publishes DAG artifact as part of deployment flow | deploybot_gcs (GCS upload) |
| `continuumBigQueryOrchestration` | `preGcpComposerRuntime` | Deploys and executes DAGs on shared Composer environment (stub — not in federated model) | GCS bucket sync |

## Architecture Diagram References

- Component: `components-continuum-big-query-orchestration`
- Dynamic (deployment and execution): `dynamic-bq-orr-bqOrr_shankarTestDag-deploy`

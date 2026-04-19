---
service: "bq_orr"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

The BigQuery Orchestration Service integrates with two external Google Cloud Platform services (Cloud Composer and BigQuery) and one internal Groupon infrastructure dependency (`pre-gcp-composer` shared environment). All integrations are outbound — this service does not expose any inbound API surface. The deployment path relies on the Groupon `deploybot_gcs` tooling to bridge the CI/CD pipeline with GCP storage.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google BigQuery | BigQuery API (Apache Airflow) | Target data warehouse for DAG-orchestrated workloads | yes | `bigQuery` |
| Google Cloud Composer | GCS bucket sync / Airflow scheduler | Runtime execution environment for deployed DAGs | yes | `preGcpComposerRuntime` |

### Google BigQuery Detail

- **Protocol**: Apache Airflow operators using the BigQuery API
- **Base URL / SDK**: Managed by Cloud Composer's Airflow workers; not directly configured in this repository
- **Auth**: GCP service account credentials managed by the Cloud Composer environment
- **Purpose**: Executes data warehouse workloads (queries, transformations, loads) defined in Airflow DAG tasks
- **Failure mode**: DAG tasks fail with retry; Airflow marks task as failed after configured retries (1 retry, 5-minute delay)
- **Circuit breaker**: Not configured — Airflow's retry mechanism provides limited fault tolerance

### Google Cloud Composer Detail

- **Protocol**: GCS bucket file upload via `deploybot_gcs`; Airflow scheduler reads DAG files from the GCS-backed DAG bucket
- **Base URL / SDK**: `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0`
- **Auth**: Kubernetes service account credentials in the target cluster; environment-specific namespace (`bigquery-dev`, `bigquery-staging`, `bigquery-production`)
- **Purpose**: Hosts and schedules Airflow DAG execution; provides the managed Airflow environment
- **Failure mode**: If the Composer environment is unavailable, DAG deployment and execution are blocked; service status tracked at https://status.cloud.google.com/
- **Circuit breaker**: Not configured — Composer availability is monitored externally via GCP status page

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| pre-gcp-composer | GCS bucket / Kubernetes | Shared Google Cloud Composer environment that hosts DAG execution; listed as a dependency in `.service.yml` | `preGcpComposerRuntime` (stub) |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

This service is a DAG deployment package — it is not consumed by other services through an API. Data engineering teams and analysts interact with the deployed DAGs via the Airflow UI on the Cloud Composer environment.

## Dependency Health

- **Google BigQuery**: 99.99% availability SLA per https://cloud.google.com/bigquery/sla. Groupon subscribes to GCP Premium Support with a 15-minute response guarantee for P1 issues.
- **Google Cloud Composer**: Status tracked at https://status.cloud.google.com/. No programmatic health check is configured within this repository.
- **deploybot_gcs**: Deployment tooling invoked during CI/CD. Failures surface in Jenkins build logs and Slack channel `grim---pit`.

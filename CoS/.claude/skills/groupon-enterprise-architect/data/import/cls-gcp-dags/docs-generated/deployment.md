---
service: "cls-gcp-dags"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "Google Cloud Composer (managed Apache Airflow)"
environments: []
---

# Deployment

## Overview

`cls-gcp-dags` is deployed as Apache Airflow DAG definitions on Google Cloud Composer — GCP's fully managed Airflow service. DAG Python files are deployed to the Cloud Composer DAGs bucket (a GCS bucket), from which Composer automatically picks up and schedules them. No Dockerfile or container image is built for this service directly; the execution environment is provided and managed by Cloud Composer. Deployment details beyond the Airflow/Composer pattern are managed externally.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None (DAG files) | DAG Python files are stored in a GCS bucket managed by Cloud Composer |
| Orchestration | Google Cloud Composer | Managed Apache Airflow environment on GCP |
| Load balancer | Not applicable | No inbound API surface |
| CDN | Not applicable | No web content served |

## Environments

> No evidence found in codebase. Environment names, regions, and URLs are managed externally via GCP project configuration and are not discoverable from the architecture DSL.

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| No evidence found in codebase. | | | |

## CI/CD Pipeline

- **Tool**: No evidence found in codebase.
- **Config**: No evidence found in codebase. (Source repo: `https://github.groupondev.com/cls/cls-gcp-dags`)
- **Trigger**: No evidence found in codebase.

### Pipeline Stages

> No evidence found in codebase. Deployment configuration managed externally. For GCP Cloud Composer DAG deployments, the typical pattern is: lint/test Python DAGs, then copy DAG files to the Composer GCS bucket.

## Scaling

> Not applicable. Google Cloud Composer manages Airflow worker scaling automatically. DAG-level parallelism is controlled by Airflow configuration (e.g., `max_active_runs`, `concurrency` per DAG), but no specific values are discoverable from the DSL.

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Managed by Cloud Composer | No evidence found in codebase. |
| Memory | Managed by Cloud Composer | No evidence found in codebase. |
| CPU | Managed by Cloud Composer | No evidence found in codebase. |

## Resource Requirements

> No evidence found in codebase. Resource requirements for Cloud Composer workers are configured at the Composer environment level, not within the DAG repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found in codebase. | No evidence found in codebase. |
| Memory | No evidence found in codebase. | No evidence found in codebase. |
| Disk | No evidence found in codebase. | No evidence found in codebase. |

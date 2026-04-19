---
service: "coupons_bi_airflow"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "GCP Cloud Composer (managed Airflow)"
environments: [staging, production]
---

# Deployment

## Overview

coupons_bi_airflow is deployed as a set of Python DAG files on GCP Cloud Composer, which is Google's fully managed Apache Airflow service running on Kubernetes. DAG files are uploaded to a GCS bucket that Cloud Composer monitors; new or updated DAGs are automatically picked up by the Airflow scheduler. There is no application server or container image to build — the service artifact is the collection of Python DAG files.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | GCP Cloud Composer (managed) | Airflow workers run in managed GKE pods |
| Orchestration | GCP Cloud Composer | Kubernetes-backed Airflow environment |
| DAG storage | Google Cloud Storage | DAGs uploaded to Cloud Composer DAG bucket |
| Data warehouse | Teradata | On-premises enterprise warehouse |
| Cloud warehouse | BigQuery | GCP-native analytical store |
| Load balancer | Not applicable | No inbound HTTP traffic |
| CDN | Not applicable | No static assets served |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pipeline validation and testing | GCP (Groupon-managed region) | Airflow UI — internal |
| production | Live BI data ingestion | GCP (Groupon-managed region) | Airflow UI — internal |

## CI/CD Pipeline

- **Tool**: CI/CD managed via repository pipeline (evidence: standard Groupon CI practices)
- **Config**: DAG deployment triggered by push to the designated DAG GCS bucket
- **Trigger**: On merge to main branch — DAG files are synced to the Cloud Composer DAG bucket

### Pipeline Stages

1. Lint / syntax check: Python DAG files validated for syntax errors and Airflow import correctness
2. Deploy to staging: DAG files uploaded to staging Cloud Composer GCS DAG bucket
3. Smoke test: Airflow scheduler picks up DAGs; basic DAG load validation
4. Deploy to production: DAG files promoted to production Cloud Composer GCS DAG bucket

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Cloud Composer autoscaling (GKE node pool) | Managed by GCP |
| Memory | Managed by Cloud Composer worker pod limits | Configured in Cloud Composer environment |
| CPU | Managed by Cloud Composer worker pod limits | Configured in Cloud Composer environment |

## Resource Requirements

> Deployment configuration managed externally — resource limits are configured in the Cloud Composer environment settings, not in this repository.

---
service: "seo-deal-redirect"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "gcp-composer-dataproc"
environments: ["dev", "stable", "production"]
---

# Deployment

## Overview

SEO Deal Redirect is deployed as an Apache Airflow DAG to GCP Cloud Composer (managed Airflow). There is no long-running containerized service — the pipeline provisions a transient GCP Dataproc cluster for each DAG run, executes Hive and PySpark jobs, then tears down the cluster. DAG Python files and job artifacts are deployed to a GCS bucket by DeployBot. Production deployments require manual approval in DeployBot after staging promotion.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Orchestrator | GCP Cloud Composer (Airflow) | Managed Airflow; DAG files in GCS DAGs bucket |
| Compute | GCP Dataproc | Transient cluster per run; 1 master + 2 workers (`n1-standard-8`), image `1.5.63-debian10` |
| Storage | GCP Cloud Storage | DAGs bucket, artifacts bucket (`gs://grpn-dnd-prod-analytics-common/`) |
| Secrets | GCP Secret Manager | TLS keystore loaded via cluster init action `load-certificates.sh` |
| Deployment agent | DeployBot (`deploybot_gcs:v3.0.0`) | Copies DAG and job files to the Composer GCS bucket |
| CI/CD | Jenkins (`Jenkinsfile`) | Runs tests and triggers DeployBot on merge to `main` |
| Network | GCP VPC (internal IPs only) | Dataproc cluster uses `internal_ip_only: true`; subnetwork in `prj-grp-shared-vpc-prod-2511` |

## Environments

| Environment | Purpose | Region | Airflow UI |
|-------------|---------|--------|------------|
| dev | Development (deprecated — not actively supported by gdoop team) | us-central1 | `https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com` |
| stable | Staging / integration testing | us-central1 | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com` |
| production | Live production pipeline | us-central1 | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com` |

### Production GCP Details

| Resource | Value |
|----------|-------|
| GCP Project | `prj-grp-c-common-prod-ff2b` |
| Dataproc cluster name | `seo-deal-redirect` |
| Dataproc region | `us-central1` |
| Dataproc zone | `us-central1-f` |
| Service account | `loc-sa-c-seo-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com` |
| DAGs GCS bucket | `us-central1-grp-shared-comp-9260309b-bucket` |
| DAG schedule | `0 5 15 * *` (5:00 AM UTC, 15th of each month) |

### Stable GCP Details

| Resource | Value |
|----------|-------|
| GCP Project | `prj-grp-c-common-stable-c036` |
| Kubernetes cluster | `gcp-stable-us-central1` |
| DAGs GCS bucket | `us-central1-grp-shared-comp-03dba3de-bucket` |
| Kubernetes namespace | `seo-deal-redirect-staging` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Merge to `main` branch

### Pipeline Stages

1. **Build / Test**: Runs `pytest tests -v` (PySpark and enrichment pipeline tests); runs legacy `python3 -m unittest discover tests`
2. **Release tag**: Jenkins creates a releasable artifact for `main` branch commits
3. **Deploy to staging**: DeployBot automatically deploys to `staging-us-central1` (GCS DAGs bucket `us-central1-grp-shared-comp-03dba3de-bucket`)
4. **Promote to production**: DeployBot promotes staging artifact to `production-us-central1`; production deployment is `manual: true` (requires explicit approval in DeployBot UI at `https://deploybot.groupondev.com/seo/seo-deal-redirect`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc master | Fixed | 1 × `n1-standard-8`, 100 GB standard disk |
| Dataproc workers | Fixed | 2 × `n1-standard-8`, 100 GB standard disk |
| Spark executor instances | Fixed per job | 200 executors (api_upload, api_upload_table_population) |
| Spark memory (executor) | Fixed | 8 GB executor memory + 12 GB overhead |
| Spark memory (driver) | Fixed | 8 GB |
| Spark cores (executor) | Fixed | 4 cores per executor |

## Resource Requirements

| Resource | Value (per Dataproc node) |
|----------|--------------------------|
| Machine type | `n1-standard-8` (8 vCPUs, ~30 GB RAM) |
| Boot disk | 100 GB `pd-standard` |
| Spark driver memory | 8 GB |
| Spark executor memory | 8 GB + 12 GB overhead |
| Spark executor cores | 4 |
| Spark executor instances | 200 (api_upload jobs) |

---
service: "badges-trending-calculator"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "dataproc"
environments: [dev, staging, prod, emea-prod]
---

# Deployment

## Overview

Badges Trending Calculator runs as a long-running Apache Spark Streaming job on Google Cloud Dataproc, managed by Apache Airflow (Google Cloud Composer). An Airflow DAG (`badges-trending-calculator-job`) runs daily at 03:22 UTC, deleting the existing Dataproc cluster, creating a fresh cluster, submitting the Spark job, and tearing down the cluster again after the job terminates. The built fat JAR is published to Groupon's internal Artifactory instance and fetched by Dataproc at job submit time. CI/CD is handled by Jenkins using the `dataPipeline` shared library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (build) | Docker (hseeberger/scala-sbt:8u222) | `.ci/docker-compose.yml` — used only for building the fat JAR |
| Compute | Google Cloud Dataproc (Hadoop YARN) | Cluster `badges-trending-calculator`, project `prj-grp-c-common-prod-ff2b`, region `us-central1` |
| Orchestration | Apache Airflow (GCP Cloud Composer) | DAG `badges-trending-calculator-job` in `orchestrator/badges_trending_calculator.py` |
| Artifact storage | Groupon Artifactory | `https://artifactory.groupondev.com/artifactory/releases/com/groupon/badges/...` |
| Secrets | GCP Secret Manager | Init script `load-certificates-with-truststore.sh` injects TLS certs at cluster startup |
| Networking | GCP Shared VPC (internal IP only) | Subnet `sub-vpc-prod-sharedvpc01-us-central1-private`, tags `allow-iap-ssh`, `dataproc-vm` |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| dev | Development / manual testing | us-central1 | `prj-grp-consumer-dev-14a6` |
| staging (stable) | Pre-production validation | us-central1 | `prj-grp-c-common-stable-c036` |
| prod (NA) | NA production traffic | us-central1 | `prj-grp-c-common-prod-ff2b` |
| emea-prod | EMEA production traffic | eu-west-1 (AWS) / EU | Separate config profile |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Shared library**: `java-pipeline-dsl@dpgm-1396-pipeline-cicd`
- **Trigger**: Push/PR on `master` or `release_branch_MMDDYYYY` branches; deploys to `staging-us-central1`

### Pipeline Stages

1. **Build**: Runs `fab build` inside the `sbt_docker` container to produce the assembly fat JAR.
2. **Pre-release**: Runs `fab upload` to publish the JAR to Artifactory under the artifact version.
3. **Deploy**: Deploys the orchestrator (DAG files) artifact to the target Airflow Composer environment via Deploybot.
4. **Promote**: Manual promotion through dev → staging → production via Deploybot.

## Scaling

| Dimension | Strategy | Config (Production) |
|-----------|----------|---------------------|
| Driver | Fixed 1 node (master) | `e2-standard-8`, 2g driver memory |
| Executors | Fixed instance count | 8 executors, 2 cores each, 6g memory |
| Dynamic allocation | Disabled | `spark.streaming.backpressure.enabled=false` |
| Cluster lifecycle | Ephemeral (daily recreation) | `idle_delete_ttl=1800s` |
| Batch interval | 600 seconds (10 min) in prod | `--batch_interval 600` arg |

## Resource Requirements

| Resource | Master Node | Worker Nodes |
|----------|-------------|-------------|
| Machine type | e2-standard-8 | e2-standard-8 |
| Number of nodes | 1 | 2 |
| Boot disk | 500 GB pd-standard | 500 GB pd-standard |
| Spark driver memory | 2g | — |
| Spark executor memory | — | 6g per executor |
| Spark executor cores | — | 2 per executor |
| Spark executor instances | — | 8 |
| Dataproc image | 1.5-debian10 | 1.5-debian10 |

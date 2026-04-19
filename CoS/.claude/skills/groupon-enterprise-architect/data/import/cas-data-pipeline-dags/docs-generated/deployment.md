---
service: "cas-data-pipeline-dags"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev-us-central1", "staging-us-central1", "production-us-central1"]
---

# Deployment

## Overview

Deployment of `cas-data-pipeline-dags` involves two artefacts: (1) the Python DAG files (and JSON configs) under `orchestrator/`, which are synced to the GCS `COMPOSER_DAGS_BUCKET` for each environment, and (2) the Scala Spark assembly JAR, which is built with sbt and published to Nexus/Artifactory, then referenced by DAG configs via `artifact_base_path` / `artifact_version`. The deploy-bot (`deploybot_gcs:v2.0.1`) handles the GCS sync. All three environments are GCP Cloud Composer instances in `us-central1`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (`sbt_docker:v0.1`) | Used only for CI build — `docker.groupondev.com/consumer_data_engineering/sbt_docker:v0.1`; runtime uses Cloud Composer managed environment |
| Orchestration | GCP Cloud Composer (Airflow) | DAG files deployed to `COMPOSER_DAGS_BUCKET` per environment |
| Compute (runtime) | GCP Dataproc | Ephemeral clusters created/deleted per DAG run; machine type `n1-standard-8`; image `1.5-debian10` |
| Deploy tooling | deploy-bot (`deploybot_gcs:v2.0.1`) | Syncs `orchestrator/**` artefacts to target GCS DAG bucket |
| Artifact store | Nexus (`nexus-dev.snc1`) | Stores Spark assembly JAR published by `sbt universal:publish` |
| Load balancer | Not applicable | Batch pipeline — no inbound traffic |
| CDN | Not applicable | — |

## Environments

| Environment | Purpose | Region | GCS DAG Bucket |
|-------------|---------|--------|----------------|
| `dev-us-central1` | Development and testing | `us-central1` | `us-central1-grp-shared-comp-155675d0-bucket` |
| `staging-us-central1` | Pre-production validation | `us-central1` | `us-central1-grp-shared-comp-03dba3de-bucket` |
| `production-us-central1` | Production workloads | `us-central1` | `us-central1-grp-shared-comp-155675d0-bucket` |

Production deployments are gated (`manual: true` in `.deploy_bot.yml`) — staging must promote to production explicitly.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Shared library**: `java-pipeline-dsl@dpgm-1396-pipeline-cicd`
- **Trigger**: Push to releasable branches (`staging_add_cde_frmwrk`, `stable_test`) and any branch for validation
- **Slack notifications**: `cas-notification` channel on any start or failure

### Pipeline Stages

1. **Build** (`optionalBuildStep`): Runs `docker-compose -f .ci/docker-compose.yml run --rm sbt bash -c "cd /app && fab build"` — executes `sbt clean assembly` inside the `sbt_docker:v0.1` container to produce the fat assembly JAR
2. **Pre-release** (`optionalPrereleaseStep`): Runs `fab upload` (`sbt universal:publish`) to publish the assembly JAR to Nexus at `nexus-dev.snc1`
3. **Deploy** (deploy-bot): Syncs `orchestrator/**` files (DAG Python files and JSON configs, per `artifactIncludePattern`) to the target `COMPOSER_DAGS_BUCKET` for the specified `deployTarget` environments (`dev-us-central1`, `staging-us-central1`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Dataproc master | Fixed | 1 × n1-standard-8, 500 GB pd-standard |
| Dataproc workers | Config-driven per DAG | `@worker_num_instances` from `common_vars.json`; all jobs use `spark.executor.instances: 200` |
| Spark memory (email pipelines) | Per-job config | Driver: 8 GB, Executor: 15–20 GB, Cores: 2–4 |
| Spark memory (mobile pipelines) | Per-job config | Driver: 8 GB, Executor: 20 GB, Cores: 4 |
| Spark memory (reporting pipeline) | Per-job config | Driver: 1 GB, Executor: 20 GB, Cores: 4, Instances: 50 |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Dataproc master CPU | n1-standard-8 (8 vCPU) | — |
| Dataproc master memory | n1-standard-8 (30 GB RAM) | — |
| Dataproc master disk | 500 GB pd-standard | — |
| Dataproc worker CPU | n1-standard-8 (8 vCPU) per node | — |
| Dataproc worker memory | n1-standard-8 (30 GB RAM) per node | — |
| Dataproc worker disk | 500 GB pd-standard per node | — |

> Exact worker count per pipeline is resolved at runtime from `@worker_num_instances` in environment-specific `common_vars.json`.

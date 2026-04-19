---
service: "PmpNextDataSync"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "dataproc"
environments:
  - staging
  - production
---

# Deployment

## Overview

PmpNextDataSync uses an ephemeral compute model: Airflow DAGs on Google Cloud Composer create Dataproc clusters on demand per pipeline run, submit Spark jobs, and then delete clusters on completion (or failure). The DAG Python files are deployed to a GCS-backed Composer bucket via the deploy_bot CI tool. The DataSyncCore Spark JAR is built with sbt-assembly and published to Groupon's internal Artifactory, from which Dataproc downloads it at cluster startup. There is no persistent server or container to manage.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Spark application packaging | sbt-assembly fat JAR | `DataSyncCore/build.sbt` — `assembly/mainClass := Some("com.groupon.pmp.Job")` |
| Artifact registry | Artifactory | `https://artifactory.groupondev.com/artifactory/snapshots/` |
| Compute | Google Dataproc (ephemeral clusters) | Dataproc image `2.2-debian12`; cluster created per DAG run |
| Orchestration | Google Cloud Composer (managed Airflow) | DAGs deployed to GCS Composer bucket |
| DAG deployment | deploy_bot with GCS upload | `deploybot_gcs:v3.0.0` Docker image |
| Cluster networking | GCP Shared VPC (private subnet) | `sub-vpc-prod-sharedvpc01-us-central1-private`; internal IP only |
| Cluster init | GCS init script | `gs://grpn-dnd-prod-analytics-common/init/load-certificates.sh` |
| Logging | Google Stackdriver (Cloud Logging) | Dataproc YARN container logging to Stackdriver |

## Environments

| Environment | Purpose | Region | GCS DAGs Bucket |
|-------------|---------|--------|-----------------|
| staging | Integration testing and promotion gate | `us-central1` | `us-central1-grp-shared-comp-03dba3de-bucket` |
| production | Live pipeline execution | `us-central1` | `us-central1-grp-shared-comp-9260309b-bucket` |

## CI/CD Pipeline

- **Tool**: Jenkins (shared library `java-pipeline-dsl`)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push / manual dispatch
- **Deploy targets**: `staging-us-central1`, `production-us-central1`
- **Artifact pattern**: `orchestrator/**` (DAG files and JSON configs)

### Pipeline Stages

1. **Build**: sbt-assembly compiles Scala source and produces fat JAR; published to Artifactory.
2. **Staging deploy**: deploy_bot uploads `orchestrator/**` to the staging Composer DAGs GCS bucket; Kubernetes namespace `pmp-datasync-staging`.
3. **Promote**: Staging deploys auto-promote to production (marked `manual: true` in deploy_bot config — requires approval).
4. **Production deploy**: deploy_bot uploads DAGs to the production Composer bucket; Kubernetes namespace `pmp-datasync-production`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Spark executors | Dynamic allocation | `minExecutors: 2`, `maxExecutors: 100` (datasync/dispatcher); `maxExecutors: 500` (processor) |
| Dataproc workers (medallion NA) | Fixed per cluster config | 1 master (n2-standard-16) + 18 workers (n2-standard-32, 2000 GB disk) |
| Dataproc workers (dispatcher NA) | Fixed per cluster config | 1 master (n2-standard-32) + 15 workers (n2-standard-16, 1000 GB disk) |
| Dataproc workers (enricher NA) | Fixed per cluster config | 1 master (n2-standard-32) + 15 workers (n2-standard-16, 1000 GB disk) |
| JDBC parallelism | Per-flow config | `num_partitions` field in flow YAML (e.g., 10–500) |
| In-app thread pool | Fixed per flow | `optimization.max_parallel_jobs` in flow YAML (e.g., 1–2 for most flows) |

## Resource Requirements

### Medallion DataSync Spark Job (NA)

| Resource | Driver | Executor |
|----------|--------|---------|
| Memory | 14 GB | 14 GB |
| CPU cores | 5 | 5 |

### Medallion Transformation Spark Job (NA)

| Resource | Driver | Executor |
|----------|--------|---------|
| Memory | 12 GB | 25 GB |
| CPU cores | 4 | 8 |

### Medallion Processor Spark Job (NA)

| Resource | Driver | Executor |
|----------|--------|---------|
| Memory | 12 GB | 25 GB |
| CPU cores | 4 | 8 |

### Adaptive Query Execution

All Spark jobs run with AQE enabled:
- `spark.sql.adaptive.coalescePartitions.enabled: true`
- `spark.sql.adaptive.skewJoin.enabled: true`
- `spark.sql.adaptive.advisoryPartitionSizeInBytes: 128MB`

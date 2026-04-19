---
service: "ads-jobframework"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "yarn"
environments: [local, staging, prod]
---

# Deployment

## Overview

ads-jobframework is deployed as a fat JAR (assembled via sbt-assembly) and submitted to a YARN cluster using `spark-submit`. The build and publish pipeline runs in Jenkins using a Docker-based sbt container. Deployment to YARN is managed via Fabric (`fabfile.py`) scripts that upload the artifact to Artifactory and trigger YARN submission on the target environment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (build) | Docker | sbt build image `docker.groupondev.com/consumer_data_engineering/sbt_docker:v0.1` via `.ci/docker-compose.yml` |
| Orchestration | YARN | `spark-submit --deploy-mode cluster --master yarn` |
| Artifact registry | Groupon Artifactory | `http://artifactory.groupondev.com/artifactory/releases/` |
| Job submission | Fabric / spark-submit | `fabfile.py` `deploy` task; manual `fab production:na deploy:<version>` |
| Build tool | sbt with sbt-assembly | Produces fat JAR `ads_jobframework_2-4-0-{version}-assembly.jar` |

## Environments

| Environment | Purpose | Region | Details |
|-------------|---------|--------|---------|
| local | Local development and testing | — | Spark master `local[8]`; staging MySQL and dev GCS bucket |
| staging | Integration and pre-release validation | GCP (stable cluster) | YARN on stable cluster; staging MySQL `ads-job-framework-rw-na-staging-db`; GCS `grpn-dnd-stable-analytics-grp-ai-reporting` |
| prod | Production workloads | GCP us-central1 | YARN on prod cluster; prod MySQL `ads-job-framework-rw-na-production-db`; GCS `grpn-dnd-prod-analytics-grp-ai-reporting` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to any branch (build); push to `main` branch (build + release)

### Pipeline Stages

1. **Checkout**: Shallow clone with submodule initialization via `scmCheckout(cloneSubModules: true, shallowClone: true)`
2. **Build**: Runs `fab build` inside the sbt Docker container; executes `sbt assembly` to produce the fat JAR
3. **Release** (main branch only): Runs `fab upload` inside the sbt Docker container; publishes the assembled JAR to Groupon Artifactory

### Manual Deployment Commands

```
# Deploy local build to NA production
fab production:na deploy:local

# Deploy specific release version to NA production
fab production:na deploy:1.0.1

# Deploy to global production
fab production:gbl deploy:1.0.1
```

## Scaling

YARN dynamic allocation is configured at job submission time:

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Executors | YARN dynamic allocation | `--conf spark.dynamicAllocation.enabled=true --conf spark.dynamicAllocation.minExecutors=10 --conf spark.dynamicAllocation.maxExecutors=10` |
| Executor memory | Static at submit time | `--executor-memory 30g` |
| Driver memory | Static at submit time | `--driver-memory 8g` |
| Executor cores | Static at submit time | `--executor-cores 4` |

## Resource Requirements

| Resource | Request | Notes |
|----------|---------|-------|
| Executor memory | 30 GB | Set at `spark-submit` invocation (from README) |
| Driver memory | 8 GB | Set at `spark-submit` invocation |
| Executor cores | 4 | Set at `spark-submit` invocation |
| Shuffle partitions | 200 | `spark.shufflePartitions = "200"` in all environment configs |
| YARN queue | configurable | `--queue <queue-name>` at submit time |
| Shuffle service | enabled | `--conf spark.shuffle.service.enabled=true` |

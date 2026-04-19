---
service: "janus-muncher"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "dataproc"
environments: [dev, staging, production]
---

# Deployment

## Overview

Janus Muncher is deployed as a fat JAR (`janus-muncher-{version}-jar-with-dependencies.jar`) uploaded to GCS operational buckets. Spark jobs are executed on ephemeral Google Cloud Dataproc clusters created and destroyed per DAG run by the Airflow (Cloud Composer) orchestrator. The Airflow DAG Python files are deployed to Cloud Composer GCS DAG buckets via deploy-bot on every release. There is no long-running application server — each pipeline run provisions a fresh Dataproc cluster, runs the Spark job, and tears down the cluster.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Build image | Docker (dev/CI) | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| JAR artifact | Maven Assembly Plugin | `janus-muncher-{version}-jar-with-dependencies.jar` published to Artifactory and GCS |
| Orchestration | Google Cloud Composer (Airflow) | Managed Airflow — DAGs deployed to Cloud Composer GCS DAG buckets |
| Compute | Google Cloud Dataproc | Ephemeral clusters per DAG run; Dataproc image `1.5.56-ubuntu18` |
| DAG deployment | deploy-bot (`dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0`) | Copies DAG Python files to Cloud Composer bucket via Kubernetes job |
| Load balancer | Not applicable | No inbound HTTP traffic |
| CDN | Not applicable | |

## Environments

| Environment | Purpose | Region | Dataproc Project | Composer DAG Bucket |
|-------------|---------|--------|-----------------|---------------------|
| dev | Development and integration testing | us-central1 | (dev project) | `us-central1-grp-pre-compose-843218f2-bucket` |
| staging | Pre-production validation | us-central1 | (staging project) | `us-central1-grp-pre-compose-9cdc6404-bucket` |
| production | Live production pipeline | us-central1 | `prj-grp-janus-prod-0808` | `us-central1-grp-pre-compose-52d3a0bc-bucket` |

## CI/CD Pipeline

- **Tool**: Jenkins (shared library `java-pipeline-dsl@dpgm-1396-pipeline-cicd`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` or `deploytest` branches; release tags

### Pipeline Stages

1. **Build**: `docker-compose -f .ci/docker-compose.yml run -T test mvn -U -B clean verify -DskipDocker=true` — compiles Scala, runs ScalaTest unit tests
2. **Pre-release**: `mvn -U -B clean deploy -DskipTests -Drevision=$ARTIFACT_VERSION` — builds fat JAR and publishes to Artifactory
3. **Deploy dev**: deploy-bot copies DAG files to `dev-us-central1` Cloud Composer bucket (`KUBERNETES_NAMESPACE=grpn-data-pipelines-staging`)
4. **Deploy staging**: deploy-bot copies DAG files to `staging-us-central1` Cloud Composer bucket
5. **Deploy production**: Manual gate — deploy-bot copies DAG files to `production-us-central1` Cloud Composer bucket (`kubernetes_cluster: gcp-production-us-central1`)

### JAR Artifact Path

- Artifactory: `https://artifactory.groupondev.com/artifactory/releases/com/groupon/data-engineering/janus-muncher/{version}/janus-muncher-{version}-jar-with-dependencies.jar`
- GCS (production): `gs://prod-us-janus-operational-bucket/jar/janus-muncher-{version}-jar-with-dependencies.jar`

## Dataproc Cluster Configuration (Production — Delta Job)

| Parameter | Value |
|-----------|-------|
| Master machine type | `n1-standard-4` (1 node) |
| Worker machine type | `e2-highmem-8` (13 nodes) |
| Boot disk | `pd-standard`, 100 GB per node |
| Dataproc image | `1.5.56-ubuntu18` |
| Cluster lifecycle | idle delete TTL: 300 s; auto-delete TTL: 14400 s (4 hours) |
| Service account | `sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com` |
| Network | `sub-vpc-prod-sharedvpc01-us-central1-private` (internal IP only) |
| Init script | `gs://prod-us-janus-operational-bucket/initscript.sh` |

## Dataproc Cluster Configuration (Production — Backfill Job)

| Parameter | Value |
|-----------|-------|
| Worker machine type | `e2-highmem-8` (25 nodes) |
| Cluster lifecycle | idle delete TTL: 300 s; auto-delete TTL: 14400 s |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Spark workers | Static per cluster config (13 workers delta, 25 workers backfill) | Per DAG cluster config |
| Spark dynamic allocation | Enabled (`spark.dynamicAllocation.enabled = true`) | Executor scaling within cluster |
| Spark driver memory | 8 GB (delta and backfill) | `spark.driver.memory = 8G` |
| Spark shuffle partitions | 900 | `spark.sql.shuffle.partitions = 900` |
| Executor memory overhead | 2 GB (delta) | `spark.executor.memoryOverhead = 2G` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Driver memory | 8 GB | 8 GB |
| Executor memory overhead | 2 GB | — |
| Workers (delta) | 13 × e2-highmem-8 (64 GB RAM, 8 vCPU each) | — |
| Workers (backfill) | 25 × e2-highmem-8 | — |
| Boot disk | 100 GB per node | — |

## Notification

- Slack channel: `janus-robots`
- deploy-bot events: `start`, `complete`, `override`
- Jenkins: pings commit author on failure

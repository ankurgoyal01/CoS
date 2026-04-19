---
service: "janus-user-activity-store"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes + dataproc"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

Janus User Activity Store is deployed as a two-layer system. The Airflow DAG artifacts (Python orchestration scripts) are deployed to Cloud Composer (managed Airflow) buckets on GCP using a deploy-bot GCS mechanism. The Spark application JAR is published to Artifactory and referenced by the Airflow DAG at runtime — the JAR runs on ephemeral Google Cloud Dataproc clusters created and destroyed per hourly execution. CI/CD is managed by Jenkins using the `dataPipeline` shared library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| CI image (build/test) | Docker | `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` (`.ci/Dockerfile`) |
| Spark runtime | Google Cloud Dataproc 1.5.56-ubuntu18 | Ephemeral cluster per DAG run; `us-central1` region |
| Orchestration | Apache Airflow (Cloud Composer) | DAG deployed to `COMPOSER_DAGS_BUCKET` per environment |
| JAR artifact store | Groupon Artifactory | `https://artifactory.groupondev.com/artifactory/releases/com/groupon/dnd-gcp-migration-ingestion/janus-user-activity-store/{version}/` |
| Deploy mechanism | deploy-bot GCS | `docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0` |
| Kubernetes cluster (deploy-bot) | GKE `gcp-stable-us-central1` (dev/staging), `gcp-production-us-central1` (prod) | Deploy-bot runs in Kubernetes; deploys DAGs to Composer buckets |
| Load balancer | Not applicable | No HTTP surface |
| CDN | Not applicable | No HTTP surface |

## Environments

| Environment | Purpose | Region | Kubernetes Namespace | Bigtable Instance |
|-------------|---------|--------|---------------------|-------------------|
| dev | Development testing | us-central1 | `grpn-data-pipelines-dev` | `grp-bigtable-dev-analytics` |
| staging | Pre-production validation | us-central1 | `grpn-data-pipelines-staging` | `grp-bigtable-stable-analytics` |
| production | Live hourly user activity ingestion | us-central1 | `grpn-data-pipelines-production` | `grp-bigtable-prod-analytics` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch; also supports manual dispatch

### Pipeline Stages

1. **Build and Test**: Runs `mvn -U -B clean verify -DskipDocker=true` inside `.ci/docker-compose.yml` Docker container (Java 11 Maven image). Includes unit tests and integration tests using Bigtable emulator via Testcontainers.
2. **Pre-release (Deploy artifact)**: On main branch, runs `mvn -U -B clean deploy -DskipTests -Drevision=$ARTIFACT_VERSION` to publish JAR with dependencies to Artifactory.
3. **Deploy to dev**: Automatically deploys DAG artifacts to `dev-us-central1` after successful build.
4. **Deploy to staging**: Promoted from dev (`promote_to: staging-us-central1`).
5. **Deploy to production**: Manual gate (`manual: true`) — promotes from staging to `production-us-central1`.

### Deploy-bot Configuration (`.deploy_bot.yml`)

| Target | Environment | Kubernetes Cluster | Promotion |
|--------|-------------|-------------------|-----------|
| `dev-us-central1` | dev | `gcp-stable-us-central1` | Promotes to staging |
| `staging-us-central1` | staging | `gcp-stable-us-central1` | Promotes to production |
| `production-us-central1` | production | `gcp-production-us-central1` | Manual only |

Deployment notifications are sent to Slack channel `janus-robots` on `start`, `complete`, and `override` events.

## Scaling

### Dataproc Cluster Configuration (per environment — dev/staging/production)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Master nodes | Fixed | 1 × `n1-standard-4` (4 vCPU, 15 GB RAM), 100 GB pd-standard disk |
| Worker nodes | Fixed | 5 × `n1-standard-4` (4 vCPU, 15 GB RAM), 100 GB pd-standard disk |
| Spark executor cores | Fixed | 4 cores per executor (`spark.executor.cores=4`) |
| Dynamic allocation | Enabled | `spark.dynamicAllocation.enabled=true` |
| Cluster lifetime | TTL-based | Idle delete after 300s; auto-delete after 7200s |

## Resource Requirements

| Resource | Per Worker Node |
|----------|----------------|
| Machine type | `n1-standard-4` |
| vCPU | 4 |
| Memory | ~15 GB |
| Disk | 100 GB pd-standard |

Spark JVM compile-time heap settings (from `pom.xml`): `-Xms512m`, `-Xmx1536m`, `-Xss128m`.

## Versioning

The artifact version follows the pattern `{major-minor}.{patch}`:
- `major-minor` is hardcoded in `pom.xml` (current: `1.0`)
- `patch` is injected at build time via `-Drevision=$ARTIFACT_VERSION` (defaults to `local-SNAPSHOT`)

The JAR is referenced by exact version in the Airflow DAG via `$PIPELINE_ARTIFACT_VERSION` Airflow Variable, ensuring reproducible deployments.

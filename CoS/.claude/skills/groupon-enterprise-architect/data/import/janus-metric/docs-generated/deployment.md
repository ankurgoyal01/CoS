---
service: "janus-metric"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "dataproc"
environments: ["staging", "production"]
---

# Deployment

## Overview

janus-metric deploys as an ephemeral Apache Spark batch job on Google Cloud Dataproc. There is no long-running container or Kubernetes deployment for the Spark application itself. Instead, four Apache Airflow DAGs (managed in Cloud Composer) create a Dataproc cluster on demand, submit the Spark JAR, and delete the cluster on completion. The JAR is fetched from Groupon's Artifactory instance at deploy time. Deploy-bot handles pushing the DAG files to the target GCS Composer bucket.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (CI only) | `.ci/docker-compose.yml` uses `docker.groupondev.com/jtier/dev-java11-maven:2021-10-14-2047f4d` for test/build |
| Orchestration | Google Cloud Dataproc (ephemeral) | Created per-DAG-run; deleted after job completion |
| DAG scheduler | Apache Airflow (Cloud Composer) | DAGs deployed to GCS Composer bucket via deploy-bot |
| Artifact storage | Artifactory | `https://artifactory.groupondev.com/artifactory/releases/com/groupon/data-engineering/janus-metrics-aggregator/` |
| Load balancer | Not applicable | No inbound traffic |
| CDN | Not applicable | No web assets |

## Environments

| Environment | Purpose | Region | Kubernetes / GCP Cluster |
|-------------|---------|--------|--------------------------|
| staging (stable) | Pre-production validation | us-central1 | `gcp-stable-us-central1` |
| production | Live metric aggregation | us-central1 | `gcp-production-us-central1` |

### Staging GCS Buckets
- Composer DAGs: `us-central1-grp-pre-compose-9cdc6404-bucket`
- Namespace: `grpn-data-pipelines-staging`
- Dataproc staging: `grpn-dnd-ingestion-janus-prod-dataproc-staging`

### Production GCS Buckets
- Composer DAGs: `us-central1-grp-pre-compose-52d3a0bc-bucket`
- Namespace: `grpn-data-pipelines-production`
- Dataproc temp: `grpn-dnd-ingestion-janus-prod-dataproc-temp`

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch (also `janus-1441-metrics-enhancement`); deploys to staging automatically; production is `manual: true`
- **Slack notifications**: `#janus-robots`

### Pipeline Stages

1. **Test**: Runs `mvn clean verify` inside Docker Compose (`docker-compose.yml` with `dev-java11-maven`)
2. **Pre-release / Package**: Runs `mvn clean deploy -DskipTests -Drevision=$ARTIFACT_VERSION` to publish JAR to Artifactory
3. **Deploy to staging**: Deploy-bot copies DAG files to `COMPOSER_DAGS_BUCKET` on `gcp-stable-us-central1` Kubernetes cluster
4. **Deploy to production**: Manual approval required; deploy-bot copies DAG files to production Composer bucket on `gcp-production-us-central1`

## Airflow DAGs

| DAG ID | Schedule | Main Class | Description |
|--------|----------|-----------|-------------|
| `janus-metric` | `@hourly` | `com.groupon.janus.ultron.JanusMetricsUltronRunner` | Janus volume and quality cube aggregation |
| `janus-raw-metric` | `@hourly` | `com.groupon.janus.ultron.JanusMetricsRawUltronRunner` | Raw event audit cube aggregation across 11 source topics |
| `juno-metric` | `@daily` | `com.groupon.janus.ultron.JunoMetricsUltronRunner` | Juno hourly volume cube aggregation |
| `janus-cardinality-topN` | `@weekly` | `com.groupon.janus.cardinality.AttributeCardinalityJobMain` | Attribute cardinality and top-N value computation |

## Scaling

Dataproc clusters are provisioned per-run; cluster sizing is defined in the Python config per environment.

| DAG / Job | Master | Workers | Machine Type |
|-----------|--------|---------|-------------|
| janus-metric | 1x n1-standard-4 | 2x n1-standard-4 | pd-standard 100GB boot disk |
| janus-raw-metric | 1x n1-standard-4 | 2x n1-standard-4 | pd-standard 100GB boot disk |
| juno-metric | 1x n1-standard-4 | 4x n1-standard-4 | pd-standard 100GB boot disk |
| janus-cardinality-topN | 1x n1-standard-4 | 10x n1-standard-4 | pd-standard 100GB boot disk |

## Resource Requirements

| Resource | Configuration |
|----------|--------------|
| Dataproc image | `1.5.56-ubuntu18` |
| Spark deploy mode | `cluster` |
| Spark dynamic allocation | enabled |
| Spark network timeout | `50000` |
| JVM heap (Maven build) | -Xms512m / -Xmx1536m |
| Cluster idle delete TTL | 300 seconds (5 minutes) |
| Cluster auto delete TTL | 18000 seconds (5 hours) for Janus/cardinality; 43200 seconds (12 hours) for Juno |
| Cluster create retries | 3 |

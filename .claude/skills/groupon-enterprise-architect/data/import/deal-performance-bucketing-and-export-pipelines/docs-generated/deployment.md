---
service: "deal-performance-bucketing-and-export-pipelines"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "aws-emr"
environments: ["na-production", "na-staging", "emea-production", "emea-staging", "development"]
---

# Deployment

## Overview

The service is packaged as a shaded JAR and submitted to an AWS EMR (Elastic MapReduce) Spark cluster via `spark-submit`. Jobs are orchestrated and scheduled by Apache Airflow (relevance-airflow). The CI pipeline builds and publishes the JAR via Jenkins (Conveyor CI). No long-running server process is deployed — each pipeline run starts a Spark application on EMR, processes data, and terminates.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (build only) | `.ci/Dockerfile` (dev-java11-maven:2021-10-14); `.ci/docker-compose.yml` for local test |
| Build artifact | Shaded JAR | `deal-performance-data-pipelines-*-shaded.jar` (Maven shade plugin) |
| Compute | AWS EMR (Spark on YARN) | Cluster capacity configured in `ranking-terraform` repo (`envs/prod/account.hcl`) |
| Orchestration | Apache Airflow | Hosted relevance-airflow; tasks: DpsUserDealBucketingTask, DpsDbExportTask, DpsDbCleanerTask |
| Storage | GCS | `gs://grpn-dnd-prod-analytics-grp-mars-mds` (NA prod); `gs://grpn-dnd-stable-analytics-grp-mars-mds` (NA staging) |
| Database | GDS PostgreSQL 13 | `deal_perf_v2_prod` (NA prod); `deal_perf_v2_stg` (NA staging) |
| Metrics | Wavefront via Telegraf | Telegraf endpoint configured per environment in YAML config |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| NA Production | Live production data processing | NA (us-central1 GCP) | AWS account `grpn-dnd-prod` |
| NA Staging | Pre-production validation | NA (us-central1 GCP) | AWS account `grpn-dnd-stable` |
| EMEA Production | EMEA region production processing | EMEA | AWS account (EMEA) |
| EMEA Staging | EMEA pre-production validation | EMEA | AWS account (EMEA staging) |
| Development (local) | Local developer testing with DirectRunner | Local | `localhost` (Docker Compose postgres) |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` or `cloud` branches (SNAPSHOT publish); on push to `release-*` branches (versioned release); all branches run tests

### Pipeline Stages

1. **Checkout**: Shallow clone of source repository
2. **Dependency Track Scan**: Security scan via `security-scan` library
3. **Build** (non-releasable branches): `mvn clean verify` inside Docker CI environment; runs unit and integration tests
4. **Build and Release** (releasable branches `master`, `cloud`, `release-*`): Increments version in `pom.xml`, runs release check, commits version bump, tags release, publishes shaded JAR to Groupon Artifactory
5. **Containerscan Security Scan**: Container image security scan

### Maven Build Profiles

| Profile | Command | Artifact |
|---------|---------|---------|
| `direct-runner` | `mvn clean install -Pdirect-runner` | JAR runnable with DirectRunner (local testing) |
| `spark-runner` | `mvn clean install -Pspark-runner` | Shaded JAR for Spark submission on EMR |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| EMR Cluster | Manual (via Terraform) | `ranking-terraform/envs/prod/account.hcl` — driver: 2 cores / 8 GB; executors: 4 cores / 16 GB each; 10 executors |
| Dynamic Allocation | Disabled | `spark.dynamicAllocation.enabled=false` in `prod.sh` |

## Resource Requirements (Production — `prod.sh`)

| Resource | Driver | Executor |
|----------|--------|---------|
| CPU cores | 2 | 4 per executor |
| Memory | 8 GB | 16 GB per executor |
| Executors | — | 10 |

## Resource Requirements (Development — `development.sh`)

| Resource | Driver | Executor |
|----------|--------|---------|
| CPU cores | 2 | 4 per executor |
| Memory | 4 GB | 4 GB per executor |
| Executors | — | 2 |

## Deployment Procedure

Full deployment steps are documented in the Confluence release process:
- Release process: `https://groupondev.atlassian.net/wiki/spaces/SR/pages/80340385918/DS+Ranking+-+Cloud+Release+Process#2.-deal-performance-data-pipelines`
- Runbook for Cloud: `https://groupondev.atlassian.net/wiki/spaces/SR/pages/80346546951/DPS+-+Runbook+for+Cloud`

To increase capacity: modify EMR cluster configuration in `https://github.groupondev.com/relevance/ranking-terraform/blob/main/envs/prod/account.hcl`.

---
service: "AudienceCalculationSpark"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "YARN"
environments: ["production", "staging", "uat", "alpha"]
---

# Deployment

## Overview

AudienceCalculationSpark is deployed as a fat JAR (assembly JAR) on a YARN-based Hadoop cluster (CerebroV2). It is not containerised with Docker. The JAR is published to Groupon Nexus Artifactory and then copied to a dedicated submitter host (`cerebro-audience-job-submitter1.snc1` for NA, `cerebro-audience-job-submitter2.snc1` for EMEA) by the `deploy.sh` script. A version-agnostic symlink `AudienceCalculationSpark-assembly-current.jar` is created at the deployment target, which AMS uses to launch all Spark jobs.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Fat JAR — no Docker container |
| Orchestration | YARN (CerebroV2) | Jobs submitted via `spark-submit` in `--deploy-mode cluster` on YARN |
| Submitter hosts | Bash / SSH | `cerebro-audience-job-submitter1.snc1` (NA), `cerebro-audience-job-submitter2.snc1` (EMEA) |
| Artifact store | Nexus Artifactory | `https://artifactory.groupondev.com/artifactory/snapshots` or `/releases` |
| YARN Resource Manager | CerebroV2 | `http://cerebro-resourcemanager-vip.snc1:8088/cluster/apps` |

## Environments

| Environment | Purpose | Region | Notes |
|-------------|---------|--------|-------|
| production | Live audience jobs serving real campaigns | NA, EMEA | NA: `cerebro-audience-job-submitter1.snc1`; EMEA: `cerebro-audience-job-submitter2.snc1` |
| staging | Pre-production validation | NA, EMEA | Uses staging AMS host |
| uat | User acceptance testing | NA, EMEA | AMS at `audience-app1-uat.snc1:9000` (NA), `audience-emea-app1-uat.snc1:9000` (EMEA) |
| alpha | Early feature testing | NA | Uses same submitter infrastructure |

## CI/CD Pipeline

- **Tool**: Internal CI (`.ci.yml`)
- **Config**: `.ci.yml`
- **Trigger**: On commit to any branch

### Pipeline Stages

1. **Environment setup**: Sets `HADOOP_USER_NAME=audiencedeploy`, Java 1.8.0_20
2. **Build and test**: `sbt clean compile test` — compiles all Scala source and runs unit tests

### Manual Deployment Steps

1. Publish JAR to Nexus: `sbt publish` (or `sbt universal:publish`)
2. Run deploy script: `./deploy.sh <stage> <realm> <jartype> <version>`
   - `stage`: `production` | `staging` | `uat` | `alpha`
   - `realm`: `na` | `emea`
   - `jartype`: `snapshot` | `release`
   - `version`: e.g. `4.35.25`
3. `deploy.sh` downloads the JAR from Nexus, SCPs it to the submitter host, and creates the `AudienceCalculationSpark-assembly-current.jar` symlink
4. All subsequent AMS-triggered `spark-submit` calls use the symlinked JAR

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Executors | Fixed (manual) | `--num-executors 25` per job (default production) |
| Executor cores | Fixed (manual) | `--executor-cores 4` per job (100 vcores total per job) |
| Executor memory | Fixed (manual) | `--executor-memory 20G` per job |
| Driver memory | Fixed (manual) | `--driver-memory 8G` per job |
| YARN queue capacity | Manual (Data Systems team) | NA: `audience` queue — 1400 vcores; EMEA: `audience_emea` — 1000 vcores |
| Max concurrent jobs | Derived | NA: 1400 / 100 = 14 jobs; EMEA: 1000 / 100 = 10 jobs |

> To add capacity, contact the Data Systems team to add vcores to the private YARN queues. Per-job vcore counts are configurable from AMS config.

## Resource Requirements

| Resource | Per Job | Notes |
|----------|---------|-------|
| CPU (vcores) | 100 (4 cores × 25 executors) | Configurable per-job from AMS |
| Memory (executor) | 20G per executor | Fixed at `spark-submit` time |
| Memory (driver) | 8G | Fixed at `spark-submit` time |
| Disk | HDFS-based | No local disk requirements beyond Spark shuffle |

## Deployment History

A deployment history file is maintained on the submitter host at `<BASE_DIR>/SparkDeploymentHistory.log`, recording timestamp, deployer, jar type, version, and JAR name for each deployment.

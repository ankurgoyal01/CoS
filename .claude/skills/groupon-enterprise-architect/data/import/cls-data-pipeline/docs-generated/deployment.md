---
service: "cls-data-pipeline"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: ["staging", "production"]
---

# Deployment

## Overview

The CLS Data Pipeline is deployed as a set of long-running Spark Streaming jobs and on-demand Spark batch jobs on the Cerebro YARN cluster at Groupon's SNC1 data center. Jobs are not containerized (no Docker); they run as YARN applications submitted via `spark-submit` on Cerebro job submitter hosts. Deployment is entirely manual: the engineer builds a fat assembly JAR, uploads it to the target host via SCP, and launches or restarts each of the six streaming pipelines individually using the appropriate shell script or spark-submit command.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile; fat JAR deployed via SCP |
| Orchestration | YARN (Cerebro cluster) | `--master yarn --deploy-mode cluster` in production |
| Compute queue | YARN queue `cls_realtime` | `--queue cls_realtime` in all production spark-submit commands |
| Spark runtime | Apache Spark 2.4.0 | Installed at `/var/groupon/spark-2.4.0` on Cerebro nodes |
| Job submitter host | `cerebro-job-submitter[1-n].snc1` | SSH target for job management as `svc_cls` |
| YARN Resource Manager | Cerebro | `http://cerebro-resourcemanager2.snc1:8088/cluster/apps` |
| Load balancer | None | Jobs are not HTTP services |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live consumer location event ingestion | US (SNC1) + EMEA (DUB1 via input brokers) | `http://cerebro-resourcemanager-vip.snc1:8088/cluster/apps` |
| Staging | Pre-production validation with staging DB and test Kafka group IDs | SNC1 | Same Cerebro cluster; `--deploy-mode client`, `--db cls_staging` |

## CI/CD Pipeline

- **Tool**: Manual (no CI/CD automation for deployment)
- **Config**: Not applicable
- **Trigger**: Manual — engineer initiates build and deployment following the release process

### Pipeline Stages

1. **Build**: Run `sbt clean assembly` to produce `target/scala-2.11/cls-data-pipeline-2.11-<version>-assembly.jar`
2. **Publish to Nexus**: Run `sbt release` to upload versioned release JAR to `http://nexus-dev/content/repositories/releases/`; or `sbt deploy` for a snapshot/development version
3. **Upload JAR to Cerebro**: SCP the assembly JAR to `svc_cls@cerebro-job-submitter[1-n].snc1:/home/svc_cls/kafka-pipeline-job/cls-data-pipeline-assembly-<version>.jar`
4. **Stop running job**: SSH to Cerebro job submitter; run `yarn application -kill <app_id>` to stop the currently running streaming job
5. **Start new job**: Execute the appropriate spark-submit command (or corresponding shell script, e.g., `sh start_pts_na.sh`) for each of the six pipelines
6. **Verify**: Check Cerebro YARN dashboard at `http://cerebro-resourcemanager2.snc1:8088/proxy/<application_id>/` to confirm jobs are in `RUNNING` state

### Pre-Release Requirements

- Feature branch created and pull request raised
- Build successful on branch
- Manual UAT/staging validation with staging parameters
- Code review by another CLS team member
- Logbook ticket created and change permission obtained via `https://cat.groupondev.com/generic_client`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (executors) | Dynamic allocation (YARN) | `--conf spark.dynamicAllocation.enabled=true --conf spark.dynamicAllocation.minExecutors=3 --conf spark.dynamicAllocation.maxExecutors=3` |
| Executor memory | Fixed per job | `--executor-memory 10g` |
| Driver memory | Fixed per job | `--driver-memory 12g` |
| Executor cores | Fixed per job | `--executor-cores 2` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Executor memory | 10 GB | 10 GB |
| Driver memory | 12 GB | 12 GB |
| Executor cores | 2 | 2 |
| Min executors | 3 | — |
| Max executors | 3 | — |
| Kafka output partitions | 80 (`--numOfpartitions 80`) | — |

## Rollback

Rollbacks are manual. The procedure is:

1. Stop the current YARN application: `yarn application -kill <app_id>`
2. SCP the previous version JAR to the Cerebro job submitter
3. Restart the streaming job(s) using the previous JAR path in the spark-submit command

No automated rollback mechanism exists.

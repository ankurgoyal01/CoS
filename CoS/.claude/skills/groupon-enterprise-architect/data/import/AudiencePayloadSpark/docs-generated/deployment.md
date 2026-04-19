---
service: "AudiencePayloadSpark"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: ["staging-na", "staging-emea", "uat-na", "uat-emea", "production-na", "production-emea", "productionCloud-na", "productionCloud-emea"]
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Deployment

## Overview

AudiencePayloadSpark is deployed as a fat JAR (`AudiencePayloadSpark-assembly-<version>.jar`) to `cerebro-audience-job-submitter` hosts and submitted to a YARN cluster via `spark-submit`. There is no Docker container or Kubernetes orchestration. Deployment is handled by Python Fabric scripts (`fabfile.py`) run by the `audiencedeploy` user. Separate deployment directories exist for each stage and region.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Fat JAR deployed to host filesystem |
| Orchestration | Apache YARN | Jobs submitted to `cerebro-namenode` YARN cluster via `spark-submit` |
| Job submitter hosts | Production: `cerebro-audience-job-submitter1.snc1` | Staging/UAT: `cerebro-audience-job-submitter3.snc1` |
| HDFS | `hdfs://cerebro-namenode/user/audiencedeploy/payload/` | Intermediate Hive tables and job staging |
| Resource Manager UI | `http://cerebro-resourcemanager1.snc1:8088/cluster/apps` | Job status monitoring |
| Artifact repository | Artifactory at `https://artifactory.groupondev.com/` | Publishes and resolves the fat JAR |
| Load balancer | None | Not applicable — batch jobs |

## Environments

| Environment | Purpose | Region | Submitter Host |
|-------------|---------|--------|---------------|
| `staging-na` | Staging — North America | NA (SNC3) | `cerebro-audience-job-submitter3.snc1` |
| `staging-emea` | Staging — EMEA | EMEA | `cerebro-audience-job-submitter3.snc1` |
| `stagingCloud-na` | Staging Cloud — NA | NA | `cerebro-audience-job-submitter3.snc1` |
| `stagingCloud-emea` | Staging Cloud — EMEA | EMEA | `cerebro-audience-job-submitter3.snc1` |
| `uat-na` | UAT — NA | NA | `cerebro-audience-job-submitter3.snc1` |
| `uat-emea` | UAT — EMEA | EMEA | `cerebro-audience-job-submitter3.snc1` |
| `production-na` | Production — NA | NA (SNC1) | `cerebro-audience-job-submitter1.snc1` |
| `production-emea` | Production — EMEA | EMEA | `cerebro-audience-job-submitter1.snc1` |
| `productionCloud-na` | Production Cloud — NA | NA | `cerebro-audience-job-submitter1.snc1` |
| `productionCloud-emea` | Production Cloud — EMEA | EMEA | `cerebro-audience-job-submitter1.snc1` |

## CI/CD Pipeline

- **Tool**: Internal CI (`.ci.yml` — Groupon CI platform)
- **Config**: `.ci.yml`
- **Trigger**: On push (compile + test); releases published manually via `sbt universal:publish`

### Pipeline Stages

1. **Build**: `export HADOOP_USER_NAME=audiencedeploy && export SPARK_LOCAL_IP='127.0.0.1' && sbt clean compile test`
2. **Publish**: `sbt universal:publish` — pushes snapshot to `https://artifactory.groupondev.com/artifactory/snapshots`; releases to `https://artifactory.groupondev.com/artifactory/releases`

### Deployment Steps (Fabric)

1. Build fat JAR locally: `sbt clean assembly`
2. Deploy to submitter host for target stage/region:
   ```
   fab <stage>:<region> deploy
   ```
   This copies `target/scala-2.12/*.jar` and Python scripts to `/home/audiencedeploy/<stage_dir>/payload/<region>/` on the target host and creates a symlink `AudiencePayloadSpark-assembly-current.jar`

### Job Submission Example (CA attributes cron — production NA)

```
36 21 * * * /home/audiencedeploy/ams_uat/payload/na/submit_consumer_attributes.py uat na users \
  >> /home/audiencedeploy/ams_uat/payload/submit_consumer_attributes.log
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Dynamic allocation via YARN | `spark.dynamicAllocation.executorIdleTimeout: 300s` |
| Cassandra write rate (NA) | Throughput cap | `spark.cassandra.output.throughput_mb_per_sec: 0.04` MB/s |
| Cassandra write rate (EMEA) | Concurrent writes | `spark.cassandra.output.concurrent.writes: 50` |
| Spark driver memory (CA jobs) | Fixed | `spark.driver.memory: 16g` |
| Spark driver result size (PA agg) | Fixed | `spark.driver.maxResultSize: 3g` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Spark driver memory (CA jobs) | 16 GB | 16 GB |
| Spark driver max result size (PA agg) | 3 GB | 3 GB |
| Spark driver max result size (CA jobs) | 8 GB | 8 GB |
| CPU / Executors | Managed by YARN dynamic allocation | — |

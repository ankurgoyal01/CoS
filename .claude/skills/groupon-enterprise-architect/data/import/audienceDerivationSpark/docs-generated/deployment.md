---
service: "audienceDerivationSpark"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: [production, staging, uat, productionCloud, uatCloud, stagingCloud]
---

# Deployment

## Overview

Audience Derivation Spark is not containerized. It is deployed as an SBT assembly FAT JAR (`AudienceDerivationSpark-assembly-*.jar`) to a dedicated job submitter host (`cerebro-audience-job-submitter1.snc1` for production) and executed via `spark-submit` on a YARN-managed Hadoop cluster. Deployment is managed manually using Fabric tasks (`fabfile.py`). Scheduling is handled by crontab entries on the job submitter host. There is no Kubernetes, ECS, or Docker infrastructure.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker/container packaging; plain FAT JAR |
| Orchestration | Apache YARN | `--master yarn --deploy-mode cluster`; YARN Resource Manager at `cerebro-resourcemanager-vip.snc1:8088` |
| Build artifact | SBT assembly JAR | `target/scala-2.12/AudienceDerivationSpark-assembly-*.jar` |
| JAR symlink | `AudienceDerivationSpark-assembly-current.jar` | Symlinked on job submitter host for cron execution |
| Load balancer | None | Batch-only; no inbound traffic |
| CDN | None | Not applicable |
| Logging | Splunk (Log4j / Filebeat) | Log path: `/var/groupon/log/gdoop/audiencederivation-Main.log` on Cerebro nodes |

## Environments

| Environment | Purpose | Region | Job Submitter Host |
|-------------|---------|--------|--------------------|
| `production` | Live production audience derivation | na, emea | `cerebro-audience-job-submitter1.snc1` |
| `staging` | Staging environment derivation | na, emea | `cerebro-audience-job-submitter3.snc1` |
| `uat` | User acceptance testing | na, emea | `cerebro-audience-job-submitter3.snc1` |
| `productionCloud` | Cloud-target production derivation | na, emea | `cerebro-audience-job-submitter1.snc1` |
| `uatCloud` | Cloud-target UAT derivation | na, emea | `cerebro-audience-job-submitter3.snc1` |
| `stagingCloud` | Cloud-target staging derivation | na, emea | `cerebro-audience-job-submitter3.snc1` |

## CI/CD Pipeline

- **Tool**: CI build runs via `.ci.yml` (Groupon internal CI)
- **Config**: `.ci.yml` — runs `sbt clean compile test`
- **Trigger**: On commit / push
- **Artifact publishing**: `sbt assembly` produces FAT JAR; `sbt universal:publish` publishes to Nexus (snapshots: `http://nexus-dev/content/repositories/snapshots/com/groupon/audiencemanagement/`, releases: `http://nexus-dev/content/repositories/releases/com/groupon/audiencemanagement/`)

### Pipeline Stages

1. **Compile + Test**: `sbt clean compile test` — compiles Scala sources and runs unit tests (via CI)
2. **Assembly**: `sbt clean assembly` — produces assembly JAR (run locally before Fabric deploy)
3. **Deploy**: `fab {stage}:{region} deploy` — SSHs to job submitter host, uploads JAR and Python scripts, uploads YAML config dirs to HDFS via `hdfs dfs -put`
4. **Kickoff**: `fab {stage}:{region} kickoff:{job}` (manual) or crontab-scheduled `submit_derivation.py` — submits Spark job to YARN

### Crontab Schedule (Production)

| Time (UTC) | Command | Job |
|-----------|---------|-----|
| 10:14 daily | `submit_derivation.py --stage production --region na --job bcookie` | NA bcookie |
| 10:15 daily | `submit_derivation.py --stage production --region na --job users` | NA users |
| 19:01 daily | `submit_derivation.py --stage production --region emea --job bcookie` | EMEA bcookie |
| 19:02 daily | `submit_derivation.py --stage production --region emea --job users` | EMEA users |

Cron logs written to: `/home/audiencedeploy/ams/derivation/derivation_cron.log`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Executor count | Dynamic allocation (YARN) | Min: 5, Max: 10 executors per job |
| Executor memory | Fixed per spark-submit | 5 GB per executor |
| Driver memory | Fixed per spark-submit | 5 GB |
| Executor cores | Fixed per spark-submit | 4 cores per executor |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Executor memory | 5 GB | 5 GB |
| Driver memory | 5 GB | 5 GB |
| Executor cores | 4 | 4 |
| YARN queue | `audience` (NA) / `audience_emea` (EMEA) | Shared YARN queue capacity |

> Disk requirements are managed by HDFS and Hive; no local disk sizing is configured in submit scripts beyond the JAR itself.

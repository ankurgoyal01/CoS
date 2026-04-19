---
service: "campaign-performance-spark"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: ["development", "staging", "production"]
---

# Deployment

## Overview

Campaign Performance Spark is deployed as a fat JAR submitted to a YARN cluster (Cerebro) using `spark-submit` in cluster mode. There is no Docker/Kubernetes orchestration for the Spark job itself; deployment is handled via Capistrano (`cap`) and orchestrated through Deploybot. The JAR is built by Jenkins CI (`jtierPipeline`) and published to Artifactory/Nexus. Two on-prem environments (staging on Cerebro SNC1, production on Cerebro SNC1) and corresponding GCP environments (GCP stable, GCP prod) are supported. A cron-based auto-restart mechanism monitors job liveness every 10 minutes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (build only) | `.ci/Dockerfile` uses `dev-java8-maven:2019-07-09` image for CI builds; no runtime container |
| Orchestration | YARN (Cerebro cluster) | `spark-submit --master yarn --deploy-mode cluster --queue campaign_performance` |
| Job submitter host | Cerebro job submitter | `cerebro-job-submitter[1-2].snc1` (on-prem); deployment dir: `/home/svc_pmp/campaign-performance-spark-deploy/current/` |
| Build artifact | Fat JAR (jar-with-dependencies) | Built by Maven `maven-assembly-plugin`; published to Artifactory at `https://artifactory.groupondev.com/artifactory/releases` |
| Config delivery | Files alongside JAR | `conf/<env>.conf`, `secrets-<env>.conf`, and `logging/elk/log4j.properties` deployed with the JAR |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | Local / Staging Kafka | `local[2]` Spark master |
| staging | Integration testing and pre-production validation | SNC1 (on-prem) / GCP stable | YARN on Cerebro staging |
| production | Live production processing | SNC1 (on-prem) / GCP prod | YARN on Cerebro production |

## CI/CD Pipeline

- **Tool**: Jenkins (via `jtierPipeline` shared library) + Deploybot
- **Config**: `Jenkinsfile` (`@Library("java-pipeline-dsl@latest-2") _`, `jtierPipeline([skipDocker: true, deployTarget: 'dummy_uat', slackChannel: 'CF9N0NXJS'])`)
- **Trigger**: On every merge to `master` (CI build + Deploybot UAT entry); manual promotion to staging and production via Deploybot

### Pipeline Stages

1. **CI Build**: Jenkins builds the fat JAR using Maven (`mvn clean package`), runs unit tests, publishes to Artifactory/Nexus
2. **UAT Entry**: `dummy_uat` Deploybot target is created automatically on every `master` merge (no deployment; used as a promotion source)
3. **Staging Deploy**: Manual promotion from UAT in Deploybot triggers `cap snc1:staging deploy:app_servers VERSION=<version> TYPE=release`
4. **Production Deploy**: Manual promotion from staging in Deploybot (requires GPROD ticket and Prodcat/SOC approval) triggers `cap snc1:production deploy:app_servers VERSION=<version> TYPE=release`
5. **Tag-based Deploy**: Production re-deployments can also be triggered by pushing a git tag with pattern `production_snc1-v<version>#GPROD-<ticket>`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Executors | Static (dynamic allocation disabled) | `--num-executors 14`, `--executor-cores 4`, `--executor-memory 16G` |
| Driver | Fixed | `--driver-cores 4`, `--driver-memory 16G` |
| Kafka parallelism | `minPartitions` config | `minPartitions=200` ensures at least 200 Spark tasks per micro-batch |
| YARN queue capacity | Manual capacity request to GDoop team | `campaign_performance` queue; 100+ dedicated cores as of initial setup |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Executor memory | 16 GB per executor | 16 GB |
| Executor CPU | 4 cores per executor | 4 cores |
| Driver memory | 16 GB | 16 GB |
| Driver CPU | 4 cores | 4 cores |
| Executor count | 14 (static) | 14 |

## Operational Scripts

The following scripts are deployed to the job submitter host under `current/run/`:

| Script | Purpose |
|--------|---------|
| `runCampaignPerformanceStreamingJob [staging|production]` | Submits the Spark job to YARN via `spark-submit` |
| `stopCampaignPerformanceStreamingJob [staging|production]` | Gracefully stops the job by removing the HDFS status marker file |
| `forceStopCampaignPerformanceStreamingJob [staging|production]` | Force-kills the YARN application |
| `cleanCache <path> <age-days> ...` | Removes aged-out dedup cache files from HDFS/GCS |

## Cron Jobs (Production)

Deployed manually to `cerebro-job-submitter2.snc1`:

| Schedule | Command | Purpose |
|----------|---------|---------|
| `* * * * *` (every minute) | `KafkaLagChecker metricLag` | Compute and emit per-partition Kafka lag to Telegraf |
| `45 1 * * *` (01:45 daily) | `cleanCache /user/grp_gdoop_pmp/campaign-perf-spark-outs/dedup_cache 30 false true` | Remove dedup cache files older than 30 days |
| `2 2 * * *` (02:02 daily) | `find /home/svc_pmp/cronlog -mtime +7 -exec rm {} \;` | Rotate cron log files older than 7 days |

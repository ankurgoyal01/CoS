---
service: "consumer-authority"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "yarn"
environments: [production]
---

# Deployment

## Overview

Consumer Authority is a Spark batch application submitted to a YARN-managed Hadoop cluster via Cerebro Job Submitter. It is not containerized in the Docker/Kubernetes sense. Airflow owns the scheduling layer; Cerebro Job Submitter owns the job submission layer; the Hadoop/YARN cluster owns compute execution. There is no persistent long-running process — the service starts, executes a run, and terminates.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Not containerized; deployed as a compiled Scala fat-JAR (SBT assembly) |
| Orchestration | YARN (Hadoop cluster) | Spark jobs submitted via `spark-submit` through Cerebro Job Submitter |
| Scheduler | Airflow | Defines daily DAG schedules and backfill run triggers |
| Job submission | Cerebro Job Submitter | Translates Airflow task execution into `spark-submit` invocations on the YARN cluster |
| Storage | HDFS + Hive | Output written to Hive-managed HDFS paths |
| Load balancer | None | Not applicable — batch pipeline with no inbound network traffic |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live daily attribute computation across NA, INTL, and GBL regions | Groupon data center | Not applicable (no HTTP surface) |

> Additional environment details (staging, dev) are not visible in the architecture model. Contact the service owner for environment-specific cluster endpoints.

## CI/CD Pipeline

- **Tool**: > No evidence found — CI/CD pipeline configuration is not visible in the architecture model
- **Config**: `build.sbt` (SBT assembly produces the deployable fat-JAR)
- **Trigger**: Airflow DAG schedule (daily) or manual Airflow backfill trigger

### Pipeline Stages

1. **Build**: SBT compiles Scala sources and assembles fat-JAR with `sbt assembly`
2. **Deploy**: Assembled JAR is deployed to the cluster artifact store accessible by Cerebro Job Submitter
3. **Schedule**: Airflow DAG triggers `cdeJobOrchestrator` via Cerebro Job Submitter on the defined cron
4. **Execute**: Spark job runs on YARN, processes data, writes output, publishes events
5. **Notify**: `cdeAlertingNotifier` sends success or failure alerts via SMTP relay

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | YARN dynamic resource allocation | Executor count determined by Spark configuration and cluster availability |
| Memory | Spark executor memory | > No evidence found — set in spark-defaults.conf or Cerebro job definition |
| CPU | Spark executor cores | > No evidence found — set in spark-defaults.conf or Cerebro job definition |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > No evidence found | > No evidence found |

> Deployment configuration for resource sizing is managed externally via Cerebro job definitions and cluster YARN configuration. Contact the service owner for current production resource allocations.

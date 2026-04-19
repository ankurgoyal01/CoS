---
service: "user-behavior-collector"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [production-na, production-emea, staging-na, staging-emea]
---

# Deployment

## Overview

User Behavior Collector is deployed as a fat JAR (uber-JAR produced by `maven-shade-plugin`) onto bare-metal/VM hosts in Groupon's SNC1 data center. It is not containerized. Deployment is managed via Capistrano (`uber_deploy` gem); packages are sourced from Groupon's internal Nexus repository. The job is triggered exclusively by cron on the target host — there is no persistent daemon process. Spark jobs are submitted from the host to the gdoop YARN cluster.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Fat JAR (`user-behavior-collector-jar-with-dependencies.jar`); no Docker image |
| Orchestration | VM / Cron | Scheduled via system cron at `/etc/cron.d/user-behavior-collector` on each host |
| Load balancer | None | Batch job; no inbound traffic |
| CDN | None | Not applicable |
| Spark cluster | YARN (gdoop) | Spark master set to `yarn`; job submitted from host to `gdoop_host` |

## Environments

| Environment | Purpose | Region | Host |
|-------------|---------|--------|------|
| production-na | NA production batch processing | NA (SNC1) | `emerging-channels-utility3.snc1` |
| production-emea | EMEA production batch processing | EMEA (SNC1) | `emerging-channels-emea4.snc1` |
| staging-na | NA staging/test runs | NA (SNC1) | `targeted-deal-message-app1-staging.snc1` |
| staging-emea | EMEA staging/test runs | EMEA (SNC1) | `emerging-channels-emea1.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (Jenkinsfile) + Capistrano (Gemfile: `uber_deploy ~> 3.1`, `capistrano 2.15.5`)
- **Config**: `Jenkinsfile` (SonarQube analysis only), `Capfile`, `Gemfile`
- **Trigger**: Manual or branch push; SonarQube analysis runs on every build

### Pipeline Stages

1. **Build**: `mvn clean` (CI), `mvn install && mvn clean compile assembly:single` (local snapshot), or `mvn clean release:clean release:prepare && mvn release:perform` (release)
2. **SonarQube Analysis**: `sonar-scanner` run via `Jenkinsfile` using `java-pipeline-dsl@latest-2` shared library
3. **Publish to Nexus**: Release artifacts uploaded to `https://artifactory.groupondev.com/artifactory/releases`
4. **Deploy via Capistrano**: `cap <environment> deploy VERSION=<version> TYPE=release`; Capistrano fetches JAR from Nexus at `http://nexus-dev.snc1/content/repositories/releases/com/groupon/utility/user-behavior-collector/` and deploys to target host

### Deploy Commands

```
# Deploy to NA staging from local snapshot
cap staging deploy WARPATH=target/user-behavior-collector-<version>-SNAPSHOT-jar-with-dependencies.jar

# Deploy to NA production from Nexus
cap production deploy VERSION=<version> TYPE=release

# Deploy to EMEA production from Nexus
cap production_emea deploy VERSION=<version> TYPE=release
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable (single cron job per region) | One NA host, one EMEA host |
| Memory | JVM heap fixed per run | `-Xmx12000m` (12 GB) |
| CPU | Spark YARN cluster handles Spark parallelism | `maxFiles` CLI arg limits files per run |
| File processing | Bounded per run | CLI `--maxFiles` arg; default cap of 10,000 files |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Memory (JVM) | 12 GB (`-Xmx12000m`) | 12 GB |
| CPU | No evidence found in codebase | No evidence found in codebase |
| Disk | Log files at `/var/groupon/log/user-behavior-collector/` | No evidence found in codebase |

> Spark executor resource configuration is managed on the gdoop YARN cluster and not defined in this repository.

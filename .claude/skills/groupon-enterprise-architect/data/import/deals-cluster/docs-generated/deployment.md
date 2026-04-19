---
service: "deals-cluster"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: ["staging", "production"]
---

# Deployment

## Overview

Deals Cluster is deployed as a fat JAR (produced by the Maven Shade plugin) onto the **Cerebro job submitter hosts** (`svc_mars_mds` user home directory at `/home/svc_mars_mds/deals-cluster/current/`). The JAR is submitted to the **Cerebro YARN cluster** for distributed Spark execution. There is no Docker containerization for the Spark job itself. Deployment is performed via **Capistrano** (`cap` command) pulling from Nexus. Job scheduling is managed via **crontab** on the Cerebro job submitter hosts.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Fat JAR packaged by `maven-shade-plugin`; no Docker |
| Orchestration | Cerebro YARN | Apache Spark on YARN; Cerebro is Groupon's on-premises Hadoop cluster |
| Job scheduler | crontab | Crontab installed on Cerebro job submitter; runs both jobs once per day |
| Deployment tool | Capistrano | `cap snc1:staging deploy:util_servers` / `cap snc1:production deploy:util_servers` |
| Artifact repository | Nexus (Artifactory) | `https://artifactory.groupondev.com/artifactory/releases` |
| Build image | `docker.groupondev.com/jtier/dev-java8-maven:3` | Used in Jenkins CI only for build isolation |

## Environments

| Environment | Purpose | Region | URL / Host |
|-------------|---------|--------|-----------|
| staging | Integration and UAT testing | snc1 | `cerebro-job-submitter3.snc1` (SSH target); Rules API at `http://deals-cluster-staging.snc1/rules` |
| production | Live deal clustering | snc1 | `cerebro-job-submitter2.snc1` (SSH target); Rules API at `http://deals-cluster-vip.snc1/rules` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root of repo)
- **Trigger**: Pull request creation / push to `main` branch triggers build; release is manual.

### Pipeline Stages

1. **Build**: Runs `mvn clean install` using Docker image `dev-java8-maven:3`; compiles Java source, runs unit tests, generates JaCoCo coverage report, runs PMD static analysis.
2. **Git submodule init**: `exec-maven-plugin` runs `git submodule update --init --recursive` during the `initialize` phase to pull `deals-cluster-secrets`.
3. **Release**: Developer manually runs `mvn clean release:clean release:prepare release:perform` on the `main` branch to publish a release version to Nexus/Artifactory.
4. **Deploy to Staging**: `cap snc1:staging deploy:util_servers VERSION=<release_number> TYPE=release`
5. **Deploy to Production**: `cap snc1:production deploy:util_servers VERSION=<release_number> TYPE=release` — requires G-PROD ticket and Change Execution Approval.

## Deployment Procedure

### Staging

```bash
cap snc1:staging deploy:util_servers VERSION=<release_number> TYPE=release
```

### Production

Pre-conditions:
1. Verify the deployment falls within the [Change Policy](https://wiki.groupondev.com/Change_policy) window.
2. Create a G-PROD ticket in Jira.
3. Submit a Change Execution Approval Request at `https://cat.groupondev.com/generic_client`.

```bash
cap snc1:production deploy:util_servers VERSION=<release_number> TYPE=release
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Controlled by Cerebro YARN resource allocation | Spark executor count configured in Spark session init |
| Memory | Managed by YARN / Spark | Not explicitly configured in this repo; managed at cluster level |
| CPU | Managed by YARN | Not explicitly configured in this repo; managed at cluster level |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are controlled by the Cerebro YARN cluster configuration, not by this repository.

## Job Schedule

Both Spark jobs run **once per day** via crontab on the Cerebro job submitter:

- `DealsClusterJob` runs first; processes all target countries for the current date.
- `TopClustersJob` runs after `DealsClusterJob` completes; reads the HDFS output from the same day.

Crontab files:
- Production: `src/main/resources/run/production/crontab`
- Staging: `src/main/resources/run/staging/crontab`

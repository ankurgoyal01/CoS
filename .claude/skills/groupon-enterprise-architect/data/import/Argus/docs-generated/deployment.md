---
service: "argus"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "jenkins"
environments:
  - production_snc1
  - production_sac1
  - production_dub1
  - production_eu_west_1
  - production_us_west_1
  - staging_snc1
  - emea_staging_snc1
  - staging_us_west_1
  - staging_us_west_2
  - miscellaneous
---

# Deployment

## Overview

Argus is not a long-running service. It is a set of short-lived batch CLI jobs executed inside a Docker container on a Jenkins CI agent. The container is built from source on every qualifying `master` branch commit, and the appropriate Gradle task is executed for each changed alert environment directory. There is no persistent deployment target — Argus runs, syncs Wavefront, and exits.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — builds from `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |
| CI/CD Orchestration | Jenkins | `Jenkinsfile` — declarative pipeline with parallel stages per environment |
| Build tool | Gradle 5.0 | `gradle/wrapper/gradle-wrapper.properties` — `gradle-5.0-all.zip` |
| CI agent | Jenkins node `dind_2gb_2cpu` | Docker-in-Docker, 2 GB RAM, 2 CPU |
| Load balancer | None | Not applicable — Argus is a batch job |
| CDN | None | Not applicable |

## Environments

Argus manages alert configurations for the following Wavefront environments:

| Environment | Purpose | Region |
|-------------|---------|--------|
| `production_snc1` | SNC1 Production alerts | SNC1 (US) |
| `production_sac1` | SAC1 Production alerts | SAC1 (US) |
| `production_dub1` | DUB1 Production alerts | Dublin (EU) |
| `production_eu_west_1` | EU-WEST-1 Production alerts | EU West 1 |
| `production_us_west_1` | US-WEST-1 Production alerts | US West 1 |
| `staging_snc1` | SNC1 Staging alerts | SNC1 (US) |
| `emea_staging_snc1` | EMEA Staging alerts | SNC1 (US, EMEA scope) |
| `staging_us_west_1` | US-WEST-1 Staging alerts | US West 1 |
| `staging_us_west_2` | US-WEST-2 Staging alerts | US West 2 |
| `miscellaneous` | Cross-environment and misc alerts | Various |

## CI/CD Pipeline

- **Tool**: Jenkins (declarative pipeline)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch (changeset-filtered stages); timer trigger for alert summary reporting

### Pipeline Stages

1. **Checkout**: Full Git clone (non-shallow, with tags) via `GitSCM`
2. **Prepare**: Determines if branch is releasable (`GITHUB_BRANCH == "master"`)
3. **BUILD-CONTAINER**: Builds Docker image `jtier-docs-ci` from `.ci/Dockerfile`
4. **ENV-UPDATE-ALERT** (parallel, changeset-gated): Runs the appropriate `updateAlerts*` Gradle task for each environment whose alert files changed:
   - `UPDATE-ALERTS-SNC1-PRODUCTION` — triggers on changes to `src/main/resources/alerts/production_snc1/**/*`
   - `UPDATE-ALERTS-SAC1-PRODUCTION` — triggers on changes to `src/main/resources/alerts/production_sac1/**/*`
   - `UPDATE-ALERTS-DUB1-PRODUCTION` — triggers on changes to `src/main/resources/alerts/production_dub1/**/*`
   - `UPDATE-ALERTS-EU-WEST-1-PRODUCTION` — triggers on changes to `src/main/resources/alerts/production_eu_west_1/**/*`
   - `UPDATE-ALERTS-US-WEST-1-PRODUCTION` — triggers on changes to `src/main/resources/alerts/production_us_west_1/**/*`
   - `UPDATE-ALERTS-MISCELLANEOUS` — triggers on changes to `src/main/resources/alerts/miscellaneous/*`
   - `UPDATE-ALERTS-EMEA-STAGING` — triggers on changes to `src/main/resources/alerts/emea_staging_snc1/*`
   - `UPDATE-ALERTS-SNC1-STAGING` — triggers on changes to `src/main/resources/alerts/staging_snc1/*`
   - `UPDATE-ALERTS-US-WEST-1-STAGING` — triggers on changes to `src/main/resources/alerts/staging_us_west_1/**/*`
   - `UPDATE-ALERTS-US-WEST-2-STAGING` — triggers on changes to `src/main/resources/alerts/staging_us_west_2/**/*`
5. **BUILD-PROJECT**: Runs `./gradlew build` when no alert files changed (validates non-alert code changes)
6. **SHOW-ALERT-SUMMARY**: Runs `./gradlew showAlertSummary` when triggered by a `TimerTrigger` (scheduled run); prints top-firing alerts to CI logs

## Scaling

> Not applicable. Argus is a batch job. Each Gradle task runs sequentially within its Docker container. Jenkins parallel stages allow multiple environment syncs to run concurrently within a single pipeline run, constrained by the 2-CPU CI agent.

## Resource Requirements

| Resource | Value |
|----------|-------|
| CI agent label | `dind_2gb_2cpu` |
| RAM | 2 GB (CI agent specification) |
| CPU | 2 cores (CI agent specification) |
| Disk | Gradle dependency cache + project build artifacts |

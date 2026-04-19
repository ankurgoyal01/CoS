---
service: "HotzoneGenerator"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: ["development", "staging", "production", "production-emea"]
---

# Deployment

## Overview

HotzoneGenerator is deployed as a fat jar (`HotzoneGenerator-<version>-jar-with-dependencies.jar`) onto bare VMs using Capistrano. There is no Docker container or Kubernetes orchestration. The job is invoked by cron on each host; the cron schedule is installed separately using `cap <env> crontab` after a deploy. Artifacts are published to a Nexus repository and deployed either from Nexus (release) or from a local snapshot jar.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Deployed as a fat jar directly on VM |
| Orchestration | VM (Capistrano) | `Capfile` + `cap <env> deploy` commands |
| Load balancer | None | Batch job; no load balancer |
| CDN | None | Not applicable |
| Artifact repository | Nexus | `http://nexus-dev/content/repositories/releases/com/groupon/utility/HotzoneGenerator/` |
| Artifact repository (snapshots) | Artifactory | `https://artifactory.groupondev.com/artifactory/snapshots` |

## Environments

| Environment | Purpose | Region | Host |
|-------------|---------|--------|------|
| staging | Pre-production validation | NA (snc1) | `ec-proximity-app1-staging` |
| production | NA live traffic | NA (snc1) | `mobile-proximity-utility1.snc1` |
| production_emea | EMEA live traffic | EMEA (dub1) | `proximity-indexer-app1.dub1` |

> No UAT environment exists for this service (noted in README.md).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses `@Library("java-pipeline-dsl@latest-2")`)
- **Trigger**: On push / merge (Jenkins pipeline)

### Pipeline Stages

1. **Build**: `mvn clean compile` — compiles source code.
2. **Package**: `mvn install && mvn clean compile assembly:single` — produces fat jar with all dependencies.
3. **Release**: `mvn clean release:clean release:prepare && mvn release:perform && git push && git push --tags` — publishes release artifact to Nexus.
4. **Deploy (staging)**: `cap staging deploy WARPATH=target/HotzoneGenerator-<version>-jar-with-dependencies.jar` (snapshot) or `cap staging deploy VERSION=<v> TYPE=release` (release).
5. **Deploy (production NA)**: `cap production deploy VERSION=<v> TYPE=release`
6. **Deploy (production EMEA)**: `cap production_emea deploy VERSION=<v> TYPE=release`
7. **Crontab install**: `cap production crontab` / `cap production_emea crontab` — installs or restores cron entries after host roll.

## Cron Schedule

| Region | Hotzone generation | Weekly email |
|--------|-------------------|--------------|
| NA | `0 22 * * *` UTC (daily 22:00) | `0 15 * * 5` UTC (Fridays 15:00) |
| EMEA | `0 22 * * *` UTC (daily 22:00) | `0 7 * * 5` UTC (Fridays 07:00) |

The cron runs as `svc_emerging_channel`. The `run_job` script invokes:
```
/usr/local/bin/java -Dcustom.logpath=/var/groupon/log/HotzoneGenerator \
  -jar /var/groupon/HotzoneGenerator/HotzoneGenerator-<version>-jar-with-dependencies.jar \
  <env> config
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Single instance per region (cron on one VM) | Not auto-scaled |
| Memory | Not configured | No evidence found |
| CPU | Not configured | No evidence found |

## Resource Requirements

> Deployment configuration managed externally. No explicit resource limits found in the repository.

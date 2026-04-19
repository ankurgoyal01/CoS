---
service: "amsJavaScheduler"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1]
---

# Deployment

## Overview

AMS Java Scheduler is containerized (Docker) and deployed as a set of Kubernetes CronJobs, one per job-type component (bcookie, sadintegrationcheck, universal, users, usersbatchsad). Each CronJob component runs independently on its own schedule. The primary cloud deployment targets GCP (us-central1 and europe-west1); a legacy AWS eu-west-1 environment for EMEA production is also active. Deployment is managed via DeployBot with Helm chart `cmf-generic-cron-job` version `3.88.1`. The build and release pipeline is driven by Jenkins.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; image published to `docker-conveyor.groupondev.com/crm/ams-java-scheduler` |
| Build image (CI) | Docker | `.ci/Dockerfile` — based on `docker.groupondev.com/jtier/dev-java17-maven:2022-03-22-558dc7f` |
| Orchestration | Kubernetes CronJob | Helm chart `cmf-generic-cron-job` version `3.88.1`; deployed via `deploy.sh` (NA) and `deploy-emea.sh` (EMEA) using `krane` |
| Deployment tool | DeployBot | `https://deploybot.groupondev.com/crm/amsJavaScheduler` |
| Load balancer | None | No inbound traffic; no load balancer required |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | Cluster / Context |
|-------------|---------|--------|-------------------|
| `staging-us-central1` | NA staging | GCP us-central1 | `gcp-stable-us-central1` / `ams-gcp-staging-us-central1` |
| `staging-europe-west1` | EMEA staging | GCP europe-west1 | `gcp-stable-europe-west1` / `ams-gcp-staging-europe-west1` |
| `production-us-central1` | NA production | GCP us-central1 | `gcp-production-us-central1` / `ams-gcp-production-us-central1` |
| `production-eu-west-1` | EMEA production | AWS eu-west-1 | `production-eu-west-1` / `ams-production-eu-west-1` |

Kubernetes namespaces: `ams-staging` (staging) and `ams-production` (production).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (uses shared library `java-pipeline-dsl@latest-2`)
- **Trigger**: Merge to `development` branch triggers build and deployment artifact generation
- **Deploy tool**: DeployBot (`https://deploybot.groupondev.com/crm/amsJavaScheduler`)

### Pipeline Stages

1. **Build**: Maven build (`mvn clean compile install`) on the `development` branch; Docker image built using `dockerfile-maven-plugin`
2. **Test**: Docker Compose CI environment (`.ci/docker-compose.yml`) runs unit tests inside a Java 17 Maven container
3. **Publish**: Docker image tagged and pushed to `docker-conveyor.groupondev.com/crm/ams-java-scheduler`; artifacts published to Artifactory (`https://artifactory.groupondev.com/artifactory/releases`)
4. **Deploy to Staging**: DeployBot task triggers `deploy.sh` (NA) or `deploy-emea.sh` (EMEA), which renders Helm templates for all five CronJob components and applies them via `krane deploy` with a 300-second global timeout
5. **Promote to Production**: After successful staging verification, operator promotes via DeployBot to production environments

## CronJob Components and Schedules

Each component is deployed as an independent Kubernetes CronJob with its own `jobSchedule`:

| Component | Cloud Schedule (production NA) | Cloud Schedule (production EMEA) | `AMS_TYPE` |
|-----------|-------------------------------|----------------------------------|------------|
| `universal` | `0 2 * * *` (02:00 UTC) | varies | `universal` |
| `bcookie` | `0 1 * * *` | varies | `bcookie` |
| `users` | `0 1 * * *` | not deployed (NA only) | `users` |
| `sadintegrationcheck` | `0 21 * * *` | varies | `sadintegrationcheck` |
| `usersbatchsad` | `30 0 * * *` | not deployed (NA only) | `usersbatchsad` |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed parallelism | `parallelism: 1` per CronJob component (no auto-scaling; each job runs one pod at a time) |
| Memory | Request + Limit | 500Mi request / 500Mi limit |
| CPU | Request only | 1000m request (no CPU limit set) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | not set |
| Memory | 500Mi | 500Mi |
| Disk | not specified | not specified |

## Manual Operations

Single ad-hoc job run (without modifying the schedule):
```
kubectl create job --from=cronjob/<ams-cronjob-name> <custom-job-name>
```

Disable a CronJob:
```
kubectl patch cronjobs <cronjob-name> -p '{"spec" : {"suspend" : true }}'
```

Enable a CronJob:
```
kubectl patch cronjobs <cronjob-name> -p '{"spec" : {"suspend" : false }}'
```

Access requires Kubernetes Tools (`kubectl` + `cloud-elevator`) and ARQ access approval for the AMS service.

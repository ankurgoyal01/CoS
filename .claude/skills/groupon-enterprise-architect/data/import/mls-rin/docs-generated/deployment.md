---
service: "mls-rin"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, staging-us-west-2, production-us-central1, production-europe-west1, production-eu-west-1, production-snc1, production-sac1, production-dub1]
---

# Deployment

## Overview

MLS RIN is deployed as a Docker container managed by Kubernetes (via Groupon's Conveyor cloud platform) in GCP and AWS regions. A legacy on-premises deployment also exists across three data centers (SNC1, SAC1, DUB1) using a Capistrano-based JTier deploy pipeline. The cloud deployment is the primary path; on-premises is legacy. CI/CD is driven by a Jenkins JTier pipeline with automatic staging deployments on PR merge and manual promotion to production via DeployBot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base image `docker.groupondev.com/jtier/prod-java17-jtier:2024-04-23-77dca2a`; app image `docker-conveyor.groupondev.com/mx-jtier/mls-rin` |
| Orchestration | Kubernetes (Conveyor) | Manifests in `.meta/deployment/cloud/components/app/`; namespace `mls-rin-staging` / `mls-rin-production` |
| Load balancer | Kubernetes Service | HTTP port 8080 (app), admin port 8081, JMX port 8009 exposed |
| CDN | None documented | Internal service only |
| On-prem deploy | Capistrano / Überdeploy | `Capfile`, `Gemfile`; `cap` command with datacenter:environment targets |

## Environments

| Environment | Purpose | Region / Datacenter | URL / VIP |
|-------------|---------|---------------------|-----------|
| staging-us-central1 | Cloud staging (US) | GCP us-central1 | (internal cloud DNS) |
| staging-europe-west1 | Cloud staging (EU) | GCP europe-west1 | (internal cloud DNS) |
| staging-us-west-2 | Cloud staging (US West) | AWS us-west-2 | (internal cloud DNS) |
| production-us-central1 | Cloud production (US) | GCP us-central1 | (internal cloud DNS) |
| production-europe-west1 | Cloud production (EU) | GCP europe-west1 | (internal cloud DNS) |
| production-eu-west-1 | Cloud production (EU) | AWS eu-west-1 | (internal cloud DNS) |
| production (snc1) | On-prem production (US) | SNC1 | `http://mls-rin-vip.snc1` |
| staging (snc1) | On-prem staging (US) | SNC1 | `http://mls-rin-us-staging-vip.snc1` (US), `http://mls-rin-emea-staging-vip.snc1` (EMEA) |
| production (sac1) | On-prem production (US) | SAC1 | `http://mls-rin-vip.sac1` |
| production (dub1) | On-prem production (EMEA) | DUB1 | `http://mls-rin-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (JTier pipeline DSL `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: On PR merge to `master`; additionally supports `MCE-.*` branches as releasable
- **Staging auto-deploy targets**: `staging-us-central1`, `staging-europe-west1` (via DeployBot)
- **Notifications**: Google Chat space (`#mx-deploy`); Slack channel `#mx-deploy`
- **Submodule handling**: `cloneSubModules: true` (required for secrets submodule)

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles, runs tests, generates Swagger server stubs, produces JAR
2. **Static analysis**: PMD (configured via `pmd-rulesets.xml`) and FindBugs (configured via `findbugs-exclude.xml`)
3. **Docker build**: Builds Docker image from `src/main/docker/Dockerfile`; bundles OTel Java agent
4. **Publish**: Pushes image to `docker-conveyor.groupondev.com/mx-jtier/mls-rin`; releases JAR to Nexus
5. **Auto-deploy staging**: DeployBot triggers Kubernetes deployment to staging environments
6. **Smoke tests**: Built-in Capistrano smoke tests (`src/main/resources/smoke_test/smoke_test.rb`) run post-deploy; auto-rollback on failure
7. **Production promotion**: Manual promotion via DeployBot; requires Prodcat validation (ORR Green, no moratorium, dependency deploy window check)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | Min: 2, Max: 3 replicas |
| Horizontal (production cloud) | Kubernetes HPA | Min: 3, Max: 16 replicas; `hpaTargetUtilization: 100` |
| Horizontal (on-premises) | Manual host provisioning | Capfile-managed host list |
| Memory | JVM heap managed by `MIN_RAM_PERCENTAGE` / `MAX_RAM_PERCENTAGE` | 75% of container memory limit |

## Resource Requirements

| Resource | Request (staging) | Limit (staging) | Request (production) | Limit (production) |
|----------|-------------------|-----------------|----------------------|--------------------|
| CPU | 1000m | 2000m | 1200m (GCP US) / 120m (AWS EU) | 2000m |
| Memory | 4Gi | 8Gi | 4Gi | 8Gi |
| Disk | Managed by Filebeat volume (`low` staging, `medium` production) | | | |

## Health Probes

| Probe | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|-------|------|------|--------------|--------|---------|-------------------|
| Readiness | `/grpn/healthcheck` | 8080 | 40s | 20s | 15s | 5 |
| Liveness | `/ping` | 8080 | 60s | 15s | 5s | 5 |

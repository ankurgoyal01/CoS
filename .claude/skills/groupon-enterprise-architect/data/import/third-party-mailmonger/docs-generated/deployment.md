---
service: "third-party-mailmonger"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-1, staging-us-central1, production-us-west-1, production-us-central1, production-eu-west-1, production-snc1, production-sac1, production-dub1]
---

# Deployment

## Overview

Third Party Mailmonger runs as a containerized Java 11 service on two platforms: a cloud Kubernetes deployment (AWS, managed via DeployBot and JTier cloud tooling) and a legacy on-premises Capistrano deployment (SNC1, SAC1, DUB1 colos). The Docker image is built from `src/main/docker/Dockerfile` using the JTier `prod-java11-jtier:3` base image. Cloud deployments are defined in `.meta/deployment/cloud/` and follow the standard JTier cloud deployment pattern.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `src/main/docker/Dockerfile` — base `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| CI build image | Docker | `.ci/Dockerfile` — base `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` |
| Orchestration | Kubernetes (cloud) | Manifests in `.meta/deployment/cloud/components/app/` |
| Image registry | JFrog Artifactory | `docker-conveyor.groupondev.com/engage/third-party-mailmonger` |
| On-prem deployment | Capistrano | `Capfile`, `Gemfile`; `bundle exec cap <colo>:<env> deploy:app_servers` |
| Load balancer | VIP (on-prem) | `http://mailmonger-vip.snc1`, `http://mailmonger-vip.sac1`, `http://mailmonger-vip.dub1` |
| CDN | None | Internal service; no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-west-1 | Cloud staging | AWS us-west-1 | Internal Kubernetes service |
| staging-us-central1 | Cloud staging | AWS us-central1 | Internal Kubernetes service |
| production-us-west-1 | Cloud production | AWS us-west-1 | Internal Kubernetes service |
| production-us-central1 | Cloud production | AWS us-central1 | Internal Kubernetes service |
| production-eu-west-1 | Cloud production (EU) | AWS eu-west-1 | Internal Kubernetes service |
| Production (SNC1) | On-prem production | US (SNC1) | `http://mailmonger-vip.snc1` |
| Production (SAC1) | On-prem production | US (SAC1) | `http://mailmonger-vip.sac1` |
| Production (DUB1) | On-prem production (EU) | EU (DUB1) | `http://mailmonger-vip.dub1` |
| Staging (SNC1) | On-prem staging | US (SNC1) | `http://mailmonger-app-staging-vip.snc1` |
| UAT (SNC1) | On-prem UAT | US (SNC1) | Internal VIP |

## CI/CD Pipeline

### Cloud deployment

- **Tool**: Jenkins (cloud-jenkins.groupondev.com) + DeployBot
- **Config**: `Jenkinsfile`
- **Trigger**: Automatic on every merged PR (`mvn deploy` to JFrog Artifactory)

#### Pipeline Stages (Cloud)

1. **Build**: `mvn clean package deploy` — compiles, tests (JUnit, Mockito), packages, and publishes artifact to Artifactory
2. **Staging tag**: DeployBot creates a `staging-us-west-1` tag automatically
3. **Authorize staging**: Engineer authorizes staging deployment via DeployBot UI
4. **Promote to production**: Engineer clicks Promote in DeployBot to advance from `staging-us-west-1` to `production-us-west-1`
5. **GPROD change ticket**: Required for production promotions

### On-premises deployment

- **Tool**: Capistrano (via `bundle exec cap`)
- **Config**: `Capfile`, `Gemfile`
- **Trigger**: Manual; requires Logbook ticket and sudo permissions on target hosts

#### Pipeline Stages (On-Prem)

1. **Release branch**: `git checkout -b release; mvn release:clean release:prepare release:perform`
2. **Canary deploy**: `bundle exec cap snc1:production1 deploy:app_servers VERSION=<v> TYPE=release TICKET=GPROD-<n>`
3. **Validate**: Check Splunk `sourcetype=mailmonger`, review dashboards
4. **Full deploy**: `bundle exec cap snc1:productionN deploy:app_servers ...`; then SAC1, then DUB1
5. **Smoke test**: Send a test email end-to-end; verify delivery and status in database

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (cloud staging) | Kubernetes HPA | min 1, max 2, target CPU 100% |
| Horizontal (cloud production) | Kubernetes HPA | min 2, max 25, target CPU 100% |
| Horizontal (common default) | Kubernetes HPA | min 3, max 15, target CPU 100% |
| Memory | Kubernetes limits | Request 3 Gi, limit 5 Gi (main container) |
| CPU | Kubernetes limits | Request 300m (main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not explicitly set (inherits node limit) |
| Memory | 3 Gi | 5 Gi |
| Disk | Not specified | Not specified |

## Rollback

### Cloud rollback

Use the DeployBot UI: click **Retry** on the last stable deployment, or click **Rollback** on the failed deployment entry.

### On-prem rollback

```
bundle exec cap snc1:production1 rollback
bundle exec cap snc1:productionN rollback
```

Repeat for SAC1 and DUB1 as needed.

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application (mapped to Kubernetes service port 80) |
| 8081 | Dropwizard admin port |
| 8009 | JMX port |

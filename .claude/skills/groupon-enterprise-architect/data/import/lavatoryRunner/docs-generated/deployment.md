---
service: "lavatoryRunner"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "cron (host-level)"
environments: ["uat", "staging", "production-snc1", "production-sac1", "production-dub1"]
---

# Deployment

## Overview

Lavatory Runner is packaged as a Docker image and deployed via cron jobs on dedicated `artifactory-utility` virtual machines. There is no Kubernetes or ECS orchestration — containers are launched directly by the host cron daemon, execute the purge, and exit. Deployment of new cron job configurations (new policies or schedule changes) requires manually running an Ansible playbook against the target hosts.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; extends `docker.groupondev.com/artifactory/lavatory:2019.05.08-19.55.38-387658e` |
| Orchestration | Host cron | Cron scripts deployed by Ansible playbook to `/opt/lavatory/lavatory_cron_job.sh` on `artifactory-utility` hosts |
| Registry | Artifactory (internal) | Published to `docker.groupondev.com/artifactory/lavatoryrunner:<DATE>-<GIT_SHA>` |
| Load balancer | None | Not applicable — batch container with no inbound traffic |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| uat | User acceptance testing of retention policies | N/A | N/A |
| staging | Pre-production validation; dry-run mode also targets staging | us-west-2 (`stable-internal.us-west-2.aws.groupondev.com`) | N/A |
| production-snc1 | Production cleanup for snc1 colo Artifactory | snc1 | N/A |
| production-sac1 | Production cleanup for sac1 colo Artifactory | sac1 | N/A |
| production-dub1 | Production cleanup for dub1 colo Artifactory | dub1 | N/A |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push to any branch; additionally triggered by successful build of the upstream `lavatory` base image job

### Pipeline Stages

1. **Checkout**: Checks out repository source code using the build's git ref.
2. **Build**: Runs `make build` — builds Docker image tagged as `docker.groupondev.com/artifactory/lavatoryrunner:<DATE>-<GIT_SHA>`.
3. **Test**: Clones `artifactory/secret` repo (credentials: `svcdcos-ssh`), runs `make test` — spins up an Artifactory Pro test container, seeds it with fixture data, executes the runner, and validates artifact counts before and after purge.
4. **Dry-Run Against Staging**: Runs `make dry-run-staging` — executes the runner in `--no-default` (no dry-run flag not passed, so runs without `--nodryrun`) against the staging Artifactory instance for `docker-conveyor-snapshots`.
5. **Push** (master branch only): Runs `make push` — publishes the built image to `docker.groupondev.com/artifactory/lavatoryrunner`.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Single-instance per colo (1 primary host per production colo) | Defined in Ansible inventory group `primary` |
| Memory | Not configured within this repo | Managed at host level |
| CPU | Not configured within this repo | Managed at host level |

## Resource Requirements

> Deployment configuration managed externally. Resource limits are set at the host cron / Docker run level in the Ansible playbook, not tracked in this repo.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified | Not specified |
| Memory | Not specified | Not specified |
| Disk | Not specified | Not specified |
